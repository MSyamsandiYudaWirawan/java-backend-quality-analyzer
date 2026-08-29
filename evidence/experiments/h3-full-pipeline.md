# Experiment h3 — full pipeline: k6 + JFR profiling under generated load

> Status: **in progress — hypothesis pre-registered below, before any JFR
> recording was taken or scored.** Branch: `exp/h3-full-pipeline` (from
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

_(pending — measured runs not yet executed)_
