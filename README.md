
oas_util: OpenAPI Regex & Format Utilities for Erlang
====================================================

This library provides utilities for working with OpenAPI/JSON Schema regex patterns and format validation in Erlang. It translates JavaScript-style regexes to Erlang/PCRE2, and provides ready-to-use patterns for common OpenAPI formats. Compiled regexes are cached using `persistent_term`.

## Build

    $ rebar3 compile

## Modules & API

### oas_util

- `compile_pattern/1,2` — Compile a JS/OpenAPI regex pattern to an Erlang regex (optionally strict/anchored). Returns `MP` or throws an exception.
- `validate_format/2` — Check if a value is valid for a given OpenAPI format. Returns `true` or `false`.
- `known_formats/0` — List all supported OpenAPI format names.

### oas_pattern

- `compile/1,2` — Translate and compile JS regex to Erlang regex

### oas_format

- `validate_format/2` — Validates whether or not a string matches the pattern for a known format
- `known_formats/0` — List supported formats

## Supported OpenAPI Formats

    email, uuid, date, date_time, ipv4, ipv6, hostname, uri, password, byte, int32, int64, float, double, binary, time

## Usage Examples


### Compile a JS/OpenAPI regex pattern

```erlang
MP = oas_util:compile_pattern(<<"^foo[0-9]+bar$">>).
re:run(<<"foo123bar">>, MP).
```

### Compile with strict mode (anchored)

```erlang
MP = oas_util:compile_pattern(<<"foo">>, true).
re:run(<<"foo">>, MP). % matches
re:run(<<"xfoo">>, MP). % nomatch
```

### Validate an OpenAPI format (e.g., email)

```erlang
oas_util:validate_format(email, <<"foo.bar+baz@example.com">>). % true
oas_util:validate_format(email, <<"foo@">>). % false
```

### List all supported formats

```erlang
oas_util:known_formats().
```

## License

MIT License — see LICENSE.md
