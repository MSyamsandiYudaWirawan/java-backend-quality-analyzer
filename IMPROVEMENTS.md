# Improvement Changelog

## The Metric

The unit of improvement here is **agent capability**, not service throughput. Every experiment adds one capability to the analysis workflow and is measured by running baseline and experiment over the **same fixed eval set** (`service/targets.txt`, ~10 Java backend repos) and comparing both against the human-expert ranking.

- **Primary:** Spearman rank correlation (ρ) between analyzer score order and expert ranking.
- **Secondary:** concrete findings per repo (each traced to a file/test/profiler recording), evidence traceability, wall-clock time per analysis.

With ~10 repos, ρ is a coarse signal — one repo moving a rank swings it. So per-repo scores and the "findings the baseline missed" story are co-primary evidence in every entry.

## Structure

This document tracks every meaningful iteration. The judges want to see **how you think**, not just what you built.

**Only two final solutions exist:**
- **Baseline** — simplest thing that passes tests (`baseline` branch)
- **Advanced** — incorporates capabilities that **survived measurement** (`advanced` branch)

Everything else is an experiment: kept or rejected. Rejected experiments are required by the rubric ("one experiment you removed").

**Each iteration lives on its own Git branch.** This lets judges (and you) check out any exact state and reproduce the measurement.

```
git log --oneline --all

a1b2c3d  (advanced) Final advanced: [description]
e4f5g6h  (exp/h[N]-[name]) [Description] — KEPT (partial)
i7j8k9l  (exp/h[N]-[name]) [Description] — KEPT
m0n1o2p  (exp/h[N]-[name]) [Description] — REJECTED
u6v7w8x  (baseline) Baseline: naive analyzer
```

**Reproducing any iteration:**
```bash
git checkout exp/[name]
tests/unit/test-baseline.sh                 # fast offline checks
./service/baseline/analyze.sh <repo-url>    # or the advanced workflow per REPRODUCTION.md
```

---

## Iteration Log

| # | Branch | Change | Evidence | Result | Status |
|---|--------|--------|----------|--------|--------|
| 1 | `baseline` | Naive analyzer: 5 shallow yes/no checks → 0–100 score | spring-petclinic run (`evidence/baseline/spring-petclinic/`) | 100/100 — saturates, no headroom to rank repos | BASELINE |
| 2 | `exp/h1-[name]` | [Capability added + hypothesis] | [Eval-set scores] | [Δρ, findings added] | **TBD** |
| 3 | `exp/h2-[name]` | [Capability added + hypothesis] | [Eval-set scores] | [Δρ, findings added] | **TBD** |
| 4 | `advanced` | [Final workflow] | [Full eval-set comparison] | [baseline ρ → advanced ρ] | ADVANCED |

---

## Experiment Details

### REJECTED: H1 — [Hypothesis Name]
- **Hypothesis:** [What capability you thought would improve ranking quality.]
- **Evidence:** [What the eval set showed before the change — scores, missed findings.]
- **Result:** [What actually happened after the change, with per-repo scores.]
- **Why rejected:** [Why the numbers didn't justify keeping it.]
- **Full report:** [`evidence/experiments/h1-[name].md`](evidence/experiments/h1-[name].md)

### KEPT: H2 — [Hypothesis Name]
- **Hypothesis:** [What capability you thought would improve ranking quality.]
- **Evidence:** [What the eval set showed before the change — scores, missed findings.]
- **Result:** [What actually happened after the change, with per-repo scores.]
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

> "Baseline: a naive script that gives spring-petclinic 100/100 and can't tell good from great. First I tried [experiment 1] and [experiment 2] — both falsified on the eval set. The real win was [kept experiment]: [what changed], [measured delta in ranking quality / findings]. I also explored [other experiment] — it [result]. [X] mattered most. [Y] mattered least."
