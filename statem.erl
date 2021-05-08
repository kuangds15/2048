%%%-------------------------------------------------------------------
%%% @author linjinyuan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc 状态机：每分钟将信息写入mysql数据库
%%%
%%% @end
%%% Created : 27. 5月 2020 8:56
%%%-------------------------------------------------------------------
-module(statem).
-author("linjinyuan").

-behaviour(gen_statem).
-define(NAME, statem).
-define(DB_HOST, "localhost").
-define(DB_PORT, 3306).
-define(DB_USER, "root").
-define(DB_PASS, "123456").
-define(DB_NAME, "test1").

-export([start_link/0, start/0, init/1, callback_mode/0, unlog/3, log/3, open/3, terminate/3, code_change/4]).



start_link() ->
  gen_statem:start_link({local, ?NAME}, ?MODULE, 0, []).

start() ->
  reset:start_link(),
  reset:start(),
  Number = chat_server:onlineNum(),
  gen_statem:cast(?NAME, {number, Number}).

init(Data) ->
  initMysql(),
  chat_server:start(),
  {ok, unlog, Data}.

callback_mode() ->
  state_functions.

unlog(cast, {number, _Number}, Data) ->
  {next_state, open, Data, [{state_timeout, 60000, log}]}.

log(cast, {number, Number}, Data) ->
  %%将数据写入数据库
  {{Y, M, D}, {H, Min, S}} = calendar:local_time(),
  Time = [Y, "/", M, "/", D, "/", H, ":", Min, ":", S],
  mysql:fetch(p1, list_to_binary("insert into online(onlineNum,time) values (" ++ lists:concat([Number]) ++ ",'" ++ lists:concat(Time) ++ "')")),
  {next_state, open, Data, [{state_timeout, 60000, log}]}.

open(state_timeout, log, Data) ->
  %%获取在线人数判断哪个状态
  Number = chat_server:onlineNum(),
  case Number of
    0 ->
      gen_statem:cast(?NAME, {number, Number}),
      {next_state, unlog, Data};
    _ -> gen_statem:cast(?NAME, {number, Number}),
      {next_state, log, Data}
  end;

open(cast, {number, _}, Data) ->
  {next_state, open, Data}.

terminate(_Reason, _State, Data) ->
  open(state_timeout, log, Data).
code_change(_Vsn, State, Data, _Extra) ->
  {ok, State, Data}.


% 初始化mysql数据库
initMysql() ->
  mysql:start_link(p1, ?DB_HOST, ?DB_PORT, ?DB_USER, ?DB_PASS, ?DB_NAME, fun(_, _, _, _) -> ok end),
  mysql:connect(p1, ?DB_HOST, undefined, ?DB_USER, ?DB_PASS, ?DB_NAME, true),
  mysql:fetch(p1, <<"drop table if exists online">>),
  mysql:fetch(p1, <<"create table online (id int not null auto_increment,
                     onlineNum int not null,
                     time varchar(20) not null,
                     primary key (id)
												   ) engine = innodb">>).