%%%-------------------------------------------------------------------
%%% @author Pawel Chrzaszcz
%%% @copyright (C) 2013, Erlang Solutions Ltd.
%%% @doc Test utilities
%%%
%%% @end
%%% Created : 12 Aug 2013 by pawel.chrzaszcz@erlang-solutions.com
%%%-------------------------------------------------------------------
-module(tracerl_test_util).

-include_lib("test_server/include/test_server.hrl").

-compile(export_all).

all_if_dyntrace(All) ->
    case erlang:system_info(dynamic_trace) of
        none -> {skip, "No dynamic trace in this run-time system"};
        _    -> All
    end.

start_trace(ScriptSrc) ->
    Self = self(),
    Collector = spawn(fun() -> collect(Self, []) end),
    {ok, DP} = tracerl_process:start_link(ScriptSrc, node(),
                                           fun(Msg) -> Collector ! Msg end),
    ct:log(gen_server:call(DP, get_script)),
    DP.

collect(Dest, Output) ->
    receive
        {line, "DEBUG " ++ _ = L} ->
            TermL = termify_line(L),
            collect(Dest, [TermL|Output]);
        {line, L} ->
            TermL = termify_line(L),
            Dest ! {line, TermL},
            collect(Dest, [TermL|Output]);
        eof ->
            ct:log("trace output:~n~p~n", [lists:reverse(Output)]),
            Dest ! eof
    end.

termify_line(L) ->
    [termify_token(Token) || Token <- re:split(L, " ", [{return,list}])].

termify_token(L) ->
    try list_to_integer(L)
    catch error:badarg ->
            try list_to_pid(L)
            catch error:badarg -> L
            end
    end.

%%%-------------------------------------------------------------------
%%% Test helpers
%%%-------------------------------------------------------------------
send_n(StartNo, EndNo) ->
    send_all(lists:seq(StartNo, EndNo)).

receive_n(StartNo, EndNo) ->
    receive_all(lists:seq(StartNo, EndNo)).

send_all(Messages) ->
    receive {start, Receiver} -> ok end,
    [Receiver ! Msg || Msg <- Messages].

receive_all(Messages) ->
    [receive Msg -> ok end || Msg <- Messages].

ring_start(ProcNum) ->
    lists:sort([spawn(fun ring_proc/0) || _ <- lists:seq(1, ProcNum)]).

ring_stop(Ps) ->
    [P ! stop || P <- Ps].

ring_proc() ->
    receive
        [Ps|Rest] when is_list(Ps) ->
            [P ! Rest || P <- Ps],
            ring_proc();
        [{notify, Pid, Ref}] ->
            Pid ! {finished, Ref},
            ring_proc();
        [Next|Rest] ->
            Next ! Rest,
            ring_proc();
        [] ->
            ring_proc();
        stop ->
            ok
    end.

ring_send(Ps, MsgNum, Pid) ->
    Ref = make_ref(),
    lists:last(Ps) ! lists:flatten([lists:duplicate(MsgNum, Ps),
                                    {notify, Pid, Ref}]),
    Ref.
