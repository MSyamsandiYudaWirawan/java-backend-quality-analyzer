# Improvement Changelog

> **Branch:** `exp/h2-k6-generation` — this changelog covers the baseline stage and iterations 1–2 (h1, KEPT; h2, KEPT). Later iterations document themselves on their own branches.

## The Metric

The unit of improvement here is **agent capability**, not service throughput. Every experiment adds one capability to the analysis workflow and is measured by running baseline and experiment over the **same fixed eval set** (`service/targets.txt`, 10 Java backend repos) and comparing both against the human-expert ranking (`service/eval/expert-ranking.txt` — v1 at h1, revised to v2 before the h2 eval).

- **Primary:** Spearman rank correlation (ρ) between analyzer score order and expert ranking.
- **Secondary:** concrete findings per repo (each traced to a file/test/profiler recording), evidence traceability, wall-clock time per analysis.

With ~10 repos, ρ is a coarse signal — one repo moving a rank swings it. So per-repo scores and the tie/pair checks the harness reports alongside ρ are co-primary evidence in every entry.

## Structure

This document tracks every meaningful iteration. The judges want to see **how you think**, not just what you built.

**Only two final solutions exist:**
- **Baseline** — simplest thing that passes tests (the control analyzer `service/baseline/analyze.sh` + committed evidence, present on every branch)
- **Advanced** — incorporates capabilities that **survived measurement** (`advanced` branch)

Everything else is an experiment: kept or rejected. Rejected experiments are required by the rubric ("one experiment you removed").

**Each iteration lives on its own Git branch.** This lets judges (and you) check out any exact state and reproduce the measurement.

**Reproducing any iteration up to this stage:**
```bash
git checkout exp/h1-rubric-scoring     # or: git checkout exp/h2-k6-generation
tests/unit/test-baseline.sh           # fast offline checks (see REPRODUCTION.md)
./service/baseline/analyze.sh <repo-url>
bash service/advanced/collect.sh <repo-url> --out evidence/advanced/h1/<repo>
./run-experiment.sh <repo-url> --docker   # h2 measured run (committed k6 script)
# headline numbers from committed scores: see REPRODUCTION.md (--resume)
```

---

## Iteration Log

| # | Branch | Change | Evidence | Result | Status |
|---|--------|--------|----------|--------|--------|
| 1 | `baseline` (control) | Naive analyzer: 5 shallow yes/no checks → 0–100 score | spring-petclinic run (`evidence/baseline/spring-petclinic/`) | 100/100 — saturates, no headroom to rank repos | BASELINE |
| 2 | `baseline` (control) | Full eval-set run: 10 repos vs expert ranking v1, tie-aware harness | `evidence/eval/baseline/` (eval-report.md, eval-results.json) | **ρ = 0.811** — NOT ROBUST: 5-way tie at 90 spans expert ranks 2–8; ρ carried by 3 anchors; 11 of 45 pairs unjudged; environment-sensitive (same run gave 0.493 with a stray container on port 5432) | BASELINE-HEADLINE |
| 3 | `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence (build/test logs, census, package tree, dep analysis, repo scan); Runtime = 0 uniformly; committed per-repo score sheets with per-item citations | `evidence/eval/h1/`, `evidence/advanced/h1/*/score-sheet.json` | **ρ = 0.865** vs v1 (0.939 vs v2); 90-tie broken (5 repos now span 50–63, cited); tie bounds [0.835, 0.929] vs baseline [0.527, 0.915]; unjudged pairs 3 vs 11 | KEPT |
| 4 | — | Human ruling: expert ranking revised v1 → v2 (blog-rest-api 6th → 10th on the verified committed JWT secret; petclinic-degraded kept at v1 relative position) | `evidence/experiments/expert-ranking-v2-decision.md`, `evidence/expert-ranking-notes.md` | h1 re-ranked vs v2: **ρ = 0.939** (`evidence/eval/h1-v2/`) — all h2 numbers below are vs v2 | RULING |
| 5 | `exp/h2-k6-generation` | Agent-generated k6 load tests (template+slots, smoke gate, fixed docker envelope, dual 50/200-VU profile); Runtime scored blind from measured load reports; JFR item = 0 uniformly (h3 seam); NOT_TESTABLE = Runtime 0 with root-cause note | `evidence/eval/h2/`, `evidence/advanced/h2/` + `evidence/advanced/h2-50vus/` (committed scripts, slots, load reports) | **ρ = 0.954** (h1 0.939, baseline 0.811); controlled-repo ordering recovered exactly; h1's honest tie at 55 broken (caffeine 70 vs mvc 65, on 2168 rps PASS vs FAIL @200); unjudged pairs 3 → 1; petclinic (baseline 100/100) saturates at ~234 rps, p95 2191ms @200 VUs | KEPT |

---

## Experiment Details

### BASELINE: Naive analyzer + the measurement machinery around it
- **What was built:** `service/baseline/analyze.sh` (5 binary checks, weights
  10/10/20/25/35); the shared rubric (`service/rubric/quality-rubric.md`);
  the eval harness (`service/eval/evaluate.py`, stdlib-only) with `--resume`
  and tie-awareness (ρ bounds over tie-breakings, pair counts, NOT ROBUST
  stamp when >20% of pairs are unjudged); the finalized 10-repo eval set
  (`service/targets.txt`); expert ranking v1 (notes in
  `evidence/expert-ranking-notes.md`).
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
- **Result:** ρ = **0.865** vs v1; the baseline-tied 5 repos now span 50–63
  with citations; tie bounds [0.835, 0.929] (baseline: [0.527, 0.915]);
  unjudged pairs 3 of 45 (baseline: 11). Runtime dimension scored 0 uniformly
  (h1 rule) — 25 rubric points left dark for h2/h3. The remaining 3-way tie at
  55 (practice-mvc / mvc-caffeine / petclinic-degraded) is honest: structurally
  near-identical repos whose real differences are runtime behavior, out of h1
  scope by design.
- **Why kept:** Pre-registered criteria met: ρ > 0.811 and the tie broken
  into an evidence-defensible order. The gain is in discrimination (pair
  check), not the headline number — +0.054 sits inside the baseline's own
  luck envelope.
- **Resolved after h1 (human ruling):** h1 disagreed with expert ranking v1 on
  blog-rest-api (h1 9th vs expert 6th — genuine undeclared-MySQL test failure
  + committed JWT secret) and petclinic-degraded (h1 5–7th vs expert 9th).
  The human revised the ranking to **v2** before the h2 eval: blog-rest-api
  6th → 10th on the verified secret; petclinic-degraded kept (its failures
  are intentionally injected — design intent is not a code property).
  Decision record: `evidence/experiments/expert-ranking-v2-decision.md`.
  h1 vs v2: ρ = **0.939** (`evidence/eval/h1-v2/`).
- **Full report:** [`evidence/experiments/h1-rubric-scoring.md`](evidence/experiments/h1-rubric-scoring.md)

### KEPT: H2 — Agent-generated k6 load testing, Runtime scored from measured evidence
- **Hypothesis (pre-registered before any k6 script was generated or executed):**
  An agent that generates and executes its own k6 load tests against the
  booted targets — template + slots, fixed load profile across repos — and
  scores the rubric's Runtime dimension from the measured evidence ranks the
  eval set closer to the expert than h1 does. Mechanism: h1's Runtime = 0
  rule left the honest 3-way tie at 55 and the 4 controlled repos' known
  runtime ordering (webflux-redis > webflux > mvc-caffeine > mvc — the only
  repos ranked on measured runtime knowledge) unchecked. h2 is the first
  capability that can check itself against ground truth.
- **Explicit falsification pre-registration:** KEPT if (a) the controlled-repo
  ordering is recovered AND (b) full-set ρ ≥ h1 with no increase in unjudged
  pairs; MIXED if ordering recovered but ρ drops (fix the scoring, not the
  measurement); REJECTED if the ordering is not recovered or smoke gates fail
  on repos the expert ranked on runtime knowledge.
- **Design (per `prompts/README.md` §5):** generation is template + slots,
  never free-form (`service/advanced/k6/template.js` + `service/advanced/gen-k6.py`,
  stdlib validator/renderer; `template-form.js` variant for server-rendered
  apps); scripts committed per repo, re-runs never regenerate; a smoke gate
  must pass before acceptance; measured path is docker with an identical
  resource envelope for every target (`service/advanced/docker/h2-*.yml` +
  generic `Dockerfile.target`); NOT_TESTABLE → Runtime = 0 with an explicit
  note — a finding, not a harness failure.
- **Dual fixed profile (human decision, raised BEFORE any evidence was
  committed — 50 VUs kept every repo far from its saturation knee):** 50-VU
  efficiency runs at `evidence/advanced/h2-50vus/<repo>/`, 200-VU stress runs
  at `evidence/advanced/h2/<repo>/`; otherwise identical (10s ramp + 60s hold,
  10% creates / 90% reads of 50 seeded entities, thresholds p95<500ms /
  err<1% / checks>95%).
- **Result:** ρ = **0.954** vs v2 (h1: 0.939, baseline: 0.811), n=10; tie
  bounds [0.939, 0.964]; pair check 41 concordant / 3 discordant / 1 unjudged
  (h1: 39/3/3). Both pre-registered criteria MET: (b) 0.954 ≥ 0.939 with
  unjudged pairs 3 → 1; (a) the analyzer's final order of the 4 controlled
  repos matches the known order exactly — practice-mvc, the only FAIL @200 of
  the four, lands last on the runtime evidence alone. Caveat recorded: raw
  RPS ranks mvc-caffeine first (2168 > 1448 > 1031), so the order among the
  three PASS repos comes from the other rubric dimensions; the 1-CPU k6
  container makes raw-RPS ties at the top unreliable anyway.
- **Findings the baseline could never see:**
  - **spring-petclinic — baseline 100/100 — saturates at ~234 rps with p95
    2191ms / max 8111ms under 200 VUs, checks 100%**: pure queueing collapse
    (`evidence/advanced/h2/spring-petclinic/load-report.md`).
  - petclinic-degraded is runtime-identical to upstream (240 vs 234 rps,
    p95 2105 vs 2191ms — consistent with byte-identical runtime code); its
    remaining tie with practice-mvc at 65 is honest.
  - 3 NOT_TESTABLE findings with cited evidence: blog-rest-api boot-crashes
    on stock MySQL 8.4 ("Public Key Retrieval is not allowed", boot-diagnosis.log),
    gs-rest-service-complete has no create endpoint, spring-mvc-showcase's
    build fails on Java 21.
- **Why kept:** Both pre-registered criteria met, and the h1 honest tie broke
  on exactly the pre-registered mechanism — same code minus a cache: 2168 rps
  PASS vs FAIL @200. The ρ gain (+0.015) is small at n=10; the strong claim is
  the evidence and the pair check, not the headline.
- **Incidents and caveats (recorded):** MSYS path mangling on compose runs
  (third occurrence; `MSYS_NO_PATHCONV=1`); k6 `.values` summary nesting;
  `jarGlob` slot pins module6's boot jar; the k6 container has 1 CPU —
  mvc-caffeine's 2168 rps may approach the generator's ceiling, compressing
  the top end; JFR item scored 0 for all repos (h3 capability, same
  non-distortion rule as h1's Runtime = 0), so h2 max runtime is 15/25.
- **Full report:** [`evidence/experiments/h2-k6-generation.md`](evidence/experiments/h2-k6-generation.md)

---

## What Mattered Most

**Measuring what the tie was hiding (h2)** — h1's honest 3-way tie at 55 broke on exactly its real mechanism: practice-mvc-caffeine separated from practice-mvc (70 vs 65) on 2168 rps PASS vs FAIL at 200 VUs, same code minus a cache. The four controlled repos' known runtime ordering was recovered exactly, blind.

The insight: a capability earns its place when it checks itself against ground truth it was never shown. The controlled repos were the only ones the expert ranked on measured runtime knowledge — h2 recovered that ordering from its own measurements, which is a stronger validation than any ρ delta at n=10.

## What Did Not Matter

**Raw RPS at the top end.** mvc-caffeine posted the highest throughput of the eval set (2168 rps) but the 1-CPU k6 container may cap the generator before the target saturates — raw-RPS ties at the top are unreliable, and the order among the three PASS controlled repos comes from the other rubric dimensions, not from runtime. The robust signal is the threshold verdict at a fixed profile, not the leaderboard.

---

## Video Changelog Reference (30 seconds)

> "Baseline: a naive script that gives spring-petclinic 100/100 and ties five repos at 90. h1: an agent scores collected evidence against a rubric, blind, with citations — the tie broke, ρ 0.865. h2: the agent writes its own k6 load tests — template plus slots, smoke-gated, fixed docker envelope — and scores runtime from measurement. The four controlled repos came out in exactly their known order; petclinic, the baseline's 100/100, collapses at 234 rps under 200 VUs. ρ 0.954, one unjudged pair left of forty-five."
