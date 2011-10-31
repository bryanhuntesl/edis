%%%-------------------------------------------------------------------
%%% @author Fernando Benavides <fernando.benavides@inakanetworks.com>
%%% @author Chad DePue <chad@inakanetworks.com>
%%% @copyright (C) 2011 InakaLabs SRL
%%% @doc Benchmarks for string commands
%%% @end
%%%-------------------------------------------------------------------
-module(strings_bench).
-author('Fernando Benavides <fernando.benavides@inakanetworks.com>').
-author('Chad DePue <chad@inakanetworks.com>').

-behaviour(edis_bench).

-include("edis.hrl").

-export([all/0,
         init/0, init_per_testcase/1, init_per_round/2,
         quit/0, quit_per_testcase/1, quit_per_round/2]).
-export([append/1, decr/1, decrby/1]).

%% ====================================================================
%% External functions
%% ====================================================================
-spec all() -> [atom()].
all() -> [Fun || {Fun, _} <- ?MODULE:module_info(exports) -- edis_bench:behaviour_info(callbacks),
                 Fun =/= module_info].

-spec init() -> ok.
init() -> ok.

-spec quit() -> ok.
quit() -> ok.

-spec init_per_testcase(atom()) -> ok.
init_per_testcase(_Function) -> ok.

-spec quit_per_testcase(atom()) -> ok.
quit_per_testcase(_Function) -> ok.

-spec init_per_round(atom(), [binary()]) -> ok.
init_per_round(append, Keys) ->
  [{ok, Deleted} | OkKeys] =
    edis_db:run(
      edis_db:process(0),
      #edis_command{cmd = <<"EXEC">>, group = transaction, result_type = multi_result,
                    args = [#edis_command{cmd = <<"DEL">>, args = [<<"test-string">>],
                                          group = keys, result_type = number} |
                                           [#edis_command{cmd = <<"APPEND">>,
                                                          args = [<<"test-string">>, <<"X">>],
                                                          result_type = number,
                                                          group = strings} || _Key <- Keys]
                            ]}),
  case Deleted of
    0 -> ok;
    1 -> ok
  end,
  case {length(OkKeys), length(Keys)} of
    {X,X} -> ok
  end;
init_per_round(Fun, Keys) when Fun =:= decr;
                               Fun =:= decrby ->
  [{ok, Deleted} , ok] =
    edis_db:run(
      edis_db:process(0),
      #edis_command{cmd = <<"EXEC">>, group = transaction, result_type = multi_result,
                    args = [#edis_command{cmd = <<"DEL">>, args = [<<"test-string">>],
                                          group = keys, result_type = number},
                            #edis_command{cmd = <<"SET">>,
                                          args = [<<"test-string">>, edis_util:integer_to_binary(length(Keys))],
                                          result_type = ok, group = strings}]}),
  case Deleted of
    0 -> ok;
    1 -> ok
  end;
init_per_round(_Fun, _Keys) -> ok.

-spec quit_per_round(atom(), [binary()]) -> ok.
quit_per_round(_, _Keys) -> ok.

-spec append([binary()]) -> pos_integer().
append([Key|_]) ->
  edis_db:run(
    edis_db:process(0),
    #edis_command{cmd = <<"APPEND">>, args = [<<"test-string">>, Key],
                  group = strings, result_type = number}).

-spec decr([binary()]) -> pos_integer().
decr(_) ->
  edis_db:run(
    edis_db:process(0),
    #edis_command{cmd = <<"DECR">>, args = [<<"test-string">>],
                  group = strings, result_type = number}).

-spec decrby([binary()]) -> pos_integer().
decrby(Keys) ->
  edis_db:run(
    edis_db:process(0),
    #edis_command{cmd = <<"DECRBY">>, args = [<<"test-string">>, length(Keys)],
                  group = strings, result_type = number}).