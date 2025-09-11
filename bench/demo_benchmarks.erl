#!/usr/bin/env escript
%% -*- erlang -*-

%% Demo script showing how to run sock benchmarks
%% This provides a simpler alternative to the full erlperf integration

-mode(compile).

main([]) ->
    main(["demo"]);
main(["demo"]) ->
    io:format("~n=== Sock Application Benchmark Demo ===~n~n"),
    
    % Setup
    setup_environment(),
    
    % Run demo benchmarks
    run_demo_benchmarks(),
    
    io:format("~n=== Demo Complete ===~n");

main(["time", Function]) ->
    setup_environment(),
    time_single_benchmark(list_to_atom(Function));

main(["help"]) ->
    print_help();

main(_) ->
    print_help().

print_help() ->
    io:format("Usage: escript demo_benchmarks.erl [command]~n"),
    io:format("Commands:~n"),
    io:format("  demo                 - Run demonstration benchmarks~n"),
    io:format("  time <function>      - Time a specific benchmark function~n"),
    io:format("  help                 - Show this help~n"),
    io:format("~n"),
    io:format("Available benchmark functions:~n"),
    io:format("  create_ep_simple~n"),
    io:format("  create_ep_with_port~n"),
    io:format("  create_ep_with_options~n"),
    io:format("  create_assoc_loopback~n").

setup_environment() ->
    % Add paths
    code:add_path("../ebin"),
    code:add_path("../_build/bench/lib/sock/ebin"),
    code:add_path("../_build/default/lib/sock/ebin"),
    
    % Start sock application
    case application:ensure_all_started(sock) of
        {ok, _} -> 
            io:format("Sock application started successfully~n");
        {error, {already_started, sock}} -> 
            io:format("Sock application already running~n");
        {error, Reason} -> 
            io:format("Failed to start sock application: ~p~n", [Reason]),
            halt(1)
    end.

run_demo_benchmarks() ->
    Benchmarks = [
        {"Endpoint Creation (Simple)", fun demo_create_ep_simple/0},
        {"Endpoint Creation (With Port)", fun demo_create_ep_with_port/0},
        {"Endpoint Creation (With Options)", fun demo_create_ep_with_options/0},
        {"Association Creation", fun demo_create_assoc/0},
        {"Connection Lifecycle", fun demo_connection_lifecycle/0}
    ],
    
    [run_demo_benchmark(Name, Fun) || {Name, Fun} <- Benchmarks].

run_demo_benchmark(Name, Fun) ->
    io:format("~n--- ~s ---~n", [Name]),
    
    % Warmup
    io:format("Warming up... "),
    [Fun() || _ <- lists:seq(1, 5)],
    io:format("done~n"),
    
    % Measure
    io:format("Running benchmark... "),
    Count = 20,
    {Time, _} = timer:tc(fun() ->
        [Fun() || _ <- lists:seq(1, Count)]
    end),
    
    AvgTime = Time / Count,
    OpsPerSec = 1000000 / AvgTime,
    
    io:format("done~n"),
    io:format("Results: ~.2f ops/sec (avg ~.2f μs per op)~n", [OpsPerSec, AvgTime]).

time_single_benchmark(Function) ->
    io:format("Timing ~p...~n", [Function]),
    
    Fun = case Function of
        create_ep_simple -> fun demo_create_ep_simple/0;
        create_ep_with_port -> fun demo_create_ep_with_port/0;
        create_ep_with_options -> fun demo_create_ep_with_options/0;
        create_assoc_loopback -> fun demo_create_assoc/0;
        _ ->
            io:format("Unknown function: ~p~n", [Function]),
            halt(1)
    end,
    
    % Run multiple times and show statistics
    Times = [begin
        {Time, _} = timer:tc(Fun),
        Time
    end || _ <- lists:seq(1, 10)],
    
    MinTime = lists:min(Times),
    MaxTime = lists:max(Times),
    AvgTime = lists:sum(Times) / length(Times),
    
    io:format("Results over 10 runs:~n"),
    io:format("  Min: ~.2f μs (~.2f ops/sec)~n", [MinTime, 1000000/MinTime]),
    io:format("  Max: ~.2f μs (~.2f ops/sec)~n", [MaxTime, 1000000/MaxTime]),
    io:format("  Avg: ~.2f μs (~.2f ops/sec)~n", [AvgTime, 1000000/AvgTime]).

%% Demo benchmark functions (simplified versions)

demo_create_ep_simple() ->
    {ok, _EP} = sock:create_ep(),
    ok.

demo_create_ep_with_port() ->
    Port = get_free_port(),
    {ok, _EP} = sock:create_ep([loopback], Port, []),
    ok.

demo_create_ep_with_options() ->
    Port = get_free_port(),
    Options = [{accept, 1}, {protocol, sctp}],
    {ok, _EP} = sock:create_ep([loopback], Port, Options),
    ok.

demo_create_assoc() ->
    % Create server
    ServerPort = get_free_port(),
    {ok, _ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    % Create client and connect
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, _AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    ok.

demo_connection_lifecycle() ->
    % Create server
    ServerPort = get_free_port(),
    {ok, _ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    % Create client and connect
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    % Wait for connection
    timer:sleep(10),
    
    % Get paths (verify connection)
    {ok, _Paths} = sock:get_paths(AssocPid),
    
    ok.

%% Helper functions

get_free_port() ->
    {ok, Socket} = gen_tcp:listen(0, []),
    {ok, Port} = inet:port(Socket),
    gen_tcp:close(Socket),
    Port.
