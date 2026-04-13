%% oas_util.erl
%% Public API for OpenAPI regex and format utilities

-module(oas_util).
-export([
    compile_pattern/1,
    compile_pattern/2,
    validate_format/2,
    known_formats/0
]).

%% This is a dummy type to make Eqwalizer happy
%% This type will never actually be returned
%% since we do not use the `export` option to compile
-type exported() :: {re_exported_pattern, _, _, _, _}.

-doc """
Compile a JS/OpenAPI pattern to an Erlang regex (Non-strict).
Note: This does not enforce anchoring, so patterns like "abc" will match "abc", "xabc", "abcx", and "xabcx".

The spec includes `exported()` to satisfy Eqwalizer, but in practice we will
only return `re:mp()` since we don't use the `export` option.

Will throw an exception if compilation fails, with details about the error and its position.
""".
-spec compile_pattern(binary()) -> re:mp() | exported().
%% Compile a JS/OpenAPI pattern to an Erlang regex (default: non-strict)
compile_pattern(Pattern) ->
    oas_pattern:compile(Pattern).

-doc """
Compiles with optional Strict Mode (Force anchoring).
Returns {ok, mp()} | {error, {ErrorDesc, Pos}}.

The spec includes `exported()` to satisfy Eqwalizer, but in practice we will
only return `re:mp()` since we don't use the `export` option.

Will throw an exception if compilation fails, with details about the error and its position.
""".
-spec compile_pattern(binary(), boolean()) -> re:mp() | exported().
compile_pattern(Pattern, Strict) ->
    oas_pattern:compile(Pattern, Strict).

-doc """
Check if a values is valid for a given OpenAPI format
""".
validate_format(Format, Value) ->
    oas_format:validate_format(Format, Value).

-doc """
List all known OpenAPI formats
""".
known_formats() ->
    oas_format:known_formats().
