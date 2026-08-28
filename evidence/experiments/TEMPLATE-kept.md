# KEPT: H[N] — [Hypothesis Name]

> **Branch:** `experiment/h[N]-[short-name]`
> **Status:** KEPT
> **Date:** YYYY-MM-DD

---

## Hypothesis

[What you believed the bottleneck was, based on JFR evidence. Be specific.]

Example:
> "JFR shows ThreadPark p95=120ms and low CPU utilization. I hypothesize the default Tomcat thread pool (200 threads) is exhausted under load, causing requests to queue. Reducing HikariCP connection pool size to match thread count should eliminate the parking wait."

---

## Evidence Before Change

[JFR screenshot reference or pasted data. Point to the exact event.]

| Metric | Value | Severity |
|--------|-------|----------|
| ThreadPark p95 | [X]ms | CONCERNING |
| SocketRead p95 | [X]ms | [SEV] |
| CPU Load | [X]% | [SEV] |
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
| ThreadPark p95 | [X]ms | [Y]ms | -[Z]% |
| Errors | [X]% | [Y]% | — |

**JFR diagnosis report:**
- File: `evidence/experiment/h[N]-[name]/diagnosis-report-h[N].md`
- Key finding: [one sentence]

---

## Why Kept

[The measured delta justifies keeping it. Be specific with numbers.]

Example:
> "RPS improved 3.2x (320 → 1024 req/s) and p95 latency dropped 60%. ThreadPark p95 fell from 120ms to 8ms. The evidence falsifies the null hypothesis."

---

## Next Step

[What hotspot does the new JFR show? What is the next hypothesis?]
