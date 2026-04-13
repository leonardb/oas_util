-module(oas_pattern).

-export([compile/1, compile/2, to_pcre2/1, to_pcre2/2]).

compile(JsPattern) ->
    compile(JsPattern, false).

compile(JsPattern, StrictMode) ->
    Translated = to_pcre2(JsPattern, StrictMode),
    Key = {?MODULE, Translated, StrictMode},
    case persistent_term:get(Key, undefined) of
        undefined ->
            case re:compile(Translated, [unicode, ucp, {newline, anycrlf}]) of
                {ok, Compiled} ->
                    persistent_term:put(Key, Compiled),
                    Compiled;
                {error, {ErrDesc, Pos}} ->
                    Translated = to_pcre2(JsPattern, StrictMode),
                    %% Create a visual pointer to the error position
                    Marker = << << (case I == Pos of true -> $^; false -> $\s end) >> || I <- lists:seq(0, byte_size(Translated)) >>,
                    
                    erlang:error({regex_compilation_failed, [
                        {error, list_to_binary(ErrDesc)},
                        {at_position, Pos},
                        {original, JsPattern},
                        {translated, Translated},
                        {visual_hint, <<Translated/binary, "\n", Marker/binary>>}
                    ]})
            end;
        Cached ->
            Cached
    end.

to_pcre2(JsPattern) ->
    to_pcre2(JsPattern, false).

%% Translates a JS regex string to a PCRE2-compatible binary.
-spec to_pcre2(binary(), boolean()) -> binary().
to_pcre2(JsPattern, StrictMode) when is_binary(JsPattern) ->
    %% 1. Extract and convert flags if delimiters /.../i are present
    {Body, Modifiers} = extract_flags(JsPattern),
    
    %% 2. Apply Strict Mode (Automatic Anchoring) if requested
    FinalBody = case StrictMode of
        true -> apply_strict_anchoring(Body);
        false -> Body
    end,

    %% 3. Prepend Erlang/PCRE2 modifiers (e.g., (?is))
    PatternWithFlags = <<Modifiers/binary, FinalBody/binary>>,

    %% 4. Manually convert \uXXXX (JS) to \x{XXXX} (PCRE2) for compatibility
    U_Converted = js_unicode_to_pcre2(PatternWithFlags),

    %% 5. Handle invalid sequences inside [classes]
    Class_Cleaned = clean_classes(U_Converted),

    %% 6. Strip non-essential escapes (PCRE2 strict mode)
    strip_non_essential_escapes(Class_Cleaned).

%% Manual binary scan-and-replace for \uXXXX -> \x{XXXX}
%% Convert \uXXXX to \x{XXXX} everywhere, including inside character classes
js_unicode_to_pcre2(Bin) ->
    js_unicode_to_pcre2(Bin, <<>>).

js_unicode_to_pcre2(<<>>, Acc) ->
    io:format("Pattern: ~p~n", [Acc]),
    Acc;
js_unicode_to_pcre2(<<$\\, $u, H1, H2, H3, H4, Rest/binary>>, Acc) ->
    case is_hex(H1) andalso is_hex(H2) andalso is_hex(H3) andalso is_hex(H4) of
        true ->
            js_unicode_to_pcre2(Rest, <<Acc/binary, "\\x{", H1, H2, H3, H4, $}>>);
        false ->
            js_unicode_to_pcre2(Rest, <<Acc/binary, $\\, $u, H1, H2, H3, H4>>)
    end;
js_unicode_to_pcre2(<<C, Rest/binary>>, Acc) ->
    io:format("Unmatched char: ~tp~n", [C]),
    js_unicode_to_pcre2(Rest, <<Acc/binary, C>>).

is_hex(C) when (C >= $0 andalso C =< $9) orelse (C >= $A andalso C =< $F) orelse (C >= $a andalso C =< $f) -> true;
is_hex(_) -> false.

%% --- Internal Helpers ---

%% Detects /pattern/flags and extracts them
extract_flags(<<$/, Rest/binary>>) ->
    case binary:matches(Rest, <<"/">>) of
        [] -> {<<$/, Rest/binary>>, <<>>}; 
        Matches ->
            {Pos, _Len} = last_match(Matches),
            Body = binary:part(Rest, 0, Pos),
            Flags = binary:part(Rest, Pos + 1, byte_size(Rest) - Pos - 1),
            {Body, translate_flags(Flags)}
    end;
extract_flags(Pattern) -> {Pattern, <<>>}.

%% This is here purely to get around equalizer's "last" function not working on binaries
last_match([]) -> nomatch;
last_match(Matches) -> lists:last(Matches).

%% Map JS flags to PCRE2 inline modifiers
translate_flags(<<>>) -> <<>>;
translate_flags(Flags) ->
    Map = [{<<"i">>, <<"i">>}, {<<"m">>, <<"m">>}, {<<"s">>, <<"s">>}],
    Active = [Val || {Key, Val} <- Map, binary:match(Flags, Key) =/= nomatch],
    case Active of
        [] -> <<>>;
        _ -> <<"(?", (iolist_to_binary(Active))/binary, ")">>
    end.

%% Wraps body in ^(?: ... )$ if anchors are missing
apply_strict_anchoring(Body) ->
    HasStart = case re:run(Body, <<"^\\^">>) of {match, _} -> true; _ -> false end,
    HasEnd = case re:run(Body, <<"[^\\\\]\\$$">>) of {match, _} -> true; _ -> false end,
    case {HasStart, HasEnd} of
        {true, true} -> Body;
        _ -> <<"^(?:", Body/binary, ")$">>
    end.

%% Removes sequences that PCRE2 forbids inside [...] classes (e.g. \B, \R, \X)
clean_classes(Bin) ->
    re:replace(Bin, <<"\\[([^\\]]*)\\]">>, 
        fun(_FullMatch, [Internal]) ->
            CleanInternal = re:replace(Internal, <<"\\\\([BRX])">>, <<"\\1">>, [global, {return, binary}]),
            <<"[", CleanInternal/binary, "]">>
        end, [global, {return, binary}]).

%% Removes backslashes from characters that aren't regex metacharacters
strip_non_essential_escapes(Bin) ->
    Meta = <<".\\+*?[^]$(){}=!<>|:-">>,
    Shorthands = <<"dwsDWSbBAnrtvef0123456789x">>,
    re:replace(Bin, <<"\\\\(.)">>, 
        fun(Match, [Char]) ->
            case binary:match(<<Meta/binary, Shorthands/binary>>, Char) of
                nomatch -> Char; 
                _ -> Match       
            end
        end, [global, {return, binary}]).
