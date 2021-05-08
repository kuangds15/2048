%%%-------------------------------------------------------------------
%%% @author linjinyuan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc 客户端
%%%
%%% @end
%%% Created : 26. 5月 2020 8:33
%%%-------------------------------------------------------------------
-module(chat_client).
-author("linjinyuan").
%% API
-export([start/0]).

start() ->
  %%发起连接
  {ok, Socket} = gen_tcp:connect("localhost", 2345, [binary, {packet, 4}]),
  %%  选择注册或者登录
  regist_or_login(Socket),
  %%创建进程接收消息
  Pid = spawn(fun() -> loop() end),
  %%为socket分配控制进程Pid，接收socket消息
  gen_tcp:controlling_process(Socket, Pid),
  sellp(),
  send_msg(Socket).

loop() ->
  receive
    {tcp, Socket, Bin} ->
      State = agreement:unpacket1(Bin),
      case State of
        0 ->
          %%关闭socket，退出
          gen_tcp:close(Socket),
          io:format("already quit~n");
        1 ->
          %%数据解包
          {1, Name, Msg} = agreement:unpacket(Bin),
          io:format("~n~p : ~p~n", [Name, Msg]),
          loop();
        2 ->
          %%接收离线消息
          {2, Name, Msg, Time} = agreement:unpacket(Bin),
          io:format("~p    ~p say: ~p~n", [Time, Name, Msg]),
          loop()
      end;
    {tcp_closed, _Socket} ->
      io:format("Scoket is closed! ~n")
  end.

%%选择执行操作
send_msg(Socket) ->
  io:format("quit:'0'  chat:'1'~n"),
  Msg = io:get_line("Please enter options: "),
  Msg1 = remove_lineFeed(Msg),
  request(Socket, Msg1).

regist_or_login(Socket) ->
  io:format("regist:'0'  login:'1'~n"),
  Msg = io:get_line("Please enter options: "),
  Msg1 = remove_lineFeed(Msg),
  case Msg1 of
    "0" -> regist(Socket);
    "1" -> login(Socket);
    _ -> regist_or_login(Socket)
  end.

%%退出
request(Socket, "0") ->
  gen_tcp:send(Socket, agreement:packet(0, {}));
%%聊天请求
request(Socket, "1") ->
  Msg = io:get_line("send msg('end' : return): "),
  Msg1 = remove_lineFeed(Msg),
  case Msg1 of
    "end" ->
      send_msg(Socket);
    _ ->
      gen_tcp:send(Socket, agreement:packet(1, {Msg1})),
      request(Socket, "1")
  end.

%%登录
login(Socket) ->
  io:format("===========welcome login==============~n"),
  Name = io:get_line("Name:"),
  Pass = io:get_line("Passwd:"),
  %%除去换行符
  N = remove_lineFeed(Name),
  P = remove_lineFeed(Pass),
  gen_tcp:send(Socket, agreement:packet(10, {N, P})),
  receive
    {tcp, _From, Bin} ->
      {_State, Response} = agreement:unpacket(Bin),
      case Response of
        success -> io:format("login success~n");
        error -> io:format("user or passwd error~n"),
          login(Socket);
        already_login -> io:format("you're already logged in~n"),
          login(Socket)
      end
  end.

%%注册
regist(Socket) ->
  io:format("===========welcome regist==============~n"),
  Id = io:get_line("Id:"),
  Name = io:get_line("Name:"),
  Pass = io:get_line("Passwd:"),
  %%除去换行符
  I = remove_lineFeed(Id),
  N = remove_lineFeed(Name),
  P = remove_lineFeed(Pass),
  gen_tcp:send(Socket, agreement:packet(11, {I, N, P})),
  receive
    {tcp, _From, Bin} ->
      {_State, Response} = agreement:unpacket(Bin),
      case Response of
        success -> io:format("regist success~n"),
          %%注册成功进入登录
          login(Socket);
        error -> io:format("this id or name already regist~n"),
          regist(Socket)
      end
  end.


%%除去换行符
remove_lineFeed(Msg) ->
  string:substr(Msg, 1, string:len(Msg) - 1).

%%为了美观
sellp() ->
  receive
  after 100 -> true
  end.
