# Improvement Changelog

> **Branch:** `exp/h3-full-pipeline` — this changelog covers the baseline stage and iterations 1–3 (h1, KEPT; h2, KEPT; h3, KEPT). The `advanced` branch packages this pipeline as the final workflow.

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
git checkout exp/h1-rubric-scoring     # or: exp/h2-k6-generation, exp/h3-full-pipeline
tests/unit/test-baseline.sh           # fast offline checks (see REPRODUCTION.md)
./service/baseline/analyze.sh <repo-url>
bash service/advanced/collect.sh <repo-url> --out evidence/advanced/h1/<repo>
./run-experiment.sh <repo-url> --docker          # h2 measured run
./run-experiment.sh <repo-url> --docker --jfr    # h3: same load + JFR recording
# headline numbers from committed scores: see REPRODUCTION.md (--resume)
```

---

## Iteration Log

| # | Branch | Change | Evidence | Result | Status |
|---|--------|--------|----------|--------|--------|
| 1 | `baseline` (control) | Naive analyzer: 5 shallow yes/no checks → 0–100 score | spring-petclinic run (`evidence/baseline/spring-petclinic/`) | 100/100 — saturates, no headroom to rank repos | BASELINE |
| 2 | `baseline` (control) | Full eval-set run: 10 repos vs expert ranking v1, tie-aware harness | `evidence/eval/baseline/` (eval-report.md, eval-results.json) | **ρ = 0.811** — NOT ROBUST: 5-way tie at 90 spans expert ranks 2–8; ρ carried by 3 anchors; 11 of 45 pairs unjudged; environment-sensitive (same run gave 0.493 with a stray container on port 5432) | BASELINE-HEADLINE |
| 3 | `exp/h1-rubric-scoring` | Agent rubric scoring on collected mechanical evidence (build/test logs, census, package tree, dep analysis, repo scan); Runtime = 0 uniformly; committed per-repo score sheets with per-item citations | `evidence/eval/h1/`, `evidence/advanced/h1/*/score-sheet.json` | **ρ = 0.865** vs v1 (0.939 vs v2); 90-tie broken (5 repos now span 50–63, cited); tie bounds [0.835, 0.929] vs baseline [0.527, 0.915]; unjudged pairs 3 vs 11 | KEPT |
| 4 | — | Human ruling: expert ranking revised v1 → v2 (blog-rest-api 6th → 10th on the verified committed JWT secret; petclinic-degraded kept at v1 relative position) | `evidence/experiments/expert-ranking-v2-decision.md`, `evidence/expert-ranking-notes.md` | h1 re-ranked vs v2: **ρ = 0.939** (`evidence/eval/h1-v2/`) — all h2/h3 numbers below are vs v2 | RULING |
| 5 | `exp/h2-k6-generation` | Agent-generated k6 load tests (template+slots, smoke gate, fixed docker envelope, dual 50/200-VU profile); Runtime scored blind from measured load reports; JFR item = 0 uniformly; NOT_TESTABLE = Runtime 0 with root-cause note | `evidence/eval/h2/`, `evidence/advanced/h2/` + `evidence/advanced/h2-50vus/` | **ρ = 0.954** (h1 0.939, baseline 0.811); controlled-repo ordering recovered exactly; h1's honest tie at 55 broken (caffeine 70 vs mvc 65, on 2168 rps PASS vs FAIL @200); unjudged pairs 3 → 1; petclinic (baseline 100/100) saturates at ~234 rps, p95 2191ms @200 VUs | KEPT |
| 6 | `exp/h3-full-pipeline` | JFR profiling during the generated load (`--jfr`); Runtime grades on k6 + JFR together; pre-registered 0–10 jfrProfile rubric; only the jfrProfile item re-scored | `evidence/eval/h3/`, `evidence/advanced/h3/` (profile.jfr + jfr/diagnosis-report.md per repo) | **ρ = 0.973** (h2 0.954); 4/4 pre-registered predictions confirmed; petclinic collapse explained — 71k monitor waits on the fat-jar classloader lock; module6 k6-PASS held down by its critical JFR signal; pairs 42/2/1; tie bounds [0.964, 0.976] | KEPT |

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
  AND the tie breaks into an evidence-defensible order.
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
  pairs; REJECTED if the ordering is not recovered or smoke gates fail on
  repos the expert ranked on runtime knowledge.
- **Result:** ρ = **0.954** vs v2 (h1: 0.939, baseline: 0.811); tie bounds
  [0.939, 0.964]; pair check 41/3/1 (h1: 39/3/3). Both criteria MET. The h1
  honest tie broke on exactly the pre-registered mechanism — same code minus
  a cache: 2168 rps PASS vs FAIL @200. spring-petclinic — baseline 100/100 —
  saturates at ~234 rps with p95 2191ms / max 8111ms under 200 VUs, checks
  100%: pure queueing collapse. 3 NOT_TESTABLE findings with cited root
  causes (MySQL 8.4 boot crash, no create endpoint, Java 21 build failure).
  Caveat recorded: the 1-CPU k6 container may cap the top end — threshold
  verdicts are the robust signal, not raw RPS.
- **Full report:** [`evidence/experiments/h2-k6-generation.md`](evidence/experiments/h2-k6-generation.md)

### KEPT: H3 — JFR profiling during the generated load (full pipeline)
- **Hypothesis (pre-registered before any JFR recording was taken or scored):**
  k6 alone says *how fast*, not *why*: a service can post high RPS with a
  critical hotspot underneath. Adding JFR profiling during the generated load
  and grading Runtime on k6 + JFR together will keep or improve ranking
  agreement (h2 ρ = 0.954) AND — the real test — explain the spring-petclinic
  200-VU collapse with a concrete JFR signal. Grading rule (rubric §Runtime):
  strong throughput with a critical JFR signal scores *lower* than modest
  throughput with a clean profile. Only the jfrProfile item is re-scored.
- **Pre-registered predictions (4, falsifiable):** (1) petclinic/degraded =
  blocking-stack or lock signal, NOT GC-dominated; (2) the mvc/caffeine 10x
  rps gap visible as fewer/shorter DB SocketReads in the caffeine sibling;
  (3) webflux pair clean of request-path blocking; (4) JFR item moves off
  0-for-all (7 testable repos scored, 3 NOT_TESTABLE stay 0).
- **Validation rule:** KEPT if ρ does not degrade beyond tie-bound overlap
  AND the petclinic collapse carries a named JFR signal; REJECTED if JFR
  adds no discriminative signal, or degrades ρ without evidence.
- **Result:** ρ = **0.973** vs v2 (h2: 0.954); tie bounds [0.964, 0.976];
  pairs 42 concordant / 2 discordant / 1 tied (h2: 41/3/1). The h2
  mvc/degraded tie broke in the expert's direction (69 > 67; expert 6 > 8).
  **4/4 predictions CONFIRMED**:
  1. Petclinic collapses on ONE global monitor — the fat-jar classloader's
     `UrlJarFiles$Cache` (71,193 of 71,738 monitor events, p95 407ms);
     ThreadPark p95 1000ms; SocketRead ~9 events (H2 in-memory DB); GC 34
     pauses p99 137ms (minor). Degraded twin: 74,682 events p95 397ms —
     statistically identical, control confirmed.
  2. mvc: 6,859 DB SocketReads for ~67k requests vs caffeine: 5,524 for
     ~149k → ~2.7x fewer reads/request; per-read latency unchanged (~80ms,
     same Postgres). Caching eliminates reads; it does not speed up the DB.
  3. webflux/webflux-redis: 2 and 4 monitor events, 27/40 idle-pool parks,
     no request-path reads → jfrProfile 10/10 each.
  4. 7 testable repos scored 2–10; the 3 NOT_TESTABLE repos stay 0 citing
     the h2 findings (no h3 runs, per human decision).
- **The grading rule earns its keep:** REST-module6 PASSed k6 (1219 rps,
  p95 312ms) with a CRITICAL JFR signal — 5,018 monitor events p95 1310ms
  (Tomcat RecycledProcessors + shared HashMap) + 28,408 ThreadParks p95
  1510ms → jfrProfile 4/10, held to a tie with clean-profiled webflux-redis
  instead of rising above it.
- **Scoring rubric (pre-registered before application, uniform 0–10):** 10
  clean request path; 6 one concerning non-dominant mechanism; 4 one
  critical request-path mechanism (monitors p95 > 500ms at 1k+ events, or
  blocking reads dominating); 2 multiple compounding critical mechanisms;
  0 unmeasurable (NOT_TESTABLE).
- **Caveats (recorded):** the diagnosis template's severity labels were NOT
  used as scores — its p95-based thresholds mark even 2 monitor events
  "CRITICAL"; scoring weighed count × duration on the request path instead.
  Envelope-normal GC (p99 87–137ms on the 2-CPU G1 envelope, all repos)
  carries no deduction. JFR overhead (~1–2%, settings=profile) means h3 k6
  numbers may differ trivially from h2's; scoring cites the h3 run's own
  report.
- **Why kept:** Both pre-registered criteria met: ρ did not degrade AND the
  petclinic collapse carries a named mechanism. This is the "undeniable
  evidence moment": baseline 100/100 → k6 catches the failure → JFR names
  the cause.
- **Pipeline incidents during measurement (all fixed):** `disk=true` JFR
  chunk writes fail on Docker Desktop Windows bind mounts → in-memory
  recording + dumponexit; Git Bash mangled the exported `JFR_OPTS` POSIX
  path → `MSYS_NO_PATHCONV=1` (4th instance of the bug class); Python
  `json.dump` defaulted to cp1252 on Windows → score sheets rewritten with
  explicit `encoding="utf-8"` (caught by the harness's JSON parse before
  any scoring was consumed); `Dockerfile.target` pinned to
  `eclipse-temurin:21-jre-jammy` (floating tag moved 21.0.11 → 21.0.12
  between h2 and h3).
- **Full report:** [`evidence/experiments/h3-full-pipeline.md`](evidence/experiments/h3-full-pipeline.md)

---

## What Mattered Most

**Naming the mechanism (h3)** — h2 caught spring-petclinic collapsing at 200 VUs (234 rps, p95 2191ms, checks 100%) but could not say why; h3's JFR named it: 71,193 monitor waits on ONE global lock, the fat-jar classloader's `UrlJarFiles$Cache`, replicated exactly by its byte-identical degraded twin.

The insight: throughput numbers and their causes are different evidence, and they can disagree. module6 PASSed k6 while sitting on a critical lock — without the JFR item it would have scored above a clean-profile repo. "How fast" ranks repos; "why" is what an acquirer actually needs to know.

## What Did Not Matter

**GC — the signal everyone looks for first.** Seven out of seven JFR recordings showed envelope-normal GC (p99 87–137ms on the 2-CPU G1 envelope); it explained nothing and carried no deduction. The collapses were locks and blocking I/O. Same lesson at the tooling level: the diagnosis template's CRITICAL/CONCERNING severity labels are uncalibrated defaults (2 monitor events can be "CRITICAL") — useful as pointers, useless as scores.

---

## Video Changelog Reference (30 seconds)

> "Baseline: a naive script that gives spring-petclinic 100/100. h1: blind rubric scoring on collected evidence — the 90-tie broke, ρ 0.865. h2: agent-generated k6 load tests — the controlled repos came out in their known order, petclinic collapsed at 200 VUs, ρ 0.954. h3: JFR under the same load named the cause — 71,000 threads queued on one fat-jar classloader lock, in the baseline's favorite repo. ρ 0.973, one unjudged pair of forty-five. Every point cites a file, a load report, or a recording."
