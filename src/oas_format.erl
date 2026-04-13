%% Maps OpenAPI format names to Erlang PCRE2 regex patterns

-module(oas_format).
-export([
    validate/2,
    list_known/0
]).

%% Returns a list of supported OpenAPI format names
list_known() ->
    [email, uuid, date, date_time, ipv4, ipv6, hostname, uri, password, byte, int32, int64, float, double, binary, time].

%% Returns the regex pattern (as a binary) for a given OpenAPI format atom

-spec validate(atom(), binary()) -> boolean().
validate(Format, Value) ->
    case get_pattern(Format) of
        {error, _} = Err ->
            Err;
        Pattern ->
            re:run(Value, Pattern) /= nomatch
    end.

get_pattern(Format) ->
    case persistent_term:get({?MODULE, Format}, undefined) of
        undefined ->
            case raw_pattern_for_format(Format) of
                undefined ->
                    {error, unknown_format};
                Pattern ->
                    compile(Format, Pattern)
            end;
        CachedPattern ->
            CachedPattern
    end.

compile(Format, Pattern) ->
    Key = {?MODULE, Format},
    case persistent_term:get(Key, undefined) of
        undefined ->
            case re:compile(Pattern, [unicode, ucp, {newline, anycrlf}]) of
                {ok, Compiled} ->
                    persistent_term:put(Key, Compiled),
                    Compiled;
                {error, {ErrDesc, Pos}} ->
                    %% Create a visual pointer to the error position
                    Marker = << << (case I == Pos of true -> $^; false -> $\s end) >> || I <- lists:seq(0, byte_size(Pattern)) >>,
                    
                    erlang:error({regex_compilation_failed, [
                        {error, list_to_binary(ErrDesc)},
                        {at_position, Pos},
                        {original, Pattern},
                        {visual_hint, <<Pattern/binary, "\n", Marker/binary>>}
                    ]})
            end;
        Cached ->
            Cached
    end.

%% For introspection/testing: get the raw pattern string
raw_pattern_for_format(email) ->
    <<"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$">>;
raw_pattern_for_format(uuid) ->
    <<"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$">>;
raw_pattern_for_format(date) ->
    <<"^\\d{4}-\\d{2}-\\d{2}$">>;
raw_pattern_for_format(date_time) ->
    <<"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?(?:Z|[+-]\\d{2}:?\\d{2})$">>;
raw_pattern_for_format(ipv4) ->
    <<"^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$">>;
raw_pattern_for_format(ipv6) ->
    <<"^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$">>;
raw_pattern_for_format(hostname) ->
    <<"^([a-zA-Z0-9][-a-zA-Z0-9]{0,62})(\\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$">>;
raw_pattern_for_format(uri) ->
    <<"^[a-zA-Z][a-zA-Z0-9+.-]*:[^\\s]*$">>;
raw_pattern_for_format(password) ->
    <<"^.*$">>;
raw_pattern_for_format(byte) ->
    <<"^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$">>;
raw_pattern_for_format(int32) ->
    <<"^-?\\d{1,10}$">>;
raw_pattern_for_format(int64) ->
    <<"^-?\\d{1,19}$">>;
raw_pattern_for_format(float) ->
    <<"^-?\\d+(?:\\.\\d+)?$">>;
raw_pattern_for_format(double) ->
    <<"^-?\\d+(?:\\.\\d+)?$">>;
raw_pattern_for_format(binary) ->
    <<"^.*$">>;
raw_pattern_for_format(time) ->
    <<"^\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?$">>;
raw_pattern_for_format(_) ->
    undefined.
