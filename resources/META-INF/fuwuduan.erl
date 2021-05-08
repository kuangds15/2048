%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 4月 2021 19:32
%%%-------------------------------------------------------------------
-module(fuwuduan).
-author("Administrator").

%% API
-export([start/0]).

   start()  ->
     {ok,Listen}  =  gen_tcp:listen(2345,[binary,{packet,4},{reuseaddr,true},{active,true}]),
       spawn(fun() -> connect(Listen) end ).

     connect(Listen)  ->
       {ok,Socket} = gen_tcp:accept(Listen),
       spawn(fun() -> connect(Listen) end ),
       loop(Socket).

   loop(Socket)  ->
     receive
       {tcp,Socket,Bin}  ->
                          ;
       {tcp_close,Socket} ->
         io:format("Server socket close~n")
     end

