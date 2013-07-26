%%%-------------------------------------------------------------------
%%% @author Pawel Chrzaszcz
%%% @copyright (C) 2013, Erlang Solutions Ltd.
%%% @doc Script generation utilities
%%%
%%% @end
%%% Created : 26 Jul 2013 by pawel.chrzaszcz@erlang-solutions.com
%%%-------------------------------------------------------------------
-module(dyntrace_gen_util).

-compile(export_all).

sep(Args, Sep) ->
    sep_f(Args, Sep, fun(Arg) -> Arg end).

sep_t(Tag, Args, Sep) ->
    sep_f(Args, Sep, fun(Arg) -> {Tag, Arg} end).

sep_f([A, B | T], Sep, F) -> [F(A), Sep | sep_f([B|T], Sep, F)];
sep_f([H], _Sep, F)       -> [F(H)];
sep_f([], _Sep, _F)       -> [].