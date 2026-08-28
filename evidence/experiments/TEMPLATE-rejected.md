# REJECTED: H[N] — [Hypothesis Name]

> **Branch:** `experiment/h[N]-[short-name]`
> **Status:** REJECTED
> **Date:** YYYY-MM-DD

---

## Hypothesis

[What you believed the bottleneck was, based on JFR evidence. Be specific.]

Example:
> "JFR shows high ObjectAllocationSample count (45,000). I hypothesize reducing JSON serialization allocations with a faster mapper (Jackson Afterburner) will reduce GC pressure and improve throughput."

---

## Evidence Before Change

[JFR screenshot reference or pasted data. Point to the exact event.]

| Metric | Value | Severity |
|--------|-------|----------|
| ObjectAllocationSample | [X] | MODERATE |
| GC Pause p99 | [X]ms | HEALTHY |
| RPS | [X] req/s | — |
| p95 Latency | [X]ms | — |

**Key JFR signal:**
```
[paste relevant flame graph or event dump here]
```

---

## Change Implemented

[One sentence. One change. No "and".]

```diff
# or: code snippet showing the exact change
```

---

## Evidence After Change

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| RPS | [X] | [Y] | +[Z]% |
| p95 Latency | [X]ms | [Y]ms | -[Z]% |
| ObjectAllocationSample | [X] | [Y] | -[Z]% |
| GC Pause p99 | [X]ms | [Y]ms | — |
| Errors | [X]% | [Y]% | — |

**JFR diagnosis report:**
- File: `evidence/experiment/h[N]-[name]/diagnosis-report-h[N].md`
- Key finding: [one sentence]

---

## Why Rejected

[The measured delta does NOT justify the change. Be specific with numbers. Explain what you learned.]

Example:
> "RPS improved only 4% (1024 → 1065 req/s), within run-to-run variance. p95 latency unchanged. GC pauses were already HEALTHY (p99=12ms), so allocation reduction had no observable effect on throughput. The real bottleneck was elsewhere (ThreadPark, confirmed by H2 experiment). This taught me: do not optimize allocation rate when GC is not the bottleneck."

---

## Lesson Learned

[The insight you take forward. This is what judges want to see.]

Example:
> "Allocation rate is a secondary metric. If GC pauses are healthy, reducing allocations is premature optimization. Always check GC p99 before tuning serializers."
