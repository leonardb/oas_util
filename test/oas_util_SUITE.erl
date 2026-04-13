%% oas_util_SUITE.erl
%% Test suite for oas_util module (public API)

-module(oas_util_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).

-export([
    email/1, uuid/1, date/1, date_time/1, ipv4/1, ipv6/1, hostname/1, uri/1, password/1, byte/1, int32/1, int64/1, float/1, double/1, binary/1, time/1,
    basic_match/1, anchors/1, quantifiers/1, character_classes/1, unicode/1, dot_wildcard/1, escaping/1, unicode_range/1
]).

all() ->
    [email, uuid, date, date_time, ipv4, ipv6, hostname, uri, password, byte, int32, int64, float, double, binary, time,
     basic_match, anchors, quantifiers, character_classes, unicode, dot_wildcard, escaping, unicode_range].

basic_match(_Config) ->
    %% Simple literal match
    MP = oas_util:compile_pattern(<<"abc">>),
    {match, _} = re:run(<<"abc">>, MP),
    nomatch = re:run(<<"def">>, MP).

anchors(_Config) ->
    MP = oas_util:compile_pattern(<<"^abc$">>),
    {match, _} = re:run(<<"abc">>, MP),
    nomatch = re:run(<<"xabc">>, MP),
    nomatch = re:run(<<"abcx">>, MP).

quantifiers(_Config) ->
    MP = oas_util:compile_pattern(<<"a+">>),
    {match, _} = re:run(<<"aaa">>, MP),
    nomatch = re:run(<<"">>, MP).

character_classes(_Config) ->
    MP = oas_util:compile_pattern(<<"[a-z]">>),
    {match, _} = re:run(<<"m">>, MP),
    nomatch = re:run(<<"1">>, MP).

unicode(_Config) ->
    Pattern = <<"\\u00E9">>,
    MP = oas_util:compile_pattern(Pattern),
    BinE = <<"é"/utf8>>,
    {match, _} = re:run(BinE, MP),
    nomatch = re:run(<<"e">>, MP).

dot_wildcard(_Config) ->
    MP = oas_util:compile_pattern(<<"a.c">>),
    {match, _} = re:run(<<"abc">>, MP),
    {match, _} = re:run(<<"a-c">>, MP),
    nomatch = re:run(<<"ac">>, MP).

escaping(_Config) ->
    MP = oas_util:compile_pattern(<<"a\\.c">>),
    {match, _} = re:run(<<"a.c">>, MP),
    nomatch = re:run(<<"abc">>, MP).

unicode_range(_Config) ->
    %% Match any lowercase Latin-1 Supplement letter (e.g. à, á, â, ã, ä, å)
    Pattern = <<"[\\u00E0-\\u00E5]">>,
    MP = oas_util:compile_pattern(Pattern),
    BinAgrave = <<"à"/utf8>>,
    BinAring = <<"å"/utf8>>,
    BinA = <<"a">>,
    {match, _} = re:run(BinAgrave, MP),
    {match, _} = re:run(BinAring, MP),
    nomatch = re:run(BinA, MP).

init_per_suite(Config) -> Config.
end_per_suite(Config) -> Config.
init_per_testcase(_Case, Config) -> Config.
end_per_testcase(_Case, Config) -> Config.


email(_Config) ->
    ?assert(oas_util:validate_format(email, <<"foo.bar+baz@example.com">>)),
    ?assertNot(oas_util:validate_format(email, <<"foo@">>)).

uuid(_Config) ->
    ?assert(oas_util:validate_format(uuid, <<"123e4567-e89b-12d3-a456-426614174000">>)),
    ?assertNot(oas_util:validate_format(uuid, <<"not-a-uuid">>)).

date(_Config) ->
    ?assert(oas_util:validate_format(date, <<"2023-12-31">>)),
    ?assert(oas_util:validate_format(date, <<"2023-13-01">>)).

date_time(_Config) ->
    ?assert(oas_util:validate_format(date_time, <<"2023-12-31T23:59:59Z">>)),
    ?assert(oas_util:validate_format(date_time, <<"2023-12-31T23:59:59+02:00">>)),
    ?assertNot(oas_util:validate_format(date_time, <<"2023-12-31">>)).

ipv4(_Config) ->
    ?assert(oas_util:validate_format(ipv4, <<"192.168.1.1">>)),
    ?assert(oas_util:validate_format(ipv4, <<"999.999.999.999">>)).

ipv6(_Config) ->
    ?assert(oas_util:validate_format(ipv6, <<"2001:0db8:85a3:0000:0000:8a2e:0370:7334">>)),
    ?assertNot(oas_util:validate_format(ipv6, <<"not:ipv6">>)).

hostname(_Config) ->
    ?assert(oas_util:validate_format(hostname, <<"example.com">>)),
    ?assertNot(oas_util:validate_format(hostname, <<"-badhost">>)).

uri(_Config) ->
    ?assert(oas_util:validate_format(uri, <<"http://example.com/path?query#frag">>)),
    ?assertNot(oas_util:validate_format(uri, <<"not a uri">>)).

password(_Config) ->
    ?assert(oas_util:validate_format(password, <<"any string!@#">>)).

byte(_Config) ->
    ?assert(oas_util:validate_format(byte, <<"SGVsbG8=">>)),
    ?assertNot(oas_util:validate_format(byte, <<"notbase64">>)).

int32(_Config) ->
    ?assert(oas_util:validate_format(int32, <<"123456">>)),
    ?assertNot(oas_util:validate_format(int32, <<"123456789012">>)).

int64(_Config) ->
    ?assert(oas_util:validate_format(int64, <<"123456789012345">>)),
    ?assertNot(oas_util:validate_format(int64, <<"123456789012345678901234">>)).

float(_Config) ->
    ?assert(oas_util:validate_format(float, <<"123.45">>)),
    ?assert(oas_util:validate_format(float, <<"-123">>)),
    ?assertNot(oas_util:validate_format(float, <<"abc">>)).

double(_Config) ->
    ?assert(oas_util:validate_format(double, <<"123.456789">>)),
    ?assert(oas_util:validate_format(double, <<"-123">>)),
    ?assertNot(oas_util:validate_format(double, <<"abc">>)).

binary(_Config) ->
    ?assert(oas_util:validate_format(binary, <<"any bytes">>)).

time(_Config) ->
    ?assert(oas_util:validate_format(time, <<"23:59:59">>)),
    ?assert(oas_util:validate_format(time, <<"12:34:56.789">>)),
    ?assertNot(oas_util:validate_format(time, <<"notatime">>)).
