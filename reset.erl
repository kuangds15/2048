%%%-------------------------------------------------------------------
%%% @author linjinyuan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc 每日零点重置
%%%
%%% @end
%%% Created : 28. 5月 2020 11:52
%%%-------------------------------------------------------------------
-module(reset).
-author("linjinyuan").

%% API
-export([]).

-behaviour(gen_statem).
-define(NAME, reset).

-export([start_link/0, start/0, init/1, callback_mode/0, unreset/3, open/3, terminate/3, code_change/4]).



start_link() ->
  gen_statem:start_link({local, ?NAME}, ?MODULE, [], []).

start() ->
  {{_, _, _}, {Hour, Min, Second}} = calendar:local_time(),
  Sec = ((24 - Hour) * 60 * 60 + (60 - Min) * 60 + (60 - Second)) * 1000,
  gen_statem:cast(?NAME, {second, Sec}).

init(Data) ->
  {ok, unreset, Data}.

callback_mode() ->
  state_functions.

unreset(cast, {second, Sec}, Data) ->
  {next_state, open, Data, [{state_timeout, Sec, reset}]}.

open(state_timeout, reset, Data) ->
  List = chat_server:all_users_chats(),
  Rank = lists:keysort(3, List),
  Length = length(Rank),

  io:format("==========00:00:00 push rank========~n"),

  case (Length > 10) of
    true ->
      for((Length - 10), Length, 1, Rank);
    false ->
      for(0, Length, 1, Rank)
  end,
  Second = (24 * 60 * 60 + 60 * 60 + 60) * 1000,
  gen_statem:cast(?NAME, {second, Second}),
  {next_state, unreset, Data}.

terminate(_Reason, _State, Data) ->
  open(state_timeout, reset, Data).
code_change(_Vsn, State, Data, _Extra) ->
  {ok, State, Data}.

for(N, N, _, _) ->
  over;
for(I, N, R, Rank) ->
  {Id, Name, Times} = lists:nth(N, Rank),
  io:format("~p-----Id: ~p  Name: ~p Chats:  ~p~n", [R, Id, Name, Times]),
  for(I, N - 1, R + 1, Rank).
