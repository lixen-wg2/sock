-module(sock_bench).

%% ErlPerf benchmark module for sock application
%% Tests SCTP connection establishment and management performance

-export([
    % Endpoint benchmarks
    create_ep_simple/0,
    create_ep_with_port/0,
    create_ep_with_options/0,
    
    % Association benchmarks  
    create_assoc_loopback/0,
    create_assoc_with_server/0,
    
    % Connection lifecycle benchmarks
    full_connection_cycle/0,
    concurrent_connections/0,
    
    % Future: Binary message sending benchmarks
    send_small_binary/0,
    send_large_binary/0,
    send_burst_messages/0,
    
    % Benchmark setup/teardown helpers
    setup_application/0,
    cleanup_application/0,
    get_free_port/0,
    setup_server/0,
    cleanup_server/1
]).

%% Benchmark: Simple endpoint creation
%% Tests the basic performance of creating SCTP endpoints
create_ep_simple() ->
    {ok, _EP} = sock:create_ep(),
    % Cleanup is handled by application teardown
    ok.

%% Benchmark: Endpoint creation with specific port
%% Tests performance when binding to specific ports
create_ep_with_port() ->
    Port = get_free_port(),
    {ok, _EP} = sock:create_ep([loopback], Port, []),
    ok.

%% Benchmark: Endpoint creation with options
%% Tests performance with various SCTP options
create_ep_with_options() ->
    Port = get_free_port(),
    Options = [{accept, 1}, {protocol, sctp}],
    {ok, _EP} = sock:create_ep([loopback], Port, Options),
    ok.

%% Benchmark: Association creation to loopback
%% Tests basic association creation performance
create_assoc_loopback() ->
    % Create server endpoint
    ServerPort = get_free_port(),
    {ok, _ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),

    % Create client endpoint
    ClientPort = get_free_port(),
    {ok, _ClientEP} = sock:create_ep([loopback], ClientPort, []),

    % Create association
    {ok, _AssocPid} = sock:create_assoc(_ClientEP, [loopback], ServerPort, []),

    ok.

%% Benchmark: Association creation with established server
%% Tests association performance with pre-established server
create_assoc_with_server() ->
    % Server is set up once, associations created repeatedly
    ServerEP = persistent_term:get(bench_server_ep),
    ServerPort = persistent_term:get(bench_server_port),
    
    % Create client endpoint
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    
    % Create association
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    ok.

%% Benchmark: Full connection lifecycle
%% Tests complete connection setup and teardown
full_connection_cycle() ->
    setup_application(),
    
    % Create server
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    % Create client and connect
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    % Wait for connection establishment
    timer:sleep(10),
    
    % Verify connection
    {ok, Paths} = sock:get_paths(AssocPid),
    
    ok.

%% Benchmark: Concurrent connections
%% Tests performance under concurrent connection load
concurrent_connections() ->
    setup_application(),
    
    % Create server that accepts multiple connections
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 10}]),
    
    % Create multiple client connections concurrently
    Clients = [begin
        ClientPort = get_free_port(),
        {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
        {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
        {ClientEP, AssocPid}
    end || _ <- lists:seq(1, 5)],
    
    % Wait for all connections
    timer:sleep(50),
    
    ok.

%% Future benchmark: Send small binary message
%% Placeholder for when binary sending is implemented
send_small_binary() ->
    % This will be implemented when sock library adds send functionality
    % For now, just test connection setup
    setup_application(),
    
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    % TODO: Add actual binary sending when API is available
    % Binary = <<1,2,3,4,5,6,7,8,9,10>>,
    % ok = sock:send(AssocPid, Binary),
    
    timer:sleep(5),
    ok.

%% Future benchmark: Send large binary message  
%% Placeholder for large message performance testing
send_large_binary() ->
    % This will be implemented when sock library adds send functionality
    setup_application(),
    
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    % TODO: Add actual binary sending when API is available
    % Binary = crypto:strong_rand_bytes(1024), % 1KB message
    % ok = sock:send(AssocPid, Binary),
    
    timer:sleep(10),
    ok.

%% Future benchmark: Send burst of messages
%% Placeholder for message burst performance testing
send_burst_messages() ->
    % This will be implemented when sock library adds send functionality
    setup_application(),
    
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 1}]),
    
    ClientPort = get_free_port(),
    {ok, ClientEP} = sock:create_ep([loopback], ClientPort, []),
    {ok, AssocPid} = sock:create_assoc(ClientEP, [loopback], ServerPort, []),
    
    % TODO: Add actual binary sending when API is available
    % [ok = sock:send(AssocPid, <<I:32>>) || I <- lists:seq(1, 10)],
    
    timer:sleep(20),
    ok.

%% Helper: Setup sock application
setup_application() ->
    case application:ensure_all_started(sock) of
        {ok, _} -> ok;
        {error, {already_started, sock}} -> ok;
        {error, Reason} -> error({setup_failed, Reason})
    end.

%% Helper: Cleanup sock application  
cleanup_application() ->
    application:stop(sock).

%% Helper: Get a free port for testing
get_free_port() ->
    {ok, Socket} = gen_tcp:listen(0, []),
    {ok, Port} = inet:port(Socket),
    gen_tcp:close(Socket),
    Port.

%% Helper: Setup persistent server for benchmarks
setup_server() ->
    setup_application(),
    ServerPort = get_free_port(),
    {ok, ServerEP} = sock:create_ep([loopback], ServerPort, [{accept, 100}]),
    persistent_term:put(bench_server_ep, ServerEP),
    persistent_term:put(bench_server_port, ServerPort),
    {ServerEP, ServerPort}.

%% Helper: Cleanup persistent server
cleanup_server({ServerEP, _Port}) ->
    persistent_term:erase(bench_server_ep),
    persistent_term:erase(bench_server_port),
    cleanup_application().
