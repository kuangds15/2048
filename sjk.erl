%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 4月 2021 0:56
%%%-------------------------------------------------------------------
-module(sjk).
-author("Administrator").

%% API
-export([do_this_once/0,add_shop_item/3,demo/1]).

-record(shop,{item,quantity,cost}).
-record(cost,{name,price}).

do_this_once()  ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(shop,[{attributes,record_info(fields,shop)}]),
  mnesia:create_table(cost,[{attributes,record_info(fields,cost)}]),
  mnesia:stop().

add_shop_item(Name,Quantity,Cost)  ->
  Row = #shop{item = Name,quantity = Quantity,cost = Cost},
  F = fun() -> mnesia:write(Row)
    end,
  mnesia:transaction(F).

demo(select_shop)  ->
  do(qlc:q([X || X <- mnesia:table(shop)])).

do(Q)  ->
  F= fun()  ->
    qlc:e(Q)
     end,
  {atomic,Val}  = mnesia:transaction(F),
  Val.