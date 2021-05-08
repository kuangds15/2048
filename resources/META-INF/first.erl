%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 4月 2021 15:13
%%%-------------------------------------------------------------------
-module(first).
-author("Administrator").

%% API
-export([nano_get_url/0]).

nano_get_url()  ->
  nano_get_url("www.baidu.com").

nano_get_url(Host)  ->
  {ok,Socket}  =  gen_tcp:connect(Host,80,[binary,{packet,0}]),
  ok = gen_tcp:send(Socket, "Get / HTTP/1.0\r\n\r\n"),
  receive_date(Socket,[]).

receive_date(Socket,SoFar)  ->
  receive
    {tcp,Socket,Bin}  ->
      receive_date(Socket,[Bin|SoFar]);
    {tcp_closed,Socket}  ->
      list_to_binary(lists:reverse(SoFar))
  end.