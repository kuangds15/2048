%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 4月 2021 16:58
%%%-------------------------------------------------------------------
-module(fwd).
-author("Administrator").

%% API
-export([start/0, start_room/0]).
-record(login, {pid, password}).
-record(register, {pid2, password2}).
-record(room, {name, people}).

start() ->
  case gen_tcp:listen(2345, [binary, {packet, 4}, {active, true}]) of
    {ok, Listen} ->
      spawn(fun() -> wait_a_client(Listen) end);
    {error, Why} ->
      io:format("~p~n", [Why])
  end.



wait_a_client(Listen) ->
  case gen_tcp:accept(Listen) of
    {ok, Socket} ->
      spawn(fun() -> wait_a_client(Listen) end),
      loop(Socket);
    {error, Why} ->
      io:format("~p~n", [Why])
  end.


loop(Socket) ->
  receive
    {tcp, Socket, Bin} ->
      Msg = agreement1:unpacket(Bin),
      case Msg of
        1 -> {1, Pid, Pass} = agreement:unpacket(Bin),
          case
            do(qlc:q([X#register.pid2 || X <- mnesia:table(register), X =:= Pid])) of
            error -> gen_tcp:send(Socket, agreement:packet(1, {no_this_pid}));
            Pid -> case
                     do(qlc:q([{X#login.pid, Y#login.password} || X <- mnesia:table(login),
                       Y <- mensia:table(login),
                       X =:= Pid, Y =:= Pass])) of
                     {Pid, _} -> gen_tcp:send(Socket, agreement:packet(1, {already_login}));
                     {error, Pass} -> Row = #login{pid = Pid, password = Pass},
                       F = fun() -> mnesia_write(Row) end,
                       mensia:transaction(F)
                   end
          end,
          loop(Socket);
        2 -> {2, Pid, Pass} = agreement:unpacket(Bin),
          case do(qlc:q([X#register.pid2 || X <- mnesia:table(register), X =:= Pid])) of
            error -> Row = #register{pid2 = Pid, password2 = Pass},
              F = fun() -> mnesia_write(Row) end,
              mensia:transaction(F),
              gen_tcp:send(Socket, agreement:packet(2, {register}));
            Pid -> gen_tcp:send(Socket, agreement:packet(2, {pid_already_exists}))
          end
      end;
    {tcp_closed, Socket} ->
      io:format("client socket closed ~n")
  end.


start_room() ->
  case gen_tcp:listen(1234, [binary, {packet, 2}, {active, true}]) of
    {ok, Listen} ->
      spawn(fun() -> wait_a_client1(Listen) end);
    {error, Why} ->
      io:format("~p~n", [Why])
  end.

wait_a_client1(Listen1) ->
  case gen_tcp:accept(Listen1) of
    {ok, Socket1} ->
      spawn(fun() -> wait_a_client1(Listen1) end),
      loop1(Socket1);
    {error, _Why} ->
      io:format("~p~n", [_Why])
  end.

loop1(Socket1) ->
  receive
    {tcp, Socket1, Bin} ->
      do(qlc:q([X || X <- mnesia:table(room)])),
      Msg = agreement1:unpacket(Bin),
      case Msg of
        3 ->  {3,Roomname}  = agreement:unpacket(Bin),
          Row = #room{name = Roomname, people = 1},
          F = fun() -> mnesia_write(Row) end,
          mensia:transaction(F);

        4 -> {4,}

      end
  end.

create_room()  ->
  Newroom = #room{}




do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.




