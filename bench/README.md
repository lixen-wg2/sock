# Sock Application Performance Benchmarks

This directory contains comprehensive performance benchmarks for the sock application using ErlPerf. The benchmarks test SCTP connection establishment, management, and prepare for future binary message transmission testing.

## Overview

The benchmark suite is designed to measure:

1. **Endpoint Creation Performance** - How fast SCTP endpoints can be created
2. **Association Creation Performance** - Connection establishment throughput  
3. **Connection Lifecycle Management** - Full connection setup/teardown cycles
4. **Concurrent Connection Handling** - Performance under concurrent load
5. **Binary Message Transmission** - Future benchmarks for data sending (placeholders)

## Prerequisites

1. **ErlPerf**: Install via rebar3 bench profile
2. **SCTP Support**: Ensure your system supports SCTP
3. **Sock Application**: The sock library must be compiled

```bash
# Install dependencies
rebar3 as bench compile

# Verify SCTP support (Linux)
sudo modprobe sctp
lsmod | grep sctp
```

## Running Benchmarks

### Quick Start

```bash
# Run all benchmarks with default settings
escript bench/run_benchmarks.erl

# Run specific benchmark suites
escript bench/run_benchmarks.erl -s endpoint,association

# Run with custom duration and concurrency
escript bench/run_benchmarks.erl -d 30 -c 4
```

### Command Line Options

```
Usage: escript run_benchmarks.erl [options]

Options:
  -d <seconds>     Duration per benchmark (default: 10)
  -w <seconds>     Warmup duration (default: 2)  
  -c <workers>     Concurrent workers (default: 1)
  -s <suites>      Comma-separated suite names (default: all)
                   Available: endpoint,association,lifecycle,messaging
  -o <format>      Output format: console|csv|json (default: console)
  -h               Show help
```

### Alternative: Direct ErlPerf Usage

```bash
# Start Erlang shell with bench profile
rebar3 as bench shell

# Run individual benchmarks
1> erlperf:run(sock_bench, create_ep_simple, #{}).
2> erlperf:run(sock_bench, create_assoc_loopback, #{}).
```

## Benchmark Suites

### 1. Endpoint Creation (`endpoint`)

Tests the performance of creating SCTP endpoints with various configurations:

- **`create_ep_simple`**: Basic endpoint creation with default settings
- **`create_ep_with_port`**: Endpoint creation bound to specific ports
- **`create_ep_with_options`**: Endpoint creation with SCTP options

**Expected Performance**: 1000-10000 ops/sec depending on system

### 2. Association Creation (`association`)

Tests SCTP association (connection) establishment performance:

- **`create_assoc_loopback`**: Basic association creation to loopback
- **`create_assoc_with_server`**: Association creation with persistent server

**Expected Performance**: 100-1000 ops/sec depending on system

### 3. Connection Lifecycle (`lifecycle`)

Tests complete connection management cycles:

- **`full_connection_cycle`**: Complete setup and teardown cycle
- **`concurrent_connections`**: Multiple simultaneous connections

**Expected Performance**: 50-500 ops/sec depending on complexity

### 4. Binary Messaging (`messaging`) - Future

Placeholder benchmarks for when binary sending is implemented:

- **`send_small_binary`**: Small message (10 bytes) transmission
- **`send_large_binary`**: Large message (1KB) transmission  
- **`send_burst_messages`**: Burst of multiple messages

**Note**: These currently only test connection setup as the sock library doesn't yet implement data transmission.

## Benchmark Implementation

### Core Benchmark Module

The `sock_bench.erl` module contains all benchmark functions. Each benchmark:

1. Sets up the sock application
2. Creates necessary endpoints/associations
3. Performs the measured operation
4. Cleans up resources

### Key Design Principles

- **Isolation**: Each benchmark runs independently
- **Cleanup**: Proper resource cleanup after each test
- **Realistic**: Tests real-world usage patterns
- **Scalable**: Supports concurrent execution
- **Future-Ready**: Prepared for binary messaging features

## Performance Expectations

### Typical Results (Development Machine)

```
Benchmark                      Status       Ops/Second      Duration
----------------------------------------------------------------------
create_ep_simple              SUCCESS      2500.00         10000.00
create_ep_with_port           SUCCESS      2200.00         10000.00  
create_ep_with_options        SUCCESS      2000.00         10000.00
create_assoc_loopback         SUCCESS      450.00          10000.00
create_assoc_with_server      SUCCESS      520.00          10000.00
full_connection_cycle         SUCCESS      180.00          10000.00
concurrent_connections        SUCCESS      95.00           10000.00
```

### Performance Factors

- **System Resources**: CPU, memory, network stack
- **SCTP Implementation**: Kernel SCTP vs userspace
- **Erlang VM**: Scheduler configuration, memory settings
- **Concurrency Level**: Number of parallel workers

## Troubleshooting

### Common Issues

1. **SCTP Not Available**
   ```bash
   # Linux: Install and load SCTP module
   sudo apt-get install libsctp-dev
   sudo modprobe sctp
   ```

2. **Port Conflicts**
   - Benchmarks use dynamic port allocation
   - Ensure sufficient ephemeral ports available

3. **Memory Issues**
   - Large concurrent tests may need more memory
   - Adjust Erlang VM memory settings if needed

4. **Permission Issues**
   - Some systems require privileges for SCTP
   - Run with appropriate permissions

### Debug Mode

```bash
# Run with verbose output
ERL_FLAGS="+P 1000000" escript bench/run_benchmarks.erl -d 5

# Check SCTP availability
ss -l | grep sctp
```

## Extending Benchmarks

### Adding New Benchmarks

1. Add function to `sock_bench.erl`:
   ```erlang
   my_new_benchmark() ->
       setup_application(),
       % Your benchmark code here
       ok.
   ```

2. Export the function:
   ```erlang
   -export([my_new_benchmark/0]).
   ```

3. Add to benchmark runner in appropriate suite

### Custom Benchmark Suites

Create new benchmark modules following the same pattern:

```erlang
-module(my_custom_bench).
-export([my_benchmark/0]).

my_benchmark() ->
    % Benchmark implementation
    ok.
```

## Future Enhancements

When the sock library implements binary message transmission:

1. **Update Messaging Benchmarks**: Replace placeholders with actual send operations
2. **Add Receive Benchmarks**: Test message reception performance  
3. **Throughput Tests**: Measure data transfer rates
4. **Latency Tests**: Measure round-trip times
5. **Stress Tests**: High-load scenarios with large message volumes

## Integration with CI/CD

The benchmark suite can be integrated into continuous integration:

```bash
# Performance regression detection
escript bench/run_benchmarks.erl -d 30 -o json > results.json

# Compare with baseline performance
# (Implementation depends on your CI system)
```

## Contributing

When adding new benchmarks:

1. Follow existing naming conventions
2. Include proper setup/cleanup
3. Add documentation to this README
4. Test on multiple systems if possible
5. Consider both single-threaded and concurrent scenarios
