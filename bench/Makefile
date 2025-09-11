# Makefile for Sock Application Benchmarks
# Provides convenient targets for running performance tests

.PHONY: all bench quick full endpoint association lifecycle messaging clean help

# Default target
all: bench

# Quick benchmark run (5 seconds per test)
quick:
	@echo "Running quick benchmarks (5s per test)..."
	@escript run_benchmarks.erl -d 5 -w 1

# Standard benchmark run (10 seconds per test)  
bench:
	@echo "Running standard benchmarks (10s per test)..."
	@escript run_benchmarks.erl

# Full benchmark run (30 seconds per test)
full:
	@echo "Running full benchmarks (30s per test)..."
	@escript run_benchmarks.erl -d 30 -w 5

# Concurrent benchmark run
concurrent:
	@echo "Running concurrent benchmarks (4 workers)..."
	@escript run_benchmarks.erl -c 4

# Individual benchmark suites
endpoint:
	@echo "Running endpoint creation benchmarks..."
	@escript run_benchmarks.erl -s endpoint

association:
	@echo "Running association creation benchmarks..."
	@escript run_benchmarks.erl -s association

lifecycle:
	@echo "Running connection lifecycle benchmarks..."
	@escript run_benchmarks.erl -s lifecycle

messaging:
	@echo "Running messaging benchmarks (future)..."
	@escript run_benchmarks.erl -s messaging

# Performance comparison (run multiple times)
compare:
	@echo "Running performance comparison (3 runs)..."
	@for i in 1 2 3; do \
		echo "=== Run $$i ==="; \
		escript run_benchmarks.erl -d 15; \
		echo; \
	done

# Stress test with high concurrency
stress:
	@echo "Running stress test (8 workers, 60s)..."
	@escript run_benchmarks.erl -c 8 -d 60

# Generate CSV output for analysis
csv:
	@echo "Generating CSV benchmark results..."
	@escript run_benchmarks.erl -o csv > benchmark_results.csv
	@echo "Results saved to benchmark_results.csv"

# Clean up any temporary files
clean:
	@echo "Cleaning up temporary files..."
	@rm -f benchmark_results.csv
	@rm -f *.beam
	@rm -f erl_crash.dump

# Show help
help:
	@echo "Sock Application Benchmark Targets:"
	@echo ""
	@echo "  quick      - Quick benchmark run (5s per test)"
	@echo "  bench      - Standard benchmark run (10s per test) [default]"
	@echo "  full       - Full benchmark run (30s per test)"
	@echo "  concurrent - Concurrent benchmark run (4 workers)"
	@echo ""
	@echo "  endpoint   - Endpoint creation benchmarks only"
	@echo "  association- Association creation benchmarks only"
	@echo "  lifecycle  - Connection lifecycle benchmarks only"
	@echo "  messaging  - Messaging benchmarks only (future)"
	@echo ""
	@echo "  compare    - Run benchmarks 3 times for comparison"
	@echo "  stress     - Stress test with high concurrency"
	@echo "  csv        - Generate CSV output"
	@echo ""
	@echo "  clean      - Clean up temporary files"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make quick           # Fast benchmark run"
	@echo "  make endpoint        # Test only endpoint creation"
	@echo "  make concurrent      # Test with multiple workers"
	@echo "  make csv             # Generate CSV for analysis"
