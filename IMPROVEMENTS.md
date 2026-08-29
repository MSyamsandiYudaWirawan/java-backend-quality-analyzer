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
| 2 | `baseline` | Full eval-set run: 10 repos vs expert ranking v1 | `evidence/eval/baseline/` (eval-report.md, eval-results.json) | **ρ = 0.811** — but a 5-way tie at 90 spans expert ranks 2–8; ρ carried by 3 anchors (petclinic top, degraded/showcase bottom). Environment-sensitive: same run gave ρ = 0.493 when a stray Docker container broke petclinic's tests | BASELINE-HEADLINE |
| 3 | `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence (build/test logs, census, package tree, dep analysis, repo scan); Runtime = 0 uniformly; committed per-repo score sheets | `evidence/eval/h1/`, `evidence/advanced/h1/*/score-sheet.json` | **ρ = 0.865** (baseline 0.811); 90-tie broken (5 repos now span 50–63, cited); tie bounds [0.835, 0.929] vs baseline [0.527, 0.915]; unjudged pairs 3 vs 11. Discordance on blog/degraded parked for expert-ranking v2 decision | KEPT |
| 4 | `exp/h2-[name]` | [Capability added + hypothesis] | [Eval-set scores] | [Δρ, findings added] | **TBD** |
| 5 | `advanced` | [Final workflow] | [Full eval-set comparison] | [baseline ρ → advanced ρ] | ADVANCED |

---

## Experiment Details

### KEPT: H1 — Rubric scoring by agent judgment on collected evidence
- **Hypothesis:** An agent reading mechanically-collected evidence (build/test
  logs, test census, package tree, `dependency:analyze`, repo scan) and
  scoring the shared rubric with per-item citations ranks the eval set
  closer to the expert than the baseline's binary checks — mainly by
  breaking the 5-way tie at 90 (expert ranks 2–8) that the baseline cannot
  see.
- **Evidence:** Baseline ρ = 0.811 carried by 3 anchors; 7/10 scores in two
  tie groups; Monte Carlo P(ρ ≥ 0.811 by luck) ≈ 29%
  (`evidence/eval/baseline/eval-report.md` analyst note).
- **Result:** ρ = **0.865**; the baseline-tied 5 repos now span 50–63 with
  citations; tie bounds [0.835, 0.929] (baseline: [0.527, 0.915]); unjudged
  pairs 3 of 45 (baseline: 11). Runtime dimension scored 0 uniformly
  (h1 rule) — 25 rubric points still dark, h2/h3 territory.
- **Why kept:** Pre-registered criteria met: ρ > 0.811 and the tie broken
  into an evidence-defensible order. The gain is in discrimination (pair
  check), not the headline number.
- **Open decision (human):** h1 disagrees with expert ranking v1 on
  blog-rest-api (h1 9th vs expert 6th — genuine undeclared-MySQL test
  failure + committed JWT secret) and petclinic-degraded (h1 5–7th vs
  expert 9th — petclinic-grade architecture credits). Triggers the v2
  ranking-revision policy; human decides before h2.
- **Full report:** [`evidence/experiments/h1-rubric-scoring.md`](evidence/experiments/h1-rubric-scoring.md)

### REJECTED: H2 — [Hypothesis Name]
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
