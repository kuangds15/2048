%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 4月 2021 19:57
%%%-------------------------------------------------------------------
-module(shujuku).
-author("Administrator").

%% API
-export([do_this_once/0]).

-record(shop,{item,quantity,cost}).
-record(cost,{name,price}).

do_this_once()  ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(shop,[{attributes,record_info(fields,shop)}]),
  mnesia:create_table(cost,[{attributes,record_info(fields,cost)}]),
  mnesia:create_table(design,  [attributes,record_info(files,design)]),
  mnesia:stop().

