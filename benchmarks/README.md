# Benchmarks

## Scripts

| File | Purpose |
|------|---------|
| `k6.js` | Comprehensive load test template — seeds N entities, random access, mixed read/write |
| `k6-report.js` | Markdown report generator from k6 JSON output |
| `orchestrate.js` | Full pipeline: start JAR → health poll → k6 → report → stop |

## Adapting k6.js to the Problem

This script is a **template**. It will not run without editing. At kickoff:

1. Read the problem PDF — identify the domain entity and REST endpoints.
2. In `setup()`: fill in the POST payload shape and endpoint (replace `[ENDPOINT]`).
3. In `default()`: fill in the read endpoint and write endpoint (replace `[ENDPOINT]`).
4. Adjust `WRITE_RATIO` and `ENTITY_COUNT` to match the problem workload.

## Running

```bash
# Default (50 VUs, 60s, 10% writes, 100 seeded entities)
k6 run --env MODE=baseline benchmarks/k6.js

# Higher load, more entities, more writes
k6 run --env MODE=advanced \
       --env VUS=100 \
       --env DURATION=120s \
       --env WRITE_RATIO=0.2 \
       --env ENTITY_COUNT=500 \
       benchmarks/k6.js

# Override target URL (IPv4 fallback)
k6 run --env TARGET_URL=http://127.0.0.1:8080 benchmarks/k6.js

# Generate report from JSON
node benchmarks/k6-report.js evidence/k6-advanced.json --baseline evidence/k6-baseline.json
```

## Running via Orchestrator

```bash
# From repo root
./run-experiment.sh baseline
./run-experiment.sh advanced
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET_URL` | `http://localhost:8080` | Service base URL |
| `SERVICE_URL` | `http://localhost:8080` | Health poll URL (orchestrator only) |
| `VUS` | `50` | Virtual users |
| `DURATION` | `60s` | Steady-state duration |
| `RAMP` | `10s` | Ramp-up duration |
| `MODE` | `baseline` | Label for output filename |
| `WRITE_RATIO` | `0.1` | Fraction of requests that are writes |
| `ENTITY_COUNT` | `100` | Entities seeded in setup |
| `P95_THRESHOLD_MS` | `500` | p95 latency SLO from problem PDF (ms) |
| `ERROR_RATE_THRESHOLD` | `0.01` | Max allowed error rate from problem PDF |
| `CHECK_RATE_THRESHOLD` | `0.95` | Min check pass rate |
