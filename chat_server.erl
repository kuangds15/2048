%%%-------------------------------------------------------------------
%%% @author linjinyuan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc 服务器
%%%
%%% @end
%%% Created : 26. 5月 2020 8:32
%%%-------------------------------------------------------------------
-module(chat_server).
-author("linjinyuan").

%% API
-export([handle_cast/2]).
-include("users.hrl").
-define(SERVER, ?MODULE).
-behaviour(gen_server).
-export([start/0, stop/0, onlineNum/0, login_times/0, chat_times/0, init/1, handle_call/3, handle_info/2, code_change/3, terminate/2, last_login/0, rpc/2, all_users_chats/0]).

%% ---------------接口函数------------
start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop() -> gen_server:call(?MODULE, stop).

onlineNum() -> gen_server:call(?MODULE, {online_number}).
login_times() -> gen_server:call(?MODULE, {login_times}).
chat_times() -> gen_server:call(?MODULE, {chat_times}).
last_login() -> gen_server:call(?MODULE, {last_login}).
all_users_chats() -> gen_server:call(?MODULE, {all_users_chats}).

init([]) ->
  ets_user_socket(),  %%用户Socket表
  %%创建map存储数据
  Map = maps:new(),
  %%存消息
  Pid = spawn(fun() -> map(1, Map) end),
  register(map, Pid),
  %%存最近3天发言次数
  Pid2 = spawn(fun() -> chat(1, Map) end),
  register(chats, Pid2),
  %%监听
  case gen_tcp:listen(2345, [binary, {packet, 4}, {reuseaddr, true}, {active, true}]) of
    %%创建进程接收消息
    {ok, Listen} -> spawn(fun() -> wait_link(Listen) end);
    {error, Why} -> io:format("~p~n", [Why])
  end,
  %%用户信息表
  {ok, ets:new(?MODULE, [set, public, named_table, {keypos, #user.name}])}.

wait_link(Listen) ->
  case gen_tcp:accept(Listen) of
    {ok, Socket} ->
      spawn(fun() -> wait_link(Listen) end),
      loop(Socket);
    {error, Why} ->
      io:format("~p~n", [Why])
  end.

loop(Socket) ->
  receive
    {tcp, Socket, Bin} ->
      State = agreement:unpacket1(Bin),
      case State of
        10 -> %%登录
          {10, Name, Pass} = agreement:unpacket(Bin),
          %%检查是否已登录
          case gen_server:call(?MODULE, {login, Name, Pass, Socket}) of
            error -> gen_tcp:send(Socket, agreement:packet(10, {error}));
            success -> ok;
            already_login -> gen_tcp:send(Socket, agreement:packet(10, {already_login}))
          end,
          loop(Socket);
        11 -> %%注册
          {11, Id, Name, Pass} = agreement:unpacket(Bin),
          case gen_server:call(?MODULE, {regist, Id, Name, Pass}) of
            error -> gen_tcp:send(Socket, agreement:packet(11, {error}));
            success -> gen_tcp:send(Socket, agreement:packet(11, {success}))
          end,
          loop(Socket);
        0 ->  %%退出
          gen_server:call(?MODULE, {quit, Socket}),
          loop(Socket);
        1 ->  %%聊天
          {_State, Msg} = agreement:unpacket(Bin),
          gen_server:call(?MODULE, {chat, Msg, Socket}),
          loop(Socket)
      end;
    {tcp_closed, Socket} ->
      io:format("client socket closed ~n")
  end.


%% ---------------回调函数------------
%%注册
handle_call({regist, Id, Name, Pass}, _From, Tab) ->
  Reply = case ets:member(Tab, Name) of
            true -> error;
            false ->
              ets:insert(Tab, #user{id = Id, name = Name, passwd = Pass, login_times = 0, chat_times = 0, last_login = {}, off_msg_num = 0, today_chats = 0}),
              rpc(chats, {put, Name, [0, 0, 0]}),
              success
          end,
  {reply, Reply, Tab};
%%登录
handle_call({login, Name, Pass, Socket}, _From, Tab) ->
  Reply = case ets:member(sockets, Name) of
            true -> already_login;
            false ->
              case ets:lookup(Tab, Name) of
                [] -> error;
                _ ->
                  case ets:lookup_element(Tab, Name, 4) of
                    Pass ->
                      ets:insert(sockets, {Name, Socket}),
                      Times = ets:lookup_element(Tab, Name, 5),
                      ets:update_element(Tab, Name, {5, Times + 1}),
                      gen_tcp:send(Socket, agreement:packet(10, {success})),
                      Off_key = ets:lookup_element(Tab, Name, 8),%%获取离线时保存的最大消息key
                      send_off_msg(Socket, Off_key), %%推送离线消息
                      success;
                    _ -> error
                  end
              end
          end,
  {reply, Reply, Tab};

%%退出
handle_call({quit, Socket}, _From, Tab) ->
  Name = socket_to_name(Socket),
  ets:delete(sockets, Name),
  ets:update_element(?MODULE, Name, {7, calendar:local_time()}),
  Max = rpc(map, {max_key}),
  ets:update_element(?MODULE, Name, {8, Max}),
  gen_tcp:send(Socket, agreement:packet(0, {})),
  {reply, ok, Tab};

%%聊天
handle_call({chat, Msg, Socket}, _From, Tab) ->
  %%通过Socket获取用户名
  Name = socket_to_name(Socket),
  %%记录总的聊天次数
  Times = ets:lookup_element(?MODULE, Name, 6),
  ets:update_element(?MODULE, Name, {6, Times + 1}),
  %%记录今日聊天次数
  TodayTimes = ets:lookup_element(?MODULE, Name, 9),
  ets:update_element(?MODULE, Name, {9, TodayTimes + 1}),
  %%存储聊天记录
  Value = [Name, Msg, calendar:local_time()],
  rpc(map, {put, Value}),

  %%群发消息
  [gen_tcp:send(UserSocket, agreement:packet(1, {Name, Msg})) || {_Name1, UserSocket} <- ets:tab2list(sockets)],
  {reply, ok, Tab};

%%登录次数
handle_call({login_times}, _From, Tab) ->
  io:format("login_times:~n"),
  [print({Name, Times}) || #user{name = Name, login_times = Times} <- ets:tab2list(?MODULE)],
  {reply, ok, Tab};


%%查询聊天次数
handle_call({chat_times}, _From, Tab) ->
  io:format("chat_times:~n"),
  [print({Name, Times}) || #user{name = Name, chat_times = Times} <- ets:tab2list(?MODULE)],
  {reply, ok, Tab};

%%查询最后一次登录时间
handle_call({last_login}, _From, Tab) ->
  io:format("last_login:~n"),
  [print({Name, Time}) || #user{name = Name, last_login = Time} <- ets:tab2list(?MODULE)],
  {reply, ok, Tab};

%%查询在线人数
handle_call({online_number}, _From, Tab) ->
  List = ets:tab2list(sockets),
  Num = length(List),
  {reply, Num, Tab};

%%最近3天
handle_call({all_users_chats}, _From, Tab) ->
  %%获取所有人今日聊天次数，并置0
  List = [{Name, Id, Times} || #user{id = Id, name = Name, today_chats = Times} <- ets:tab2list(?MODULE)],
  [ets:update_element(?MODULE, Name, {9, 0}) || {Name, _, _} <- List],
  %%更新所有人的近3天聊天次数
  AllUsersChats = [update(Name, Id, Times) || {Name, Id, Times} <- List],
  %%  map中的key为当前天数，key加一
  rpc(chats, {key_add}),
  {reply, AllUsersChats, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Request, _State) ->
  erlang:error(not_implemented).
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.


%%存储用户Socket
ets_user_socket() ->
  ets:new(sockets, [set, public, named_table]).


%%通过Socket找到Name
socket_to_name(Socket) ->
  List = [Name || {Name, Socket1} <- ets:tab2list(sockets), Socket =:= Socket1],
  lists:nth(1, List).

%%打印数据
print({Data1, Data2}) ->
  io:format("~p : ~p~n", [Data1, Data2]).


rpc(Map, Request) ->
  Map ! {self(), Request},
  receive
    Reponse ->
      Reponse
  end.

%%Key：聊天消息最大记录数，Map:存储10条最新聊天消息
map(Key, Map) ->
  receive
    {From, {put, Value}} ->
      Map1 = maps:put(Key, Value, Map),
      case maps:size(Map1) > 10 of
        true ->
          Map2 = maps:remove(Key - 10, Map1),
          From ! true,
          map(Key + 1, Map2);
        false ->
          From ! true,
          map(Key + 1, Map1)
      end;
    {From, {max_key}} ->
      Keys = maps:keys(Map),
      case length(Keys) of
        0 -> From ! 0;
        _ -> Max = lists:max(Keys),
          From ! Max
      end,
      map(Key, Map);
    {From, {get, N}} ->
      Value = maps:get(N, Map),
      From ! Value,
      map(Key, Map);
    {From, {}} ->
      Value = maps:to_list(Map),
      From ! Value,
      map(Key, Map)
  end.

%%推送离线消息 (Off：离线时map中最大消息条数,Max:现在map中最大消息条数)
send_off_msg(Socket, Off) ->
  Max = rpc(map, {max_key}),
  case (Max - Off) > 0 of
    true when Off > 0 ->
      List = for(Off + 1, Max, []),
      %%发送离线消息
      [gen_tcp:send(Socket, agreement:packet(2, {Name, Msg, Time})) || [Name, Msg, Time] <- List];
    _ -> not_off_line_msg
  end.

%%循环获取离线消息
for(N, N, List) ->
  List;
for(I, N, List) ->
  Value = rpc(map, {get, N}),
  for(I, N - 1, [Value | List]).

%%更新用户的近3天聊天次数
update(Name, Id, Times) ->
  [Day1, Day2, Day3] = rpc(chats, {get, Name}),
  Day = rpc(chats, {day}),
  case (Day rem 3) of
    0 -> rpc(chats, {put, Name, [Day1, Day2, Times]});
    1 -> rpc(chats, {put, Name, [Times, Day2, Day3]});
    2 -> rpc(chats, {put, Name, [Day1, Times, Day3]})
  end,
  Total = case (Day rem 3) of
            0 -> Day1 + Day2 + Times;
            1 -> Times + Day2 + Day3;
            2 -> Day1 + Times + Day3
          end,
  {Id, Name, Total}.

%%map结构存储{name,[chats1,chats2,chats3]},最近3天的发言次数
chat(Key, Map) ->
  receive
    {From, {put, Name, Value}} ->
      Map1 = maps:put(Name, Value, Map),
      From ! true,
      chat(Key, Map1);
    {From, {get, Name}} ->
      Value = maps:get(Name, Map),
      From ! Value,
      chat(Key, Map);
    {From, {day}} ->
      From ! Key,
      chat(Key, Map);
    {From, {key_add}} ->
      From ! true,
      chat(Key + 1, Map)
  end.


