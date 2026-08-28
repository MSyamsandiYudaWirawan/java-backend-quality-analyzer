# Improvement Changelog

## Structure

This document tracks every meaningful iteration. The judges want to see **how you think**, not just what you built.

**Only two final solutions exist:**
- **Baseline** — simplest thing that passes tests (`baseline` branch)
- **Advanced** — incorporates optimizations that **survived measurement** (`advanced` branch)

Everything else is an experiment: kept or rejected. Rejected experiments are required by the rubric ("one experiment you removed").

**Each iteration lives on its own Git branch.** This lets judges (and you) check out any exact state and reproduce the measurement.

```
git log --oneline --all

a1b2c3d  (advanced) Final advanced: [description]
e4f5g6h  (experiment/h[N]) [Description] — KEPT (partial)
i7j8k9l  (experiment/h[N]) [Description] — KEPT
m0n1o2p  (experiment/h[N]) [Description] — REJECTED
q3r4s5t  (experiment/h[N]) [Description] — REJECTED
u6v7w8x  (baseline) Baseline: [tech stack]
```

**Reproducing any iteration:**
```bash
git checkout experiment/[name]
cd service && ./mvnw clean package
# Run k6 load test per REPRODUCTION.md
```

---

## Iteration Log

| # | Branch | Change | Evidence | Result | Status |
|---|--------|--------|----------|--------|--------|
| 1 | `baseline` | [Tech stack and scope] | [Benchmark config] | [RPS], [p95], [errors] | BASELINE |
| 2 | `experiment/h1-[name]` | [What changed] | [Evidence type] | [Measured result] | **REJECTED** |
| 3 | `experiment/h2-[name]` | [What changed] | [Evidence type] | [Measured result] | **KEPT** |
| 4 | `experiment/h3-[name]` | [What changed] | [Evidence type] | [Measured result] | **KEPT** |
| 5 | `advanced` | [Final stack] | [Evidence type] | [Final numbers] | ADVANCED |

---

## Experiment Details

### REJECTED: H1 — [Hypothesis Name]
- **Hypothesis:** [What you thought would improve.]
- **Evidence:** [What JFR/JMH/k6 showed before the change.]
- **Result:** [What actually happened after the change, with numbers.]
- **Why rejected:** [Why the numbers didn't justify keeping it.]
- **Full report:** [`evidence/experiments/h1-[name].md`](evidence/experiments/h1-[name].md)

### KEPT: H2 — [Hypothesis Name]
- **Hypothesis:** [What you thought would improve.]
- **Evidence:** [What JFR/JMH/k6 showed before the change.]
- **Result:** [What actually happened after the change, with numbers.]
- **Why kept:** [Why the numbers justified keeping it.]
- **Full report:** [`evidence/experiments/h2-[name].md`](evidence/experiments/h2-[name].md)

---

## What Mattered Most

**[Experiment name]** — [One sentence on the biggest win. Include the key numbers.]

[2–3 sentences explaining the insight that led to it.]

---

## What Did Not Matter

**[Experiment name]** — [One sentence on the biggest miss.]

[2–3 sentences on the lesson learned.]

---

## Video Changelog Reference (30 seconds)

> "Baseline: [tech stack] — [baseline numbers]. First I tried [experiment 1] and [experiment 2] — both falsified by measurement. The real win was [kept experiment]: [what changed], [measured delta]. I also explored [other experiment] — it [result]. [X] mattered most. [Y] mattered least."
