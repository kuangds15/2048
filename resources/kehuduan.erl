%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 4月 2021 17:33
%%%-------------------------------------------------------------------
-module(kehuduan).
-author("Administrator").

%% API
-export([client/1]).

client(Str)  ->
  {ok,Socket}  =  gen_tcp:connect("localhost",2345,[binary, {packet,4}]),
  ok = gen_tcp:send(Socket,term_to_binary(Str)),
  receive
    {tcp,Socket,Bin}  ->
      io:format("Client  received  binary = ~p~n",[Bin]),

      gen_tcp:close(Socket)
  end.
