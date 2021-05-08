%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 4月 2021 4:44
%%%-------------------------------------------------------------------
-module(start).
-author("Administrator").
-behaviour(gen_server).
%% API
-export([start_link/0, regist/2, login/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, handle_call/1]).
-define(SERVER, ?MODULE).

start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop() -> gen_server:call(?MODULE, stop).

init([]) ->
  {ok, ets:new(?MODULE, [])}.

regist(Name, Pass) -> gen_server:call(?MODULE, {regist, Name, Pass}).

login(Name, Pass) ->
  io:format("111"),
  case gen_server:call(?MODULE, {login, Name, Pass}) of
    {ok} -> io:format("111"),
      register(Name, spawn(fun() -> player(Name) end));
    {password_error} -> io:format("password_error");
    _  -> io:format("11111")
  end.



handle_call({regist, Name, Pass}, _From, Tab) ->
  Reply =
    case ets:lookup(Tab, Name) of
      [] -> ets:insert(Tab, [{Name, Pass, 0}]),
        {name_successfully_registered, Name};
      [_] -> {the_name_already_exists}
    end,
  {reply, Reply, Tab};

handle_call({login, Name, Pass}, _From, Tab) ->
  Reply =
    case ets:lookup(Tab, Name) of
      [{Name, Pass, 0}] -> ets:update_element(Tab, Name, {3, 1}),
        {ok};
      [_] -> {password_error}
    end,
  {reply, Reply, Tab}.

handle_call({stop, _From, Tab}) -> {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

chat_or_logout(Name) ->
  Msg = io:get_chars("enter options: ",1),
  io:format("dayindayin"),
  Msg1 = remove_lineFeed(Msg),
  case Msg1 of
    "1" -> private_chat(Name);
    "3" -> logout(Name);
    _ -> chat_or_logout(Name)
  end.

private_chat(Me) ->
  ets:tab2list([]),
  io:format("Who do you want to chat with"),
  Msg = io:get_line("Please write:"),
  Name = remove_lineFeed(Msg),
  case ets:lookup(Name) of
    [{Name, _, 1}] ->
      Msg1 = io:get_line("Please speak:"),
      Speak = remove_lineFeed(Msg1),
      Name ! {Me, Speak},
      Me ! {Me, Speak},
      private_chat(Me);
    [{Name, _, 0}] ->
      io:format("not online"),
      private_chat(Me)
  end.




logout(Name) ->
  ets:update_element(?MODULE, Name, {3, 0}),
  stop().


player(Name) ->
  chat_or_logout(Name),
  receive
    {Who, Response} -> {Who, Response}
  end.



remove_lineFeed(Msg) ->
  string:substr(Msg, 1, string:len(Msg) - 1).