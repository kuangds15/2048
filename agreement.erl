%%%-------------------------------------------------------------------
%%% @author linjinyuan
%%% @copyright (C) 2020, <COMPANY>
%%% @doc  处理协议：封包、解包
%%%
%%% @end
%%% Created : 26. 5月 2020 17:12
%%%-------------------------------------------------------------------
-module(agreement).
-author("linjinyuan").

%% API
-export([packet/2, unpacket1/1, unpacket/1]).

%%封包
packet(State, Date) ->
  case Date of
    {} ->
      <<State:16>>;
    {Request1} ->
      R1 = term_to_binary(Request1),
      <<State:16, (byte_size(R1)):16, R1/binary>>;
    {Request1, Request2} ->
      R1 = term_to_binary(Request1),
      R2 = term_to_binary(Request2),
      <<State:16, (byte_size(R1)):16, R1/binary, (byte_size(R2)):16, R2/binary>>;
    {Request1, Request2, Request3} ->
      R1 = term_to_binary(Request1),
      R2 = term_to_binary(Request2),
      R3 = term_to_binary(Request3),
      <<State:16, (byte_size(R1)):16, R1/binary, (byte_size(R2)):16, R2/binary, (byte_size(R3)):16, R3/binary>>
  end.


%%解包
unpacket(Bin) ->
  case Bin of
    <<State:16>> ->
      State;
    <<State:16, R1:16, Request1:R1/binary>> ->
      {State, binary_to_term(Request1)};
    <<State:16, R1:16, Request1:R1/binary, R2:16, Request2:R2/binary>> ->
      {State, binary_to_term(Request1), binary_to_term(Request2)};
    <<State:16, R1:16, Request1:R1/binary, R2:16, Request2:R2/binary, R3:16, Request3:R3/binary>> ->
      {State, binary_to_term(Request1), binary_to_term(Request2), binary_to_term(Request3)}
  end.


unpacket1(Bin) ->
  <<State:16, _Date/binary>> = Bin,
  State.




