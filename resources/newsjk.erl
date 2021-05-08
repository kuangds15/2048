%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 4月 2021 4:49
%%%-------------------------------------------------------------------
-module(newsjk).
-author("Administrator").

%% API
-export([]).
-import(lists, [foreach/2]).
-compile(export_all).
-record(shop, {item, quantity, cost}).

do_this_once() ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(shop, [{attributes, record_info(fields, shop)}]),
  mnesia:stop().

start() ->
  mnesia:stop(),
  mnesia:start(),
  mnesia:wait_for_tables([shop], 2000),
  init_table(shop_info()).

get_all(TabelName) ->
  Qh =qlc:q([X || X <- mnesia:table(TabelName)]),
  F = fun() -> qlc:e(Qh) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

shop_info() ->
  [%% The shop table
    {shop, apple, 20, 2.3},
    {shop, orange, 100, 3.8},
    {shop, pear, 200, 3.6},
    {shop, banana, 420, 4.5}
  ].
init_table(TableData) ->
  F = fun(Model) -> mnesia:dirty_write(Model) end,
  lists:foreach(F, TableData).

delete(Item) ->
  Oid = {shop, Item},
  F = fun() ->
    mnesia:delete(Oid)
      end,
  mnesia:transaction(F).

dirty_delete(Item) ->
  Oid = {shop, Item},
  F = fun() ->
    mnesia:dirty_delete(Oid)
      end,
  mnesia:transaction(F).

write() ->
  Oid =  {shop, potato, 2456, 1.2},
  F = fun() ->
    mnesia:write(Oid)
      end,
  mnesia:transaction(F).

dirty_write() ->
  Oid =  {shop, potato, 2456, 1.2},
  F = fun() ->
    mnesia:dirty_write(Oid)
      end,
  mnesia:transaction(F).

execute(Function,Pram) when is_function(Function),is_list(Pram) ->
  F = fun() ->
    apply(Function,Pram)
    ,true = ok  %在事物里制造问题，验证事物的有效性
      end,
  mnesia:transaction(F).