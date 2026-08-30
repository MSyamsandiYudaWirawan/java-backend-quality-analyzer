#!/bin/bash
set -uo pipefail

# ============================================================================
# Generic JFR Hypothesis-Driven Diagnosis Script
# ============================================================================
# Dumps per-event evidence from a .jfr recording and emits a markdown report
# that rates competing bottleneck hypotheses (I/O, parking, GC, CPU, locks,
# allocation, exceptions) by confidence — never a single verdict.
#
# Pipeline: h3 — run-experiment.sh --jfr invokes this on the recording flushed
# to evidence/advanced/h3/<repo>/profile.jfr; also works standalone on any
# .jfr path.
#
# Outputs (into -o dir): per-event evidence dumps (cpu.txt, io.txt, gc.txt,
# locks.txt, park.txt, summary.txt, ...) plus <name>-report.md unless
# --no-report.
#
# Exit codes: 0 ok, 1 missing/invalid JFR file or no working jfr binary.
#
# Usage:
#   jfr-diagnose.sh [options] [recording.jfr]
#
#   If <recording.jfr> is omitted, defaults to: evidence/baseline.jfr
#
# Options:
#   -o <dir>     Output directory for evidence and report (default: dir of JFR file)
#   -j <path>    Path to the jfr binary (default: auto-detect)
#   -n <name>    Report name prefix (default: diagnosis)
#   --no-report  Skip markdown report, dump evidence only
#   -h           Show this help
#
# Environment variables (all optional):
#   JFR_CMD               Path to jfr binary (alternative to -j)
#   JAVA_HOME             Used for auto-detecting jfr binary
#   OUT_DIR               Default output directory when -o is not given
#
#   Thresholds for hypothesis confidence:
#   THRESH_IO_COUNT       SocketRead event threshold (default: 500)
#   THRESH_IO_P95_MS      SocketRead p95 threshold in ms (default: 20)
#   THRESH_PARK_COUNT     ThreadPark event threshold (default: 5000)
#   THRESH_CPU_COUNT      ExecutionSample threshold (default: 5000)
#   THRESH_LOCK_COUNT     JavaMonitorEnter threshold (default: 100)
#   THRESH_LOCK_P95_MS    Lock p95 threshold in ms (default: 10)
#   THRESH_ALLOC_COUNT    Allocation sample threshold (default: 20000)
#   THRESH_GC_P99_MS      GC p99 concern threshold in ms (default: 50)
#   THRESH_EX_COUNT       Exception count threshold (default: 100)
#
#   Severity thresholds (used in evidence table + reference section):
#   SEV_PARK_HEALTHY_MS, SEV_PARK_MODERATE_MS, SEV_PARK_CONCERNING_MS
#   SEV_IO_HEALTHY_MS, SEV_IO_MODERATE_MS, SEV_IO_CONCERNING_MS
#   SEV_LOCK_HEALTHY_MS, SEV_LOCK_MODERATE_MS, SEV_LOCK_CONCERNING_MS
#   SEV_GC_HEALTHY_MS, SEV_GC_MODERATE_MS, SEV_GC_CONCERNING_MS
#   SEV_CPU_HEALTHY_PCT, SEV_CPU_MODERATE_PCT, SEV_CPU_CONCERNING_PCT
#   SEV_EX_HEALTHY, SEV_EX_MODERATE, SEV_EX_CONCERNING
#
# Examples:
#   jfr-diagnose.sh                              # uses evidence/baseline.jfr
#   jfr-diagnose.sh recording.jfr
#   jfr-diagnose.sh -o /tmp/analysis -n prod-20250826 recording.jfr
#   JFR_CMD=/usr/lib/jvm/java-21/bin/jfr jfr-diagnose.sh
# ============================================================================

# --- Defaults ----------------------------------------------------------------
REPORT_NAME="${REPORT_NAME:-diagnosis}"
OUT_DIR="${OUT_DIR:-}"
NO_REPORT=0
DEFAULT_JFR_FILE="evidence/baseline.jfr"
MODE=""
JFR_CMD=""

# Hypothesis confidence thresholds
THRESH_IO_COUNT="${THRESH_IO_COUNT:-500}"
THRESH_IO_P95_MS="${THRESH_IO_P95_MS:-20}"
THRESH_PARK_COUNT="${THRESH_PARK_COUNT:-5000}"
THRESH_CPU_COUNT="${THRESH_CPU_COUNT:-5000}"
THRESH_LOCK_COUNT="${THRESH_LOCK_COUNT:-100}"
THRESH_LOCK_P95_MS="${THRESH_LOCK_P95_MS:-10}"
THRESH_ALLOC_COUNT="${THRESH_ALLOC_COUNT:-20000}"
THRESH_GC_P99_MS="${THRESH_GC_P99_MS:-50}"
THRESH_EX_COUNT="${THRESH_EX_COUNT:-100}"

# Severity thresholds (what is healthy / moderate / concerning / critical)
SEV_PARK_HEALTHY_MS="${SEV_PARK_HEALTHY_MS:-1}"
SEV_PARK_MODERATE_MS="${SEV_PARK_MODERATE_MS:-10}"
SEV_PARK_CONCERNING_MS="${SEV_PARK_CONCERNING_MS:-50}"

SEV_IO_HEALTHY_MS="${SEV_IO_HEALTHY_MS:-1}"
SEV_IO_MODERATE_MS="${SEV_IO_MODERATE_MS:-5}"
SEV_IO_CONCERNING_MS="${SEV_IO_CONCERNING_MS:-20}"

SEV_LOCK_HEALTHY_MS="${SEV_LOCK_HEALTHY_MS:-1}"
SEV_LOCK_MODERATE_MS="${SEV_LOCK_MODERATE_MS:-5}"
SEV_LOCK_CONCERNING_MS="${SEV_LOCK_CONCERNING_MS:-20}"

SEV_GC_HEALTHY_MS="${SEV_GC_HEALTHY_MS:-10}"
SEV_GC_MODERATE_MS="${SEV_GC_MODERATE_MS:-50}"
SEV_GC_CONCERNING_MS="${SEV_GC_CONCERNING_MS:-200}"

SEV_CPU_HEALTHY_PCT="${SEV_CPU_HEALTHY_PCT:-50}"
SEV_CPU_MODERATE_PCT="${SEV_CPU_MODERATE_PCT:-80}"
SEV_CPU_CONCERNING_PCT="${SEV_CPU_CONCERNING_PCT:-95}"

SEV_EX_HEALTHY="${SEV_EX_HEALTHY:-10}"
SEV_EX_MODERATE="${SEV_EX_MODERATE:-100}"
SEV_EX_CONCERNING="${SEV_EX_CONCERNING:-1000}"

# --- CLI parsing -------------------------------------------------------------
usage() {
  sed -n '/^# Usage:/,/^# /p' "$0" | sed 's/^# //'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -o) OUT_DIR="$2"; shift 2 ;;
    -j) JFR_CMD="$2"; shift 2 ;;
    -n) REPORT_NAME="$2"; shift 2 ;;
    --no-report) NO_REPORT=1; shift ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    baseline|advanced)
      MODE="$1"
      DEFAULT_JFR_FILE="evidence/${MODE}.jfr"
      shift
      ;;
    *) JFR_FILE="$1"; shift ;;
  esac
done

# --- Validate input ----------------------------------------------------------
JFR_FILE="${JFR_FILE:-$DEFAULT_JFR_FILE}"

if [ ! -f "$JFR_FILE" ]; then
  echo "ERROR: JFR file not found: $JFR_FILE"
  echo ""
  echo "Usage: $0 [options] [recording.jfr]"
  echo "  Default recording: $DEFAULT_JFR_FILE"
  echo "  Run with -h for full help."
  exit 1
fi

# Resolve absolute path for JFR file
JFR_FILE="$(cd "$(dirname "$JFR_FILE")" && pwd)/$(basename "$JFR_FILE")"

# --- Auto-detect jfr CLI -----------------------------------------------------
JFR=""
if [ -n "${JFR_CMD:-}" ]; then
  JFR="$JFR_CMD"
elif command -v jfr &>/dev/null; then
  JFR="$(command -v jfr)"
elif [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/jfr" ]; then
  JFR="$JAVA_HOME/bin/jfr"
else
  # Search common locations
  for candidate in \
    "/usr/lib/jvm/default-java/bin/jfr" \
    "/usr/lib/jvm/java-21-openjdk/bin/jfr" \
    "/usr/lib/jvm/java-21/bin/jfr" \
    "/usr/lib/jvm/java-17-openjdk/bin/jfr" \
    "/usr/lib/jvm/java-17/bin/jfr" \
    "/usr/lib/jvm/java-11-openjdk/bin/jfr" \
    "/usr/lib/jvm/java-11/bin/jfr"; do
    [ -x "$candidate" ] && JFR="$candidate" && break
  done
fi

if [ -z "$JFR" ]; then
  echo "ERROR: jfr command not found."
  echo ""
  echo "Install a JDK (11+) and ensure 'jfr' is on PATH, or set one of:"
  echo "  -j <path>              # CLI flag"
  echo "  JFR_CMD=<path>          # environment variable"
  echo "  JAVA_HOME=<jdk-root>    # environment variable"
  echo ""
  echo "Common install commands:"
  echo "  Ubuntu/Debian:  sudo apt install openjdk-21-jdk"
  echo "  Fedora/RHEL:    sudo dnf install java-21-openjdk-devel"
  echo "  macOS (brew):   brew install openjdk@21"
  exit 1
fi

# Verify it works — use print (tolerates incomplete chunks) not summary
if ! "$JFR" print --events jdk.JVMInformation "$JFR_FILE" >/dev/null 2>&1; then
  echo "ERROR: '$JFR' exists but failed to read '$JFR_FILE'"
  echo "       Ensure the JDK version supports JFR and the file is valid."
  exit 1
fi

# --- Output directory --------------------------------------------------------
if [ -z "$OUT_DIR" ]; then
  # Default: same directory as the JFR file
  OUT_DIR="$(dirname "$JFR_FILE")"
fi

# When mode is specified (baseline/advanced), create a dedicated subfolder
# so each run's evidence stays isolated and easy to compare.
if [ -n "$MODE" ]; then
  OUT_DIR="$OUT_DIR/$MODE"
fi

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

if [ -n "$MODE" ]; then
       REPORT_FILE="$OUT_DIR/diagnosis-report-${MODE}.md"
else
       REPORT_FILE="$OUT_DIR/${REPORT_NAME}-report.md"
fi

echo "JFR Analysis"
echo "============"
echo "JFR file:  $JFR_FILE"
echo "jfr cmd:   $JFR"
echo "Output:    $OUT_DIR"
echo ""

# --- 1. Dump Phase -----------------------------------------------------------
echo "Phase 1: Dumping JFR events ..."

"$JFR" print --events jdk.ExecutionSample        --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/cpu.txt"          2>/dev/null || true
"$JFR" print --events jdk.ObjectAllocationSample    --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/alloc.txt"        2>/dev/null || true
"$JFR" print --events jdk.SocketRead                --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/io.txt"           2>/dev/null || true
"$JFR" print --events jdk.SocketWrite               --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/io_write.txt"     2>/dev/null || true
"$JFR" print --events jdk.ThreadPark                --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/park.txt"         2>/dev/null || true
"$JFR" print --events jdk.JavaMonitorEnter          --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/locks.txt"        2>/dev/null || true
"$JFR" print --events jdk.GCPhasePause                                "$JFR_FILE" > "$OUT_DIR/gc.txt"           2>/dev/null || true
"$JFR" print --events jdk.JavaErrorThrow            --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/exceptions.txt"   2>/dev/null || true
"$JFR" print --events jdk.ExceptionThrow            --stack-depth 32 "$JFR_FILE" > "$OUT_DIR/exceptions2.txt"  2>/dev/null || true
"$JFR" print --events jdk.CPULoad                                    "$JFR_FILE" > "$OUT_DIR/cpu_load.txt"      2>/dev/null || true

"$JFR" summary "$JFR_FILE" > "$OUT_DIR/summary.txt" 2>/dev/null || true
"$JFR" print --events jdk.JVMInformation            "$JFR_FILE" > "$OUT_DIR/jvm_info.txt"    2>/dev/null || true
"$JFR" print --events jdk.OSInformation             "$JFR_FILE" > "$OUT_DIR/os_info.txt"     2>/dev/null || true
"$JFR" print --events jdk.CPUInformation            "$JFR_FILE" > "$OUT_DIR/cpu_info.txt"    2>/dev/null || true

echo "Done."
echo ""

# --- Helper: severity classification -----------------------------------------
# Returns one of: HEALTHY, MODERATE, CONCERNING, CRITICAL, N/A
severity_of() {
  local metric="$1"
  local val="${2:-0}"
  local h m c

  case "$metric" in
    park)
      h="$SEV_PARK_HEALTHY_MS"; m="$SEV_PARK_MODERATE_MS"; c="$SEV_PARK_CONCERNING_MS" ;;
    io)
      h="$SEV_IO_HEALTHY_MS"; m="$SEV_IO_MODERATE_MS"; c="$SEV_IO_CONCERNING_MS" ;;
    lock)
      h="$SEV_LOCK_HEALTHY_MS"; m="$SEV_LOCK_MODERATE_MS"; c="$SEV_LOCK_CONCERNING_MS" ;;
    gc)
      h="$SEV_GC_HEALTHY_MS"; m="$SEV_GC_MODERATE_MS"; c="$SEV_GC_CONCERNING_MS" ;;
    cpu_load)
      h="$SEV_CPU_HEALTHY_PCT"; m="$SEV_CPU_MODERATE_PCT"; c="$SEV_CPU_CONCERNING_PCT" ;;
    ex)
      h="$SEV_EX_HEALTHY"; m="$SEV_EX_MODERATE"; c="$SEV_EX_CONCERNING" ;;
    *) echo "N/A"; return ;;
  esac

  if awk "BEGIN{exit !($val <= $h)}" 2>/dev/null; then
    echo "HEALTHY"
  elif awk "BEGIN{exit !($val <= $m)}" 2>/dev/null; then
    echo "MODERATE"
  elif awk "BEGIN{exit !($val <= $c)}" 2>/dev/null; then
    echo "CONCERNING"
  else
    echo "CRITICAL"
  fi
}

# --- Helper: extract durations from JFR print output -------------------------
extract_durations() {
  local infile="$1"
  local outfile="$2"
  grep -A2 '^jdk\.' "$infile" | \
    awk '/duration =/ {
      val=$3; unit=$4
      if (unit=="ms") ms=val+0
      else if (unit=="s")  ms=val*1000
      else if (unit=="µs") ms=val/1000
      else if (unit=="ns") ms=val/1e6
      else ms=val+0
      print ms
    }' > "$outfile"
}

# --- Pre-compute all metrics -------------------------------------------------

# ThreadPark
PARK_COUNT=0; PARK_P95=0; PARK_P99=0; PARK_MAX=0; PARK_SEV="N/A"
if [ -s "$OUT_DIR/park.txt" ]; then
  PARK_COUNT=$(grep -c '^jdk\.ThreadPark' "$OUT_DIR/park.txt" || echo "0")
  extract_durations "$OUT_DIR/park.txt" "$OUT_DIR/park_durations.txt"
  if [ -s "$OUT_DIR/park_durations.txt" ]; then
    PARK_MAX=$(sort -n "$OUT_DIR/park_durations.txt" | tail -1)
    PARK_P95=$(sort -n "$OUT_DIR/park_durations.txt" | awk -v n="$PARK_COUNT" 'NR==int(n*0.95)+1{print; exit}')
    PARK_P99=$(sort -n "$OUT_DIR/park_durations.txt" | awk -v n="$PARK_COUNT" 'NR==int(n*0.99)+1{print; exit}')
    PARK_SEV=$(severity_of park "$PARK_P95")
  fi
fi

# SocketRead
READ_COUNT=0; READ_P95=0; READ_P99=0; READ_MAX=0; READ_SEV="N/A"
if [ -s "$OUT_DIR/io.txt" ]; then
  READ_COUNT=$(grep -c '^jdk\.SocketRead' "$OUT_DIR/io.txt" || echo "0")
  extract_durations "$OUT_DIR/io.txt" "$OUT_DIR/read_durations.txt"
  if [ -s "$OUT_DIR/read_durations.txt" ]; then
    READ_MAX=$(sort -n "$OUT_DIR/read_durations.txt" | tail -1)
    READ_P95=$(sort -n "$OUT_DIR/read_durations.txt" | awk -v n="$READ_COUNT" 'NR==int(n*0.95)+1{print; exit}')
    READ_P99=$(sort -n "$OUT_DIR/read_durations.txt" | awk -v n="$READ_COUNT" 'NR==int(n*0.99)+1{print; exit}')
    READ_SEV=$(severity_of io "$READ_P95")
  fi
fi

# ExecutionSample
CPU_COUNT=0
if [ -s "$OUT_DIR/cpu.txt" ]; then
  CPU_COUNT=$(grep -c '^jdk\.ExecutionSample' "$OUT_DIR/cpu.txt" || echo "0")
fi

# ObjectAllocation
ALLOC_COUNT=0
if [ -s "$OUT_DIR/alloc.txt" ]; then
  ALLOC_COUNT=$(grep -c '^jdk\.ObjectAllocationSample' "$OUT_DIR/alloc.txt" || echo "0")
fi

# GC Pause
GC_COUNT=0; GC_P95=0; GC_P99=0; GC_MAX=0; GC_TOTAL_MS=0; GC_SEV="N/A"
if [ -s "$OUT_DIR/gc.txt" ]; then
  GC_COUNT=$(grep -c '^jdk\.GCPhasePause' "$OUT_DIR/gc.txt" || echo "0")
  extract_durations "$OUT_DIR/gc.txt" "$OUT_DIR/gc_durations.txt"
  if [ -s "$OUT_DIR/gc_durations.txt" ]; then
    GC_MAX=$(sort -n "$OUT_DIR/gc_durations.txt" | tail -1)
    GC_P95=$(sort -n "$OUT_DIR/gc_durations.txt" | awk -v n="$GC_COUNT" 'NR==int(n*0.95)+1{print; exit}')
    GC_P99=$(sort -n "$OUT_DIR/gc_durations.txt" | awk -v n="$GC_COUNT" 'NR==int(n*0.99)+1{print; exit}')
    GC_TOTAL_MS=$(awk '{s+=$1} END{printf "%.1f", s}' "$OUT_DIR/gc_durations.txt")
    GC_SEV=$(severity_of gc "$GC_P99")
  fi
fi

# Lock contention
LOCK_COUNT=0; LOCK_P95=0; LOCK_MAX=0; LOCK_SEV="N/A"
if [ -s "$OUT_DIR/locks.txt" ]; then
  LOCK_COUNT=$(grep -c '^jdk\.JavaMonitorEnter' "$OUT_DIR/locks.txt" || echo "0")
  extract_durations "$OUT_DIR/locks.txt" "$OUT_DIR/lock_durations.txt"
  if [ -s "$OUT_DIR/lock_durations.txt" ]; then
    LOCK_MAX=$(sort -n "$OUT_DIR/lock_durations.txt" | tail -1)
    LOCK_P95=$(sort -n "$OUT_DIR/lock_durations.txt" | awk -v n="$LOCK_COUNT" 'NR==int(n*0.95)+1{print; exit}')
    LOCK_SEV=$(severity_of lock "$LOCK_P95")
  fi
fi

# Exceptions
EX_TOTAL=0; EX_SEV="N/A"
if [ -s "$OUT_DIR/exceptions.txt" ]; then
  EX_TOTAL=$(grep -c '^jdk\.JavaErrorThrow' "$OUT_DIR/exceptions.txt" || echo "0")
fi
if [ -s "$OUT_DIR/exceptions2.txt" ]; then
  EX2=$(grep -c '^jdk\.ExceptionThrow' "$OUT_DIR/exceptions2.txt" || echo "0")
  EX_TOTAL=$((EX_TOTAL + EX2))
fi
if [ "$EX_TOTAL" -gt 0 ] 2>/dev/null; then
  EX_SEV=$(severity_of ex "$EX_TOTAL")
fi

# CPU Load (machine-level)
CPU_LOAD_AVG="N/A"; CPU_LOAD_VAL=0; CPU_SEV="N/A"
if [ -s "$OUT_DIR/cpu_load.txt" ]; then
  CPU_LOAD_AVG=$(grep -A1 '^jdk\.CPULoad' "$OUT_DIR/cpu_load.txt" | \
    awk '/jvmUser =/ {u=$3} /jvmSystem =/ {s=$3} END{if(u!="" && s!="") printf "%.1f%%", (u+s)*100}')
  CPU_LOAD_VAL=$(grep -A1 '^jdk\.CPULoad' "$OUT_DIR/cpu_load.txt" | \
    awk '/jvmUser =/ {u=$3} /jvmSystem =/ {s=$3} END{if(u!="" && s!="") printf "%.1f", (u+s)*100}')
  if [ -n "$CPU_LOAD_VAL" ] && [ "$CPU_LOAD_VAL" != "0.0" ]; then
    CPU_SEV=$(severity_of cpu_load "$CPU_LOAD_VAL")
  fi
fi

# ============================================================================
# REPORT GENERATION
# ============================================================================

if [ "$NO_REPORT" -eq 1 ]; then
  echo "Evidence dumped to: $OUT_DIR"
  echo "Report generation skipped (--no-report)."
  exit 0
fi

{
echo "# JFR Hypothesis-Driven Diagnosis Report"
echo ""
echo "> **Principle:** This report does not deliver a single \"verdict.\""
echo "> It presents multiple competing hypotheses, rates confidence from evidence,"
echo "> and prescribes the next experiment to strengthen or falsify each one."
echo ""
echo "---"
echo ""

# ============================================================================
# 1. RECORDING METADATA
# ============================================================================
echo "## Recording Metadata"
echo ""
if [ -s "$OUT_DIR/summary.txt" ]; then
  cat "$OUT_DIR/summary.txt"
else
  echo "(summary unavailable)"
fi
echo ""
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| JFR File | \`$JFR_FILE\` |"
echo "| Analysis Output | \`$OUT_DIR\` |"
echo "| JVM+System CPU | ${CPU_LOAD_AVG} |"
echo ""

# ============================================================================
# 2. EVIDENCE SUMMARY (raw counts + percentiles + severity)
# ============================================================================
echo "## Evidence Summary"
echo ""
echo "| Event Type | Count | p50 | p95 | p99 | Max | Severity |"
echo "|------------|-------|-----|-----|-----|-----|----------|"
if [ -s "$OUT_DIR/park_durations.txt" ]; then
  n=$(wc -l < "$OUT_DIR/park_durations.txt")
  if [ "$n" -gt 0 ]; then
    p50=$(sort -n "$OUT_DIR/park_durations.txt" | awk -v n="$n" 'NR==int(n*0.50)+1{print; exit}')
    p95=$(sort -n "$OUT_DIR/park_durations.txt" | awk -v n="$n" 'NR==int(n*0.95)+1{print; exit}')
    p99=$(sort -n "$OUT_DIR/park_durations.txt" | awk -v n="$n" 'NR==int(n*0.99)+1{print; exit}')
    max=$(sort -n "$OUT_DIR/park_durations.txt" | tail -1)
    printf "| %-20s | %6s | %10s | %10s | %10s | %10s | %-10s |\n" "ThreadPark" "$n" "${p50}ms" "${p95}ms" "${p99}ms" "${max}ms" "$PARK_SEV"
  fi
fi

if [ -s "$OUT_DIR/read_durations.txt" ]; then
  n=$(wc -l < "$OUT_DIR/read_durations.txt")
  if [ "$n" -gt 0 ]; then
    p50=$(sort -n "$OUT_DIR/read_durations.txt" | awk -v n="$n" 'NR==int(n*0.50)+1{print; exit}')
    p95=$(sort -n "$OUT_DIR/read_durations.txt" | awk -v n="$n" 'NR==int(n*0.95)+1{print; exit}')
    p99=$(sort -n "$OUT_DIR/read_durations.txt" | awk -v n="$n" 'NR==int(n*0.99)+1{print; exit}')
    max=$(sort -n "$OUT_DIR/read_durations.txt" | tail -1)
    printf "| %-20s | %6s | %10s | %10s | %10s | %10s | %-10s |\n" "SocketRead" "$n" "${p50}ms" "${p95}ms" "${p99}ms" "${max}ms" "$READ_SEV"
  fi
fi

if [ -s "$OUT_DIR/lock_durations.txt" ]; then
  n=$(wc -l < "$OUT_DIR/lock_durations.txt")
  if [ "$n" -gt 0 ]; then
    p50=$(sort -n "$OUT_DIR/lock_durations.txt" | awk -v n="$n" 'NR==int(n*0.50)+1{print; exit}')
    p95=$(sort -n "$OUT_DIR/lock_durations.txt" | awk -v n="$n" 'NR==int(n*0.95)+1{print; exit}')
    p99=$(sort -n "$OUT_DIR/lock_durations.txt" | awk -v n="$n" 'NR==int(n*0.99)+1{print; exit}')
    max=$(sort -n "$OUT_DIR/lock_durations.txt" | tail -1)
    printf "| %-20s | %6s | %10s | %10s | %10s | %10s | %-10s |\n" "JavaMonitorEnter" "$n" "${p50}ms" "${p95}ms" "${p99}ms" "${max}ms" "$LOCK_SEV"
  fi
fi

if [ -s "$OUT_DIR/gc_durations.txt" ]; then
  n=$(wc -l < "$OUT_DIR/gc_durations.txt")
  if [ "$n" -gt 0 ]; then
    p50=$(sort -n "$OUT_DIR/gc_durations.txt" | awk -v n="$n" 'NR==int(n*0.50)+1{print; exit}')
    p95=$(sort -n "$OUT_DIR/gc_durations.txt" | awk -v n="$n" 'NR==int(n*0.95)+1{print; exit}')
    p99=$(sort -n "$OUT_DIR/gc_durations.txt" | awk -v n="$n" 'NR==int(n*0.99)+1{print; exit}')
    max=$(sort -n "$OUT_DIR/gc_durations.txt" | tail -1)
    printf "| %-20s | %6s | %10s | %10s | %10s | %10s | %-10s |\n" "GC Pause" "$n" "${p50}ms" "${p95}ms" "${p99}ms" "${max}ms" "$GC_SEV"
  fi
fi
echo ""

# Allocation / CPU / Exceptions (no duration, but show severity where applicable)
echo "| Event Type | Count | Note | Severity |"
echo "|------------|-------|------|----------|"
printf "| %-20s | %6s | %-46s | %-10s |\n" "ExecutionSample" "$CPU_COUNT" "CPU execution samples (not ms)" "$CPU_SEV"
printf "| %-20s | %6s | %-46s | %-10s |\n" "ObjectAllocation" "$ALLOC_COUNT" "Allocation samples (not ms)" "N/A"
printf "| %-20s | %6s | %-46s | %-10s |\n" "Exception/Error" "$EX_TOTAL" "Total exception events" "$EX_SEV"
echo ""

# ============================================================================
# 3. HYPOTHESES
# ============================================================================
echo "## Hypotheses"
echo ""
echo "| Confidence | Meaning |"
echo "|------------|---------|"
echo "| HIGH | Evidence strongly supports; next step is optimization + measurement |"
echo "| MEDIUM | Evidence suggests; next step is targeted experiment to confirm |"
echo "| LOW | Evidence weak or indirect; next step is collect missing metrics |"
echo "| NOT PROVEN | No supporting evidence in this recording |"
echo ""
echo "*Thresholds used (override via env vars):*"
echo "- IO count > ${THRESH_IO_COUNT}, p95 > ${THRESH_IO_P95_MS}ms"
echo "- Park count > ${THRESH_PARK_COUNT}, CPU count < ${THRESH_CPU_COUNT}"
echo "- Lock count > ${THRESH_LOCK_COUNT}, p95 > ${THRESH_LOCK_P95_MS}ms"
echo "- Alloc count > ${THRESH_ALLOC_COUNT}"
echo "- GC p99 < ${THRESH_GC_P99_MS}ms (for 'not a bottleneck')"
echo ""

# --- H1: I/O Bottleneck ------------------------------------------------------
echo "### [H1] External I/O (network/DB) may be limiting throughput"
echo ""

IO_CONFIDENCE="NOT PROVEN"
if [ "$READ_COUNT" -gt "$THRESH_IO_COUNT" ] 2>/dev/null; then
  if awk "BEGIN{exit !($READ_P95 > $THRESH_IO_P95_MS)}" 2>/dev/null; then
    IO_CONFIDENCE="MEDIUM"
  else
    IO_CONFIDENCE="LOW"
  fi
fi

echo "**Confidence:** $IO_CONFIDENCE"
echo ""
echo "**Severity:** $READ_SEV (SocketRead p95 = ${READ_P95}ms)"
echo ""
echo "**Evidence:**"
echo "- SocketRead events: $READ_COUNT"
echo "- SocketRead p95: ${READ_P95}ms, p99: ${READ_P99}ms, max: ${READ_MAX}ms"
if [ -s "$OUT_DIR/io.txt" ]; then
  echo "- Top destinations:"
  awk '/host =/ {
    match($0, /"([^"]+)"/, m); h=m[1]
  } /port =/ {
    p=$3
    if(h!="" && p!="") { dest=h":"p; count[dest]++ }
  } END {
    for(d in count) printf "  - %s: %d events\n", d, count[d]
  }' "$OUT_DIR/io.txt" | sort -t: -k2 -rn | head -5
fi
echo ""
echo "**Interpretation:**"
if [ "$IO_CONFIDENCE" = "MEDIUM" ]; then
  echo "Socket reads are frequent and slow under load. This is consistent with an"
  echo "external I/O bottleneck (database, cache, or downstream service), but it"
  echo "could also be network latency, large payloads, or inefficient queries."
else
  echo "Socket reads are either infrequent or fast. External I/O is not strongly"
  echo "implicated in this recording."
fi
echo ""
echo "**Next experiment:**"
echo "1. Measure query / downstream call latency from application metrics."
echo "2. Compare throughput with a stubbed/cached response path."
echo "3. Check for N+1 calls, missing indexes, or oversized payloads."
echo ""

# --- H2: Thread Parking / Blocking -------------------------------------------
echo "### [H2] Blocking wait patterns may limit concurrency"
echo ""

PARK_CONFIDENCE="NOT PROVEN"
if [ "$PARK_COUNT" -gt "$THRESH_PARK_COUNT" ] 2>/dev/null; then
  if [ "$CPU_COUNT" -lt "$THRESH_CPU_COUNT" ] 2>/dev/null; then
    PARK_CONFIDENCE="MEDIUM"
  else
    PARK_CONFIDENCE="LOW"
  fi
fi

echo "**Confidence:** $PARK_CONFIDENCE"
echo ""
echo "**Severity:** $PARK_SEV (ThreadPark p95 = ${PARK_P95}ms)"
echo ""
echo "**Evidence:**"
echo "- ThreadPark events: $PARK_COUNT"
echo "- ThreadPark p95: ${PARK_P95}ms, p99: ${PARK_P99}ms, max: ${PARK_MAX}ms"
echo "- ExecutionSample events: $CPU_COUNT (low CPU work suggests threads wait more than compute)"
if [ -s "$OUT_DIR/park.txt" ]; then
  TOP_PARK_CLASS=$(awk '/parkedClass =/ {
    cls=$0; gsub(/.*parkedClass = /, "", cls); gsub(/ \(.*\)/, "", cls)
    print cls
  }' "$OUT_DIR/park.txt" | sort | uniq -c | sort -rn | head -1 | awk '{$1=""; print $0}' | xargs)
  echo "- Most parked class: ${TOP_PARK_CLASS:-(unknown)}"
fi
echo ""
echo "**Interpretation:**"
if [ "$PARK_CONFIDENCE" = "MEDIUM" ]; then
  echo "Threads park frequently while CPU samples are low. This is consistent with a"
  echo "blocking I/O or synchronization model where worker threads spend most of their"
  echo "lifecycle waiting. However, ThreadPark alone does NOT prove thread starvation"
  echo "— it could be normal pool behavior under moderate load."
else
  echo "Thread parking is not dominant in this recording. The blocking wait model is"
  echo "not strongly implicated as the primary bottleneck."
fi
echo ""
echo "**Next experiment:**"
echo "1. Capture active/max thread counts and request queue depth during load."
echo "2. Vary thread pool sizes and measure throughput + tail latency."
echo "3. If using a blocking stack, compare against a non-blocking alternative ONLY"
echo "   after confirming the wait cause (e.g., blocking I/O driver + reactive framework"
echo "   is NOT a valid experiment — it tests the framework, not non-blocking I/O)."
echo ""

# --- H3: GC is NOT a primary bottleneck --------------------------------------
echo "### [H3] GC is NOT currently a primary bottleneck"
echo ""

GC_CONFIDENCE="NOT PROVEN"
if [ "$GC_COUNT" -eq 0 ]; then
  GC_CONFIDENCE="HIGH"
elif awk "BEGIN{exit !($GC_P99 < $THRESH_GC_P99_MS)}" 2>/dev/null; then
  GC_CONFIDENCE="HIGH"
else
  GC_CONFIDENCE="MEDIUM"
fi

echo "**Confidence:** $GC_CONFIDENCE"
echo ""
echo "**Severity:** $GC_SEV (GC Pause p99 = ${GC_P99}ms)"
echo ""
echo "**Evidence:**"
echo "- GC Pause events: $GC_COUNT"
echo "- GC Pause p95: ${GC_P95}ms, p99: ${GC_P99}ms, max: ${GC_MAX}ms"
echo "- Total GC pause time: ${GC_TOTAL_MS}ms"
echo ""
echo "**Interpretation:**"
if [ "$GC_CONFIDENCE" = "HIGH" ]; then
  if [ "$GC_COUNT" -eq 0 ]; then
    echo "No GC pauses recorded. GC is clearly not the issue."
  else
    echo "GC pauses are short and infrequent. GC is unlikely to be the dominant bottleneck."
  fi
else
  echo "GC pauses are elevated. This may contribute to tail latency and should be monitored."
fi
echo ""
echo "**Next experiment:**"
echo "- If allocation rate is high (>${THRESH_ALLOC_COUNT} samples), monitor GC overhead % during longer runs."
echo "- Otherwise: no GC experiment needed until higher confidence in H1/H2."
echo ""

# --- H4: CPU is NOT proven to be the bottleneck ------------------------------
echo "### [H4] CPU is NOT proven to be the bottleneck"
echo ""

CPU_CONFIDENCE="LOW (not proven)"
if [ "$CPU_COUNT" -gt "$THRESH_CPU_COUNT" ] 2>/dev/null; then
  CPU_CONFIDENCE="MEDIUM (contradicting)"
fi

echo "**Confidence:** $CPU_CONFIDENCE"
echo ""
echo "**Severity:** $CPU_SEV (JVM+System CPU = ${CPU_LOAD_AVG})"
echo ""
echo "**Evidence:**"
echo "- ExecutionSample events: $CPU_COUNT"
echo "- JVM+System CPU load: ${CPU_LOAD_AVG}"
if [ -s "$OUT_DIR/cpu.txt" ]; then
  TOP_CPU_METHOD=$(awk '
  /^jdk\.ExecutionSample/ { trace=0; next }
  /stackTrace = \[/ { trace=1; next }
  trace && /^\s+\]/ { trace=0; next }
  trace {
    gsub(/^[[:space:]]+/, "", $0)
    sub(/\(.*/, "", $0)
    print
  }
  ' "$OUT_DIR/cpu.txt" | sort | uniq -c | sort -rn | head -1 | awk '{$1=""; print $0}' | xargs)
  echo "- Hottest method: ${TOP_CPU_METHOD:-(unknown)}"
fi
echo ""
echo "**Interpretation:**"
if [ "$CPU_COUNT" -gt "$THRESH_CPU_COUNT" ] 2>/dev/null; then
  echo "Execution samples are high. The JVM is actively computing."
  echo "However, this does NOT automatically mean \"CPU-bound\" — it could be busy-wait,"
  echo "inefficient serialization, or simply a high-throughput healthy state."
  echo "You need CPU % (process and system) to confirm saturation."
else
  echo "Execution samples are relatively low. The JVM is not spending most of its time"
  echo "on-CPU. This is consistent with an I/O-waiting or thread-parked state."
fi
echo ""
echo "**Next experiment:**"
echo "1. Correlate ExecutionSample count with OS-level CPU % (already in JFR via CPULoad)."
echo "2. If CPU % is high and ExecutionSample is high -> profile hot methods (already done above)."
echo "3. If CPU % is low and ExecutionSample is low -> bottleneck is elsewhere (H1 or H2)."
echo ""

# --- H5: Lock Contention -----------------------------------------------------
echo "### [H5] Lock contention may be causing serial execution"
echo ""

LOCK_CONFIDENCE="NOT PROVEN"
if [ "$LOCK_COUNT" -gt "$THRESH_LOCK_COUNT" ] 2>/dev/null; then
  if awk "BEGIN{exit !($LOCK_P95 > $THRESH_LOCK_P95_MS)}" 2>/dev/null; then
    LOCK_CONFIDENCE="MEDIUM"
  else
    LOCK_CONFIDENCE="LOW"
  fi
fi

echo "**Confidence:** $LOCK_CONFIDENCE"
echo ""
echo "**Severity:** $LOCK_SEV (JavaMonitorEnter p95 = ${LOCK_P95}ms)"
echo ""
echo "**Evidence:**"
echo "- JavaMonitorEnter events: $LOCK_COUNT"
echo "- Monitor wait p95: ${LOCK_P95}ms, max: ${LOCK_MAX}ms"
if [ -s "$OUT_DIR/locks.txt" ]; then
  echo "- Most contended monitors:"
  awk '/monitorClass =/ {
    cls=$0; gsub(/.*monitorClass = /, "", cls); gsub(/ \(.*\)/, "", cls)
    print cls
  }' "$OUT_DIR/locks.txt" | sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  - %s: %s events\n", $2, $1}'
fi
echo ""
echo "**Interpretation:**"
if [ "$LOCK_CONFIDENCE" = "MEDIUM" ]; then
  echo "Monitor entry waits are frequent and slow. Some code paths may be serializing"
  echo "concurrent requests unnecessarily."
else
  echo "Lock contention is not dominant in this recording."
fi
echo ""
echo "**Next experiment:**"
echo "1. Identify which business methods acquire the contended monitors."
echo "2. Replace synchronized blocks with java.util.concurrent primitives if possible."
echo "3. Measure throughput before/after."
echo ""

# --- H6: Allocation Pressure -------------------------------------------------
echo "### [H6] Allocation pressure may be causing GC churn"
echo ""

ALLOC_CONFIDENCE="NOT PROVEN"
if [ "$ALLOC_COUNT" -gt "$THRESH_ALLOC_COUNT" ] 2>/dev/null; then
  ALLOC_CONFIDENCE="MEDIUM"
else
  ALLOC_CONFIDENCE="LOW"
fi

echo "**Confidence:** $ALLOC_CONFIDENCE"
echo ""
echo "**Evidence:**"
echo "- ObjectAllocationSample events: $ALLOC_COUNT"
if [ -s "$OUT_DIR/alloc.txt" ]; then
  echo "- Top allocating classes:"
  awk '/objectClass =/ {
    cls=$0; gsub(/.*objectClass = /, "", cls); gsub(/ \(.*\)/, "", cls)
    print cls
  }' "$OUT_DIR/alloc.txt" | sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  - %s: %s samples\n", $2, $1}'
fi
echo ""
echo "**Interpretation:**"
if [ "$ALLOC_CONFIDENCE" = "MEDIUM" ]; then
  echo "High allocation rate detected. This often correlates with GC pressure,"
  echo "especially if temporary objects dominate (JSON parsing, DTO mapping, String concat)."
else
  echo "Allocation rate is moderate. Not a primary concern unless GC pauses grow."
fi
echo ""
echo "**Next experiment:**"
echo "1. Profile allocation rate vs GC pause frequency over a longer run."
echo "2. If correlated, reduce allocations (object pooling, reuse buffers, avoid autoboxing)."
echo ""

# --- H7: Exception Storm -----------------------------------------------------
echo "### [H7] Exception rate may indicate errors or control-flow abuse"
echo ""

EX_CONFIDENCE="NOT PROVEN"
if [ "$EX_TOTAL" -gt "$THRESH_EX_COUNT" ] 2>/dev/null; then
  EX_CONFIDENCE="MEDIUM"
else
  EX_CONFIDENCE="LOW"
fi

echo "**Confidence:** $EX_CONFIDENCE"
echo ""
echo "**Severity:** $EX_SEV (total exceptions = $EX_TOTAL)"
echo ""
echo "**Evidence:**"
echo "- Exception/Error events: $EX_TOTAL"
if [ -s "$OUT_DIR/exceptions.txt" ]; then
  echo "- Top thrown types (errors):"
  awk '/thrownClass =/ {
    cls=$0; gsub(/.*thrownClass = /, "", cls); gsub(/ \(.*\)/, "", cls)
    print cls
  }' "$OUT_DIR/exceptions.txt" | sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  - %s: %s events\n", $2, $1}'
fi
if [ -s "$OUT_DIR/exceptions2.txt" ]; then
  echo "- Top thrown types (exceptions):"
  awk '/thrownClass =/ {
    cls=$0; gsub(/.*thrownClass = /, "", cls); gsub(/ \(.*\)/, "", cls)
    print cls
  }' "$OUT_DIR/exceptions2.txt" | sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "  - %s: %s events\n", $2, $1}'
fi
echo ""
echo "**Interpretation:**"
if [ "$EX_CONFIDENCE" = "MEDIUM" ]; then
  echo "High exception rate detected. Exceptions are expensive in Java (stack trace"
  echo "capture, unwinding). If used for control flow, this is a known anti-pattern."
else
  echo "Exception rate is low. Not a primary concern."
fi
echo ""
echo "**Next experiment:**"
echo "1. Check logs for repeated error patterns at the times of the recording."
echo "2. If control-flow exceptions (e.g., FlowControlException), refactor to return codes."
echo "3. Measure throughput before/after."
echo ""

# ============================================================================
# 4. HOTSPOTS (for reference — not conclusions)
# ============================================================================
echo "## Hotspot Detail"
echo ""
echo "> These are the raw hotspots. Use them to support or refute hypotheses above,"
echo "> not to declare a verdict."
echo ""

# CPU hotspots
if [ -s "$OUT_DIR/cpu.txt" ]; then
  echo "### Top Methods by ExecutionSample"
  echo ""
  echo "| Samples | Method |"
  echo "|--------:|--------|"
  awk '
  /^jdk\.ExecutionSample/ { trace=0; next }
  /stackTrace = \[/ { trace=1; next }
  trace && /^\s+\]/ { trace=0; next }
  trace {
    gsub(/^[[:space:]]+/, "", $0)
    sub(/\(.*/, "", $0)
    print
  }
  ' "$OUT_DIR/cpu.txt" | \
    sort | uniq -c | sort -rn | head -15 | \
    awk '{printf "| %7s | %s |\n", $1, $2}'
  echo ""
fi

# ThreadPark hotspots
if [ -s "$OUT_DIR/park.txt" ]; then
  echo "### Longest ThreadParks with Business Frame"
  echo ""
  echo "| Duration | Thread | First Business Frame |"
  echo "|---------:|--------|---------------------|"
  awk '
  /^jdk\.ThreadPark/ { inside=1; ms=0; thread=""; stk=""; collecting=0; next }
  inside && /duration =/ {
    val=$3; unit=$4
    if (unit=="ms") ms=val+0
    else if (unit=="s")  ms=val*1000
    else if (unit=="µs") ms=val/1000
    else if (unit=="ns") ms=val/1e6
  }
  inside && /eventThread =/ {
    match($0, /"([^"]+)"/, m)
    thread=m[1]
  }
  inside && /stackTrace = \[/ { collecting=1; next }
  inside && collecting && /^\s+\]/ { collecting=0; inside=0; print ms "|" thread "|" stk; next }
  inside && collecting {
    gsub(/^[[:space:]]+/, "", $0)
    if (stk=="") stk=$0; else stk=stk";"$0
  }
  ' "$OUT_DIR/park.txt" | \
    sort -t'|' -k1 -rn > "$OUT_DIR/park_sorted.txt"

  awk -F'|' '
  NR<=10 {
    best=""
    n=split($3, frames, ";")
    for(i=1;i<=n;i++) {
      f=frames[i]
      if (f == "...") continue
      if (f ~ /^java\./ || f ~ /^jdk\./ || f ~ /^sun\./ || f ~ /^javax\./) continue
      best=f; break
    }
    if (best=="") {
      for(i=n;i>=1;i--) {
        f=frames[i]
        if (f != "...") { best=f; break }
      }
    }
    if (best=="") best="(no stack)"
    sub(/\(.*/, "", best)
    printf "| %8.2f ms | %s | %s |\n", $1, $2, best
  }
  ' "$OUT_DIR/park_sorted.txt"
  echo ""
fi

# ============================================================================
# 5. MEASUREMENT REFERENCE
# ============================================================================
echo "## Measurement Reference"
echo ""
echo "> Default severity thresholds. Override any via environment variables."
echo "> Example: \`SEV_IO_CONCERNING_MS=30 jfr-diagnose.sh recording.jfr\`"
echo ""

echo "### ThreadPark (blocking wait)"
echo ""
echo "| Severity | p95 Threshold | What it means |"
echo "|----------|---------------|---------------|"
echo "| HEALTHY    | <= ${SEV_PARK_HEALTHY_MS} ms    | Normal parking (LockSupport, brief pool waits) |"
echo "| MODERATE   | <= ${SEV_PARK_MODERATE_MS} ms   | Some blocking; may be connection pool or mild I/O wait |"
echo "| CONCERNING | <= ${SEV_PARK_CONCERNING_MS} ms | Threads stuck waiting; likely I/O or lock bottleneck |"
echo "| CRITICAL   | > ${SEV_PARK_CONCERNING_MS} ms  | Severe blocking; check thread dumps and pool sizing |"
echo ""

echo "### SocketRead (network / DB I/O)"
echo ""
echo "| Severity | p95 Threshold | What it means |"
echo "|----------|---------------|---------------|"
echo "| HEALTHY    | <= ${SEV_IO_HEALTHY_MS} ms    | Fast local network or in-memory store |"
echo "| MODERATE   | <= ${SEV_IO_MODERATE_MS} ms   | Acceptable for remote calls |"
echo "| CONCERNING | <= ${SEV_IO_CONCERNING_MS} ms | Slow queries, large payloads, or network latency |"
echo "| CRITICAL   | > ${SEV_IO_CONCERNING_MS} ms  | DB bottleneck, N+1 queries, or downstream failure |"
echo ""

echo "### JavaMonitorEnter (lock contention)"
echo ""
echo "| Severity | p95 Threshold | What it means |"
echo "|----------|---------------|---------------|"
echo "| HEALTHY    | <= ${SEV_LOCK_HEALTHY_MS} ms    | Light synchronization, normal concurrency |"
echo "| MODERATE   | <= ${SEV_LOCK_MODERATE_MS} ms   | Some contention; review synchronized blocks |"
echo "| CONCERNING | <= ${SEV_LOCK_CONCERNING_MS} ms | Serializing execution; consider j.u.c locks |"
echo "| CRITICAL   | > ${SEV_LOCK_CONCERNING_MS} ms  | Severe contention; likely throughput killer |"
echo ""

echo "### GC Pause"
echo ""
echo "| Severity | p99 Threshold | What it means |"
echo "|----------|---------------|---------------|"
echo "| HEALTHY    | <= ${SEV_GC_HEALTHY_MS} ms    | Modern GC (G1/ZGC/Shenandoah) doing its job |"
echo "| MODERATE   | <= ${SEV_GC_MODERATE_MS} ms   | Tunable; monitor allocation rate |"
echo "| CONCERNING | <= ${SEV_GC_CONCERNING_MS} ms | Tail latency impact; review heap size / GC algo |"
echo "| CRITICAL   | > ${SEV_GC_CONCERNING_MS} ms  | Stop-the-world dominates; urgent tuning needed |"
echo ""

echo "### CPU Load (JVM User + System)"
echo ""
echo "| Severity | Threshold | What it means |"
echo "|----------|-----------|---------------|"
echo "| HEALTHY    | < ${SEV_CPU_HEALTHY_PCT}%       | Plenty of headroom |"
echo "| MODERATE   | < ${SEV_CPU_MODERATE_PCT}%      | Approaching saturation |"
echo "| CONCERNING | < ${SEV_CPU_CONCERNING_PCT}%    | Near saturation; scaling may help |"
echo "| CRITICAL   | >= ${SEV_CPU_CONCERNING_PCT}%   | CPU-bound; profile hot methods |"
echo ""

echo "### Exception Rate"
echo ""
echo "| Severity | Total Count | What it means |"
echo "|----------|-------------|---------------|"
echo "| HEALTHY    | <= ${SEV_EX_HEALTHY}     | Normal operational noise |"
echo "| MODERATE   | <= ${SEV_EX_MODERATE}    | Elevated; check for repeated patterns |"
echo "| CONCERNING | <= ${SEV_EX_CONCERNING}  | Likely control-flow abuse or real errors |"
echo "| CRITICAL   | > ${SEV_EX_CONCERNING}   | Exception storm; massive overhead |"
echo ""

echo "### Notes on Interpreting Counts"
echo ""
echo "- **ExecutionSample count** depends on recording duration and sampling rate."
echo "  Correlate with CPU load % rather than judging the raw number alone."
echo "- **ObjectAllocationSample count** also depends on duration. Look at the"
echo "  ratio to GC events: high alloc + high GC = pressure; high alloc + low GC = fine."
echo "- **SocketWrite** is not severity-graded because write latency is usually"
echo "  buffered; focus on **SocketRead** for I/O bottlenecks."
echo ""

# ============================================================================
# 6. EXPERIMENT TRACKER
# ============================================================================
echo "## Experiment Tracker"
echo ""
echo "> Copy this table into a new file and fill it in as you run each experiment."
echo "> Never change two variables at once."
echo ""
echo "### Experiment Template"
echo ""
echo '\`\`\`markdown'
echo "### Experiment: [describe change]"
echo ""
echo "| Metric | Baseline | This Run | Delta |"
echo "|--------|----------|----------|-------|"
echo "| RPS (req/s) | ? | ? | ? |"
echo "| p50 latency (ms) | ? | ? | ? |"
echo "| p95 latency (ms) | ? | ? | ? |"
echo "| p99 latency (ms) | ? | ? | ? |"
echo "| max latency (ms) | ? | ? | ? |"
echo "| CPU % | ? | ? | ? |"
echo "| GC overhead % | ? | ? | ? |"
echo "| alloc/sec | ? | ? | ? |"
echo "| active threads | ? | ? | ? |"
echo "| external call p95 (ms) | ? | ? | ? |"
echo "| errors | ? | ? | ? |"
echo ""
echo "**Hypothesis tested:** [H1 | H2 | H3 | ...]"
echo ""
echo "**Conclusion:**"
echo "- Did the data strengthen or weaken the hypothesis?"
echo "- What is the next experiment?"
echo '\`\`\`'
echo ""

# --- Suggested experiment order ----------------------------------------------
echo "### Suggested Experiment Order"
echo ""
echo "1. **Baseline confirmation** — run the same load test 3x and verify RPS variance is <5%."
echo "   This is your control. If variance is high, your test harness is the bottleneck."
echo ""
echo "2. **Experiment A — Stub external I/O** (tests H1):"
echo "   - Setup: same app, but stub/cache the external call (DB, cache, HTTP client)."
echo "   - Expected if H1 is true: large throughput gain, lower SocketRead p95."
echo "   - If no gain: external I/O is not the bottleneck -> look at H2 or H5."
echo ""
echo "3. **Experiment B — Scale concurrency** (tests H2):"
echo "   - Setup: increase thread pool / connection pool / event-loop count."
echo "   - Expected if H2 is true: throughput rises with concurrency until saturation."
echo "   - If flat: blocking wait model is not the bottleneck -> look at H1 or H4."
echo ""
echo "4. **Experiment C — Reduce allocations** (tests H6):"
echo "   - Setup: target the top allocating classes from the hotspot list above."
echo "   - Expected if H6 is true: lower GC overhead, better tail latency."
echo ""
echo "> **Rule:** Change one variable per experiment. Otherwise you cannot attribute wins."
echo ""

# ============================================================================
# 7. RAW EVIDENCE INDEX
# ============================================================================
echo "## Raw Evidence Files"
echo ""
echo "| File | Description |"
echo "|------|-------------|"
echo "| \`$OUT_DIR/cpu.txt\` | ExecutionSample stack traces |"
echo "| \`$OUT_DIR/alloc.txt\` | ObjectAllocationSample events |"
echo "| \`$OUT_DIR/io.txt\` | SocketRead events |"
echo "| \`$OUT_DIR/io_write.txt\` | SocketWrite events |"
echo "| \`$OUT_DIR/park.txt\` | ThreadPark events |"
echo "| \`$OUT_DIR/locks.txt\` | JavaMonitorEnter events |"
echo "| \`$OUT_DIR/gc.txt\` | GCPhasePause events |"
echo "| \`$OUT_DIR/exceptions.txt\` | JavaErrorThrow events |"
echo "| \`$OUT_DIR/exceptions2.txt\` | ExceptionThrow events |"
echo "| \`$OUT_DIR/cpu_load.txt\` | CPULoad events |"
echo "| \`$OUT_DIR/io_write.txt\` | SocketWrite events (manual inspection) |"
echo "| \`$OUT_DIR/jvm_info.txt\` | JVMInformation events |"
echo "| \`$OUT_DIR/os_info.txt\` | OSInformation events |"
echo "| \`$OUT_DIR/cpu_info.txt\` | CPUInformation events |"
echo ""

echo "---"
echo "Report complete. Full report saved to: \`$REPORT_FILE\`"
} | tee "$REPORT_FILE"
