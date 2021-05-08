%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 4月 2021 3:37
%%%-------------------------------------------------------------------
-module(udp).
-author("Administrator").

%% API
-export([server/1]).

server(Port)->
  {ok,Socket}  = gen_udp:open(Port,[binary]),
  loop(Socket).

loop(Socket)  ->
  receive
    {udp,Socket,Host,Port,Bin}  ->
      Binreply = ...,
    gen
  end

