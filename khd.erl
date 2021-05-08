%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 4月 2021 21:18
%%%-------------------------------------------------------------------
-module(khd).
-author("Administrator").

%% API
-export([start/0]).

start() ->
  {ok, Socket} = gen_tcp:connect("localhost", 2345, [binary, {packet, 4}]),
  rigister_or_login(Socket),
  {ok, Socket1} = gen_tcp:connect("localhost", 1234, [binary, {packet, 2}]),
  create_or_inroom(Socket1),





rigister_or_login(Socket) ->
  io:format("rigist:'0'  login:'1'~n"),
  Msg = io:get_line("enter options:"),
  Msg1 = remove_lineFeed(Msg),
  case Msg1 of
    "0" -> rigist(Socket);
    "1" -> login(Socket);
    "_" -> rigister_or_login(Socket)
  end.

rigist(Socket) ->
  io:format("Please enter you name and password"),
  Pid = io:get_line("Pid:"),
  Pass = io:get_line("Pass:"),
  Pid1 = remove_lineFeed(Pid),
  Pass2 = remove_lineFeed(Pass),
  gen_tcp:send(Socket, agreement:packet(2, {Pid1, Pass2})),
  receive
    {tcp, Socket, Bin} ->
      {_State, Response} = {agreement:unpacket(Bin)},
      case Response of
        rigister -> login(Socket);
        pid_already_exists -> rigist(Socket)
      end
  end.

login(Socket) ->
  io:format("Please enter you name and password"),
  Pid = io:get_line("Pid:"),
  Pass = io:get_line("Pass:"),
  Pid1 = remove_lineFeed(Pid),
  Pass2 = remove_lineFeed(Pass),
  gen_tcp:send(Socket, agreement:packet(1, {Pid1, Pass2})),
  receive
    {tcp, Socket, Bin} ->
      {_State, Response} = {agreement:unpacket(Bin)},
      case Response of
        no_this_pid -> login(Socket);
        already_login -> login(Socket)
      end
  end.

send_msg(Socket) ->
  io:format("quit:'0'  chat:'1'~n"),
  Msg = io:get_line("Please enter options: "),
  Msg1 = remove_lineFeed(Msg),
  request(Socket, Msg1).

create_or_inroom(Socket1)  ->
  io:format("create:'3'  inroom:'4'~n"),
  Msg = io:get_line("enter options:"),
  Msg1 = remove_lineFeed(Msg),
  case Msg1 of
    "3" -> create(Socket1);
    "4" -> inroom(Socket1);
    "_" -> create_or_inroom(Socket1)
  end.

create(Socket1)  ->
  io:format("Please enter you room name"),
  Roomname = io:get_line("Roomname:"),
  Roomname1 = remove_lineFeed(Roomname),
  gen_tcp:send(Socket1, agreement:packet(3, {Roomname1})),
  receive
    {tcp, Socket1, Bin} ->
      {_State, Response} = {agreement:unpacket(Bin)},
      case Response of
        rigister -> login(Socket1);
        pid_already_exists -> rigist(Socket1)
      end
  end.

