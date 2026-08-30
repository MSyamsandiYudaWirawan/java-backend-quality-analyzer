# Improvement Changelog

> **Branch:** `exp/h1-rubric-scoring` — this changelog covers the baseline stage and iteration 1 (h1, KEPT). Later iterations document themselves on their own branches.

## The Metric

The unit of improvement here is **agent capability**, not service throughput. Every experiment adds one capability to the analysis workflow and is measured by running baseline and experiment over the **same fixed eval set** (`service/targets.txt`, 10 Java backend repos) and comparing both against the human-expert ranking (`service/eval/expert-ranking.txt`, v1).

- **Primary:** Spearman rank correlation (ρ) between analyzer score order and expert ranking.
- **Secondary:** concrete findings per repo (each traced to a file/test/profiler recording), evidence traceability, wall-clock time per analysis.

With ~10 repos, ρ is a coarse signal — one repo moving a rank swings it. So per-repo scores and the tie/pair checks the harness reports alongside ρ are co-primary evidence in every entry.

## Structure

This document tracks every meaningful iteration. The judges want to see **how you think**, not just what you built.

**Only two final solutions exist:**
- **Baseline** — simplest thing that passes tests (`baseline` branch)
- **Advanced** — incorporates capabilities that **survived measurement** (`advanced` branch)

Everything else is an experiment: kept or rejected. Rejected experiments are required by the rubric ("one experiment you removed").

**Each iteration lives on its own Git branch.** This lets judges (and you) check out any exact state and reproduce the measurement.

**Reproducing any iteration up to this stage:**
```bash
git checkout baseline               # or: git checkout exp/h1-rubric-scoring
tests/unit/test-baseline.sh         # fast offline checks (see REPRODUCTION.md)
./service/baseline/analyze.sh <repo-url>
bash service/advanced/collect.sh <repo-url> --out evidence/advanced/h1/<repo>
# headline numbers from committed scores: see REPRODUCTION.md (--resume)
```

---

## Iteration Log

| # | Branch | Change | Evidence | Result | Status |
|---|--------|--------|----------|--------|--------|
| 1 | `baseline` | Naive analyzer: 5 shallow yes/no checks → 0–100 score | spring-petclinic run (`evidence/baseline/spring-petclinic/`) | 100/100 — saturates, no headroom to rank repos | BASELINE |
| 2 | `baseline` | Full eval-set run: 10 repos vs expert ranking v1, tie-aware harness | `evidence/eval/baseline/` (eval-report.md, eval-results.json) | **ρ = 0.811** — NOT ROBUST: 5-way tie at 90 spans expert ranks 2–8; ρ carried by 3 anchors; 11 of 45 pairs unjudged; environment-sensitive (same run gave 0.493 with a stray container on port 5432) | BASELINE-HEADLINE |
| 3 | `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence (build/test logs, census, package tree, dep analysis, repo scan); Runtime = 0 uniformly; committed per-repo score sheets with per-item citations | `evidence/eval/h1/`, `evidence/advanced/h1/*/score-sheet.json` | **ρ = 0.865** (baseline 0.811); 90-tie broken (5 repos now span 50–63, cited); tie bounds [0.835, 0.929] vs baseline [0.527, 0.915]; unjudged pairs 3 vs 11. Discordance on blog/degraded parked for expert-ranking v2 decision | KEPT |

---

## Experiment Details

### BASELINE: Naive analyzer + the measurement machinery around it
- **What was built:** `service/baseline/analyze.sh` (5 binary checks, weights
  10/10/20/25/35); the shared rubric (`service/rubric/quality-rubric.md`);
  the eval harness (`service/eval/evaluate.py`, stdlib-only) with `--resume`
  and tie-awareness (ρ bounds over tie-breakings, pair counts, NOT ROBUST
  stamp when >20% of pairs are unjudged); the finalized 10-repo eval set
  (`service/targets.txt`); expert ranking v1 (`service/eval/expert-ranking.txt`,
  notes in `evidence/expert-ranking-notes.md`).
- **Result:** ρ = **0.811** (n=10) vs v1 — tie-sensitive, range [0.527, 0.915],
  24% of pairs unjudged (`evidence/eval/baseline/eval-report.md`). 7 of 10
  scores sit in two tie groups (100×2, 90×5). Analyst note in the same file:
  Monte Carlo P(ρ ≥ 0.811 by luck) ≈ 29%; the Day-2 port-5432 incident
  (ρ swung to 0.493) shows the statistic is fragile at n=10.
- **Why this is the control:** the blindness is the point — a 35-LOC tutorial
  skeleton scores identically to the expert's #2 repo, and the four
  structurally near-identical controlled repos tie flat at 90
  (`evidence/baseline/practice-*`).

### KEPT: H1 — Rubric scoring by agent judgment on collected evidence
- **Hypothesis (pre-registered before any repo was scored):** An agent reading
  mechanically-collected evidence (build/test logs, test census, package tree,
  `dependency:analyze`, repo scan) and scoring the shared rubric with per-item
  citations ranks the eval set closer to the expert than the baseline's binary
  checks — mainly by breaking the 5-way tie at 90 (expert ranks 2–8) that the
  baseline cannot see. Falsification criteria pre-registered: KEPT if ρ > 0.811
  AND the tie breaks into an evidence-defensible order; REJECTED if ρ ≤ 0.811
  or the tie order contradicts evidence.
- **Evidence:** Baseline ρ = 0.811 carried by 3 anchors; 7/10 scores in two
  tie groups; Monte Carlo P(ρ ≥ 0.811 by luck) ≈ 29%
  (`evidence/eval/baseline/eval-report.md` analyst note).
- **Result:** ρ = **0.865**; the baseline-tied 5 repos now span 50–63 with
  citations; tie bounds [0.835, 0.929] (baseline: [0.527, 0.915]); unjudged
  pairs 3 of 45 (baseline: 11). Runtime dimension scored 0 uniformly
  (h1 rule) — 25 rubric points still dark. The remaining 3-way tie at 55
  (practice-mvc / mvc-caffeine / petclinic-degraded) is honest: structurally
  near-identical repos whose real differences are runtime behavior, out of
  h1 scope by design.
- **Why kept:** Pre-registered criteria met: ρ > 0.811 and the tie broken
  into an evidence-defensible order. The gain is in discrimination (pair
  check), not the headline number — +0.054 sits inside the baseline's own
  luck envelope.
- **Open decision (human):** h1 disagrees with expert ranking v1 on
  blog-rest-api (h1 9th vs expert 6th — genuine undeclared-MySQL test
  failure + committed JWT secret) and petclinic-degraded (h1 5–7th vs
  expert 9th — petclinic-grade architecture credits on a synthetic-bottom
  repo). Triggers the v2 ranking-revision policy; human decides before h2.
- **Collection incidents (recorded):** the port-5432 sensitivity reproduced
  during collection (petclinic re-collected with the container stopped,
  76/76 green); a collector bug fixed mid-run (`mvn -B -q` suppresses
  dependency-plugin output); the assertion census misses MockMvc/WebTestClient
  chains (documented limitation, noted in affected score sheets).
- **Full report:** [`evidence/experiments/h1-rubric-scoring.md`](evidence/experiments/h1-rubric-scoring.md)

---

## What Mattered Most

**Breaking the tie with cited judgment (h1)** — unjudged pairs fell 11 → 3 of 45 and the baseline's 90-tie became a defensible 50–63 span where every point cites a build log, test census, or dependency analysis.

The insight: the baseline's ρ = 0.811 was never the problem to beat — its *silence* was. Judgment only counts when it is blind (the agent never saw the expert ranking) and cited (every rubric item points at a collector artifact), which is what makes the broken tie defensible rather than a different kind of noise.

## What Did Not Matter

**The headline ρ gain.** +0.054 (0.811 → 0.865) sits inside the baseline's own luck envelope (P(ρ ≥ 0.811 by luck) ≈ 29%); at n=10 the number alone would prove nothing. The pair check and the tie bounds are the evidence that h1 added signal — a lesson carried forward: never report ρ without them.

---

## Video Changelog Reference (30 seconds)

> "Baseline: a naive script that gives spring-petclinic 100/100 and can't tell good from great — it ties 5 repos at 90 and its ρ of 0.811 is luck-sensitive. First experiment (h1): an agent reads mechanically-collected evidence — build logs, test census, dependency analysis — and scores a shared rubric blind, with citations. The tie broke: those 5 repos now span 50 to 63 with receipts, unjudged pairs fell from 11 to 3, ρ 0.865. The number barely moved; the discrimination is the win."
