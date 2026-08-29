# Experiment h3 — full pipeline: k6 + JFR profiling under generated load

> Status: **complete — KEPT (ρ = 0.973 vs v2; h2 0.954, baseline 0.811)**.
> Hypothesis pre-registered below, unchanged (written before any JFR
> recording was taken or scored). Branch: `exp/h3-full-pipeline` (from
> `exp/h2-k6-generation` at `7500f0e`).

## Hypothesis

k6 alone says *how fast*, not *why*: a service can post high RPS with a
critical hotspot underneath. Adding **JFR profiling during the generated
load** and grading the rubric's Runtime dimension (25 pts) on **k6 + JFR
together** will either keep or improve ranking agreement with the expert
(h2 ρ = 0.954, `evidence/eval/h2/`), and — the real test — **explain the
spring-petclinic 200-VU collapse** (234 rps, p95 2191ms, max 8111ms, checks
100%, `evidence/advanced/h2/spring-petclinic/load-report.md`) with a concrete
JFR signal. That repo is the baseline's 100/100 showcase: k6 already caught
it failing; JFR must say why, or h3 adds nothing.

Grading rule (rubric §Runtime): strong throughput with a critical JFR signal
scores *lower* than modest throughput with a clean profile. The JFR item in
the h2 score sheets is currently 0-for-all (no evidence); it is the only
item h3 re-scores — all other items stay as committed in
`evidence/advanced/h1/*/score-sheet.json` + the h2 runtime extension.

## Pre-registered predictions (falsifiable)

1. **spring-petclinic / petclinic-degraded** (byte-identical runtime code,
   both collapsed at 200 VUs): blocking-stack signal — request threads
   parked/blocked on SocketRead to the DB (H1/H2 in jfr-diagnose terms) or
   lock contention (H5), NOT a GC-dominated profile. Checks were 100%, so
   the collapse is queueing, and the recording must show where threads wait.
2. **practice-mvc vs practice-mvc-caffeine**: the 10x rps gap (2168 vs
   ~200-class) is visible as fewer/shorter DB SocketReads in the caffeine
   sibling. If the JFRs look identical, the k6 difference is not
   load-path I/O and h3's grading rule loses its justification.
3. **practice-webflux / webflux-redis** (both PASS): no blocking-read
   signal on request threads; event-loop parks are short. A critical
   blocking finding here would be a surprise worth a v2-ranking discussion.
4. The JFR item moves off 0-for-all: at least the three NOT_TESTABLE repos
   stay 0 (policy §5 — could not load-test), the other seven get
   evidence-linked JFR citations.

## Validation

- Re-run the eval harness with h3 score sheets vs
  `service/eval/expert-ranking.txt` (v2). Compare ρ and tie bounds against
  h2 (0.954, bounds [0.939, 0.964]).
- Verdict **KEPT** if: ρ does not degrade beyond tie-bound overlap AND the
  petclinic collapse carries a named JFR signal. **REJECTED** if JFR adds
  no discriminative signal across the 7 testable repos, or degrades ρ
  without an explanation the evidence supports (the v2-ranking revision
  policy applies: contradicting runtime evidence revises the ranking, never
  excuses the analyzer).
- End-to-end check: score → load → profile → grade holds for all 10 repos,
  with the NOT_TESTABLE path (exit 3) unchanged.

## Design

- **Pipeline:** `run-experiment.sh <target> --docker --jfr`. `--jfr` boots
  the service with `-XX:StartFlightRecording=disk=true,dumponexit=true,
  filename=/jfr-repo/advanced/h3/<repo>/profile.jfr,settings=profile`
  (compose seam `JFR_OPTS`, `service/advanced/docker/h2-target.yml`).
  After the full k6 run the service is stopped (SIGTERM, 15s grace) so the
  JVM finalizes the recording — the temurin JRE image has no jcmd, so live
  dumps are not an option. `jfr-diagnose.sh` then produces
  `h3/<repo>/jfr/diagnosis-report.md`, unchanged from the pre-existing
  template (works on any .jfr path).
- **Evidence isolation:** committed k6 script + slots stay in
  `evidence/advanced/h2/<repo>/` and are never rewritten; all h3 run
  outputs (k6-smoke/full.json, load-report.*, profile.jfr, jfr/) land in
  `evidence/advanced/h3/<repo>/`.
- **Load profile:** unchanged from h2 (committed scripts, 200-VU stress
  profile) — the JFR recording describes the same load window the h2
  numbers came from. Note: JFR overhead (~1–2% for settings=profile) means
  h3 k6 numbers may differ trivially from h2's; scoring cites the h3 run's
  own report.
- **NOT_TESTABLE repos** (blog-rest-api, gs-rest-service-complete,
  spring-mvc-showcase): the finding path (exit 3) fires before any JFR
  step; Runtime stays 0 by policy §5.

## Results

**Verdict: KEPT.** Measured runs executed 2026-08-29 (`--docker --jfr`,
commits `8124f93`, `d8656ac`, `094437b`; score sheets + eval in the
follow-up commit).

### Prediction outcomes (pre-registered above, scored blind)

1. **petclinic/degraded = blocking signal, not GC — CONFIRMED** (lock
   branch). Both collapse on ONE global monitor: the fat-jar classloader's
   `UrlJarFiles$Cache` (71,193 of 71,738 events for petclinic, p95 407ms;
   degraded: 74,682 events p95 397ms — statistically identical, control
   confirmed). ThreadPark p95 1000ms on both. SocketRead ~9 events (H2
   in-memory DB — no DB I/O), GC 34 pauses p99 137ms (minor). The
   checks-100% + p95-2.5s collapse is request threads serializing on
   nested-jar resource resolution (Thymeleaf), exactly the queueing
   mechanism predicted.
2. **caffeine gap visible in DB SocketReads — CONFIRMED in direction.**
   mvc: 6,859 reads for ~67k requests; caffeine: 5,524 reads for ~149k
   requests → ~2.7x fewer reads/request (per-read latency unchanged, ~80ms,
   same Postgres). Caching eliminates reads per request; it does not speed
   up the DB.
3. **webflux/webflux-redis clean of blocking — CONFIRMED.** 2 and 4
   monitor events, 27/40 ThreadParks (idle-pool), no request-path socket
   reads. Both PASS k6 with clean profiles → jfrProfile 10/10 each.
4. **JFR item off 0-for-all — CONFIRMED.** 7 testable repos scored 2–10;
   the 3 NOT_TESTABLE repos stay 0 citing the h2 findings (no h3 runs, per
   human decision).

### The h3 grading rule earns its keep

**REST-module6 PASSed k6 (1219 rps, p95 312ms) with a CRITICAL JFR
signal**: 5,018 monitor events p95 1310ms (Tomcat RecycledProcessors +
shared HashMap) + 28,408 ThreadParks p95 1510ms. Graded jfrProfile 4/10:
strong throughput with a critical hotspot scores below modest throughput
with a clean profile. Without the JFR item, module6's runtime would have
scored above webflux-redis; the evidence held it to a tie.

### Harness numbers

- **ρ = 0.973** vs expert v2 (h2: 0.954, baseline: 0.811). Tie bounds
  [0.964, 0.976] (h2: [0.939, 0.964]).
- Pairs: 42 concordant / 2 discordant / 1 tied (h2: 41/3/1). The h2
  mvc/degraded tie broke in the expert's direction (69 > 67; expert 6 > 8).
- Remaining tie: webflux-redis = module6 at 82 (expert 2 vs 3) — the
  analyzer carries no ordering opinion, not a contradiction.
- Eval: `evidence/eval/h3/`; score sheets extended in place
  (`evidence/advanced/h1/*/score-sheet.json`, jfrProfile item only).

### Scoring rubric applied (pre-registered before application, uniform)

- 10 — clean request path (monitors < 1k, parks idle-only, no request-path
  reads, GC envelope-normal)
- 6 — one concerning, non-dominant mechanism
- 4 — one critical request-path mechanism (monitors p95 > 500ms at 1k+
  events, or blocking reads dominating)
- 2 — multiple compounding critical mechanisms
- 0 — unmeasurable (NOT_TESTABLE, h2 finding cited)

### Pipeline incidents during measurement (all fixed, see trajectory)

- `disk=true` JFR chunk writes fail on Docker Desktop Windows bind mounts →
  in-memory recording + dumponexit (pre-existing template's recipe).
- Git Bash mangled exported `JFR_OPTS` POSIX path on compose `up` →
  `MSYS_NO_PATHCONV=1` on all compose calls (4th instance of the bug class).
- Python `json.dump` defaulted to cp1252 on Windows → score sheets
  rewritten with explicit `encoding="utf-8"` (caught by the harness's JSON
  parse, before any scoring was consumed).
- `Dockerfile.target` pinned to `eclipse-temurin:21-jre-jammy` (floating
  tag moved 21.0.11 → 21.0.12 between h2 and h3).
