#!/usr/bin/env escript
%% -*- erlang -*-

%% ErlPerf benchmark runner for sock application
%% Provides comprehensive performance testing of SCTP operations

-mode(compile).

main(Args) ->
    io:format("~n=== Sock Application Performance Benchmarks ===~n~n"),
    
    % Parse command line arguments
    Config = parse_args(Args),
    
    % Ensure required applications are available
    setup_environment(),
    
    % Run benchmark suites
    Results = run_benchmark_suites(Config),
    
    % Generate report
    generate_report(Results),
    
    io:format("~n=== Benchmark Complete ===~n").

%% Parse command line arguments
parse_args([]) ->
    #{
        duration => 10,        % seconds per benchmark
        warmup => 2,          % warmup seconds
        concurrency => 1,     % concurrent workers
        suites => all,        % which benchmark suites to run
        output => console     % output format
    };
parse_args(Args) ->
    parse_args(Args, #{
        duration => 10,
        warmup => 2, 
        concurrency => 1,
        suites => all,
        output => console
    }).

parse_args([], Config) ->
    Config;
parse_args(["-d", Duration | Rest], Config) ->
    parse_args(Rest, Config#{duration => list_to_integer(Duration)});
parse_args(["-w", Warmup | Rest], Config) ->
    parse_args(Rest, Config#{warmup => list_to_integer(Warmup)});
parse_args(["-c", Concurrency | Rest], Config) ->
    parse_args(Rest, Config#{concurrency => list_to_integer(Concurrency)});
parse_args(["-s", Suites | Rest], Config) ->
    SuiteList = string:tokens(Suites, ","),
    parse_args(Rest, Config#{suites => [list_to_atom(S) || S <- SuiteList]});
parse_args(["-o", Output | Rest], Config) ->
    parse_args(Rest, Config#{output => list_to_atom(Output)});
parse_args(["-h" | _], _Config) ->
    print_help(),
    halt(0);
parse_args([Unknown | _], _Config) ->
    io:format("Unknown argument: ~s~n", [Unknown]),
    print_help(),
    halt(1).

print_help() ->
    io:format("Usage: escript run_benchmarks.erl [options]~n"),
    io:format("Options:~n"),
    io:format("  -d <seconds>     Duration per benchmark (default: 10)~n"),
    io:format("  -w <seconds>     Warmup duration (default: 2)~n"),
    io:format("  -c <workers>     Concurrent workers (default: 1)~n"),
    io:format("  -s <suites>      Comma-separated suite names (default: all)~n"),
    io:format("                   Available: endpoint,association,lifecycle,messaging~n"),
    io:format("  -o <format>      Output format: console|csv|json (default: console)~n"),
    io:format("  -h               Show this help~n").

%% Setup the environment for benchmarking
setup_environment() ->
    % Add current directory to code path
    code:add_path("../ebin"),
    code:add_path("../_build/bench/lib/erlperf/ebin"),
    code:add_path("../_build/bench/lib/sock/ebin"),
    code:add_path("../_build/default/lib/sock/ebin"),

    % Ensure erlperf is available
    case code:which(erlperf) of
        non_existing ->
            io:format("Error: erlperf not found. Run: rebar3 as bench compile~n"),
            halt(1);
        _ ->
            ok
    end.

%% Run all benchmark suites
run_benchmark_suites(Config) ->
    Suites = case maps:get(suites, Config) of
        all -> [endpoint, association, lifecycle, messaging];
        List -> List
    end,
    
    io:format("Running benchmark suites: ~p~n~n", [Suites]),
    
    Results = [run_suite(Suite, Config) || Suite <- Suites],
    lists:flatten(Results).

%% Run a specific benchmark suite
run_suite(endpoint, Config) ->
    io:format("=== Endpoint Creation Benchmarks ===~n"),
    [
        run_benchmark("create_ep_simple", sock_bench, create_ep_simple, Config),
        run_benchmark("create_ep_with_port", sock_bench, create_ep_with_port, Config),
        run_benchmark("create_ep_with_options", sock_bench, create_ep_with_options, Config)
    ];

run_suite(association, Config) ->
    io:format("=== Association Creation Benchmarks ===~n"),
    [
        run_benchmark("create_assoc_loopback", sock_bench, create_assoc_loopback, Config),
        run_benchmark("create_assoc_with_server", sock_bench, create_assoc_with_server, Config)
    ];

run_suite(lifecycle, Config) ->
    io:format("=== Connection Lifecycle Benchmarks ===~n"),
    [
        run_benchmark("full_connection_cycle", sock_bench, full_connection_cycle, Config),
        run_benchmark("concurrent_connections", sock_bench, concurrent_connections, Config)
    ];

run_suite(messaging, Config) ->
    io:format("=== Binary Messaging Benchmarks (Future) ===~n"),
    [
        run_benchmark("send_small_binary", sock_bench, send_small_binary, Config),
        run_benchmark("send_large_binary", sock_bench, send_large_binary, Config),
        run_benchmark("send_burst_messages", sock_bench, send_burst_messages, Config)
    ].

%% Run a single benchmark
run_benchmark(Name, Module, Function, Config) ->
    Duration = maps:get(duration, Config),
    Warmup = maps:get(warmup, Config),
    Concurrency = maps:get(concurrency, Config),
    
    io:format("Running ~s... ", [Name]),
    
    % Setup any persistent state if needed
    setup_benchmark(Name),
    
    try
        % Run the benchmark using erlperf
        {Time, Result} = timer:tc(fun() ->
            run_erlperf_benchmark(Module, Function, Duration, Warmup, Concurrency)
        end),
        
        io:format("Done (~.2f ms)~n", [Time / 1000]),
        
        #{
            name => Name,
            module => Module,
            function => Function,
            result => Result,
            duration => Duration,
            concurrency => Concurrency,
            status => success
        }
    catch
        Error:Reason:Stacktrace ->
            io:format("Failed: ~p:~p~n", [Error, Reason]),
            #{
                name => Name,
                module => Module, 
                function => Function,
                error => {Error, Reason},
                stacktrace => Stacktrace,
                status => failed
            }
    after
        cleanup_benchmark(Name)
    end.

%% Setup benchmark-specific state
setup_benchmark("create_assoc_with_server") ->
    sock_bench:setup_server();
setup_benchmark(_) ->
    ok.

%% Cleanup benchmark-specific state  
cleanup_benchmark("create_assoc_with_server") ->
    try
        ServerEP = persistent_term:get(bench_server_ep),
        ServerPort = persistent_term:get(bench_server_port),
        sock_bench:cleanup_server({ServerEP, ServerPort})
    catch
        _:_ -> ok
    end;
cleanup_benchmark(_) ->
    sock_bench:cleanup_application().

%% Run benchmark using erlperf
run_erlperf_benchmark(Module, Function, Duration, Warmup, Concurrency) ->
    % Create a simple benchmark function
    BenchFun = fun() -> Module:Function() end,
    
    % Run warmup
    io:format("(warmup ~ps) ", [Warmup]),
    [BenchFun() || _ <- lists:seq(1, Warmup * 10)],
    
    % Run actual benchmark
    StartTime = erlang:monotonic_time(millisecond),
    EndTime = StartTime + (Duration * 1000),
    
    Count = run_benchmark_loop(BenchFun, EndTime, 0),
    ActualDuration = erlang:monotonic_time(millisecond) - StartTime,
    
    OpsPerSecond = (Count * 1000) / ActualDuration,
    
    #{
        operations => Count,
        duration_ms => ActualDuration,
        ops_per_second => OpsPerSecond,
        concurrency => Concurrency
    }.

%% Benchmark execution loop
run_benchmark_loop(Fun, EndTime, Count) ->
    case erlang:monotonic_time(millisecond) < EndTime of
        true ->
            Fun(),
            run_benchmark_loop(Fun, EndTime, Count + 1);
        false ->
            Count
    end.

%% Generate benchmark report
generate_report(Results) ->
    io:format("~n=== Benchmark Results ===~n"),
    io:format("~-30s ~-12s ~-15s ~-10s~n", ["Benchmark", "Status", "Ops/Second", "Duration"]),
    io:format("~s~n", [lists:duplicate(70, $-)]),
    
    [print_result(Result) || Result <- Results],
    
    % Summary statistics
    SuccessResults = [R || R <- Results, maps:get(status, R) == success],
    FailedCount = length(Results) - length(SuccessResults),
    
    io:format("~n=== Summary ===~n"),
    io:format("Total benchmarks: ~p~n", [length(Results)]),
    io:format("Successful: ~p~n", [length(SuccessResults)]),
    io:format("Failed: ~p~n", [FailedCount]),
    
    if FailedCount > 0 ->
        io:format("~nFailed benchmarks:~n"),
        [io:format("  ~s: ~p~n", [maps:get(name, R), maps:get(error, R)]) 
         || R <- Results, maps:get(status, R) == failed];
       true -> ok
    end.

print_result(#{status := success, name := Name, result := Result}) ->
    OpsPerSec = maps:get(ops_per_second, Result),
    Duration = maps:get(duration_ms, Result),
    io:format("~-30s ~-12s ~-15.2f ~-10.2f~n", 
              [Name, "SUCCESS", OpsPerSec, Duration]);

print_result(#{status := failed, name := Name, error := _Error}) ->
    io:format("~-30s ~-12s ~-15s ~-10s~n",
              [Name, "FAILED", "-", "-"]).
