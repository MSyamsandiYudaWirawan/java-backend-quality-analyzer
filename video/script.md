# 5-Minute Walkthrough Script

> Filled 2026-08-29 (packaging, `advanced` branch). Numbers verified against
> `evidence/eval/*/eval-report.md`. Practice once before recording.

---

## 0. Hook (15 sec)

"Teams acquire Java backends they didn't write — and manual review misses
exactly the issues that cost money: runtime behavior. I built an agent that
scores repo quality where every point traces to a file, a test result, or a
profiler recording."

## 1. Baseline (45 sec)

"My baseline is a naive shell script: five yes/no checks — README, pom,
tests exist, build passes, tests pass — summed to 100. Measured on
spring-petclinic: 100/100. On the 10-repo eval set it ties FIVE repos at
90/100 — it can't tell a cached WebFlux app from an empty skeleton. Its
ranking correlation with a human expert is 0.811, and the harness stamps it
NOT ROBUST: a quarter of repo pairs are unjudged ties. That's the control."

## 2. One Rejected Experiment (60 sec)

"Rejected mid-flight: the 50-VU load profile. My first measured runs put
every repo through 50 concurrent users — and ALL of them passed every
threshold by five times. The verdicts were vacuous: no repo was anywhere
near its saturation knee, so the measurement carried no ordering
information. I rejected the profile, re-rendered every script at 200 VUs,
and re-ran everything BEFORE any evidence was committed — comparability
preserved, garbage evidence never entered the repo. The 50-VU reports are
kept in `evidence/advanced/h2-50vus/` as the efficiency view."

## 3. One Kept Experiment (60 sec)

"The kept arc is measured runtime evidence. First the agent learned to
generate and run its own k6 load tests — template plus slots, smoke-gated,
same docker envelope for every repo. Then JFR profiling during that load.
Result on ranking correlation: 0.811 baseline → 0.865 rubric scoring →
0.954 with k6 → 0.973 with JFR. And the moment that justifies the whole
pipeline: spring-petclinic — the baseline's 100/100 showcase — collapses at
200 VUs: 189 requests per second, p95 two and a half seconds, checks 100%.
The JFR names the mechanism: 71,193 monitor waits on ONE global lock — the
fat-jar classloader's jar-file cache."

## 4. Advanced Solution (60 sec)

"The advanced solution is the full pipeline: clone, build, parsed test
evidence, agent-generated load test, JFR under load, rubric-scored report
with per-item citations. Final ranking correlation: 0.973, unjudged pairs
down from 11 to 1 of 45. Key trade-off: minutes per repo instead of
seconds — and honesty over coverage: three repos score Runtime 0 as
NOT_TESTABLE with root-cause findings instead of a faked number. The full
changelog is in `IMPROVEMENTS.md` — measured runtime evidence contributed
most; pure code-metrics scoring was rejected without a branch because its
best case adds no discriminative signal."

## 5. Key Failure Mode (30 sec)

"Trickiest bug: JFR recordings silently dying on Windows Docker Desktop.
With `disk=true`, JFR's chunk writes fail on the Windows bind mount and the
JVM aborts at startup. Then Git Bash rewrote my exported JFR path into a
Windows path when spawning docker — the fourth instance of that bug class.
Fix: in-memory recording flushed on graceful shutdown, plus
MSYS_NO_PATHCONV on every compose call. Both reproduced manually before
re-running."

## 6. Hot Take (30 sec)

"Static review can't see the failures that matter. The most polished repo
in the set is the worst runtime performer. And the signal everyone expects
in a Java profile — GC — explained nothing in seven out of seven
recordings; the decisive signals were lock contention and blocking I/O.
If your quality assessment doesn't boot the repo and put it under load,
you're grading the README."

## 7. Close (15 sec)

"Repo, reproduction guide, trajectories, and every measurement are in the
submission. `REPRODUCTION.md` regenerates the headline number — ρ 0.973 —
in under ten seconds from committed evidence. Thank you."

---

## Shot List (what's actually on screen)

- **§0 Hook** — talking head, or the top of `README.md` (Problem & User) if
  you want a visual anchor. Nothing else; keep it clean.
- **§1 Baseline** — 3 beats: (1) `service/baseline/analyze.sh` header block
  (the 5 checks, ~3 sec), (2) `evidence/eval/baseline/eval-report.md`
  scrolled to the score table — linger on the five 90/100 rows, (3) the
  `NOT ROBUST` stamp line under the ρ. This table IS the baseline story.
- **§2 Rejected** — split view: `evidence/advanced/h2-50vus/spring-petclinic/load-report.md`
  (left) vs `evidence/advanced/h2/spring-petclinic/load-report.md` (right).
  Point at PASS-by-5x thresholds on the left, FAIL at 200 VUs on the right.
- **§3 Kept — the money shot, give it the most care** — full-screen
  `evidence/advanced/h3/spring-petclinic/load-report.md`: RPS 189.08, p95
  2500ms, checks 100%, verdict FAIL (these h3 numbers match the narration;
  the h2 report's 233.77/2190ms is the no-profiler twin if asked). Then cut
  to `evidence/advanced/h3/spring-petclinic/jfr/diagnosis-report.md` at the
  `jdk.JavaMonitorEnter 71738` line and the fat-jar classloader finding.
- **§4 Advanced** — `Documentation.md` §Pipeline flow (schematic, 5 sec),
  then `evidence/eval/h3/eval-report.md` full ordering vs the baseline
  table from §1 (side-by-side if possible). Flash one NOT_TESTABLE:
  `evidence/advanced/h2/springboot-blog-rest-api/load-report.md` finding
  note. End on `IMPROVEMENTS.md` §Full Baseline-vs-Advanced Eval Table.
- **§5 Failure mode** — optional: `trajectories/kimi-cli/2026-08-29_17-10-h3-jfr-tooling.md`
  header on screen while you talk; or grep `MSYS_NO_PATHCONV` in
  `run-experiment.sh`. Talking head is fine here too.
- **§6 Hot take** — back on the h3 diagnosis report: the event-count table
  (`jdk.JavaMonitorEnter 71738 / 1886945` vs the tiny
  `jdk.GCPhasePauseLevel1 117 / 4719`) — the visual proof that "GC
  explained nothing".
- **§7 Close** — LIVE terminal, the one real demo:
  `python service/eval/evaluate.py --label h3 --resume --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" --targets service/targets.txt --ranking service/eval/expert-ranking.txt --out evidence/eval/h3`
  printing ρ = 0.973 in <10s. **After recording: `git checkout -- evidence/`
  — `--resume` regenerates the report and drops the hand-written analyst
  note.** Practice this command twice before recording.

## Recording Tips

- Use a terminal with a dark theme and large font (14pt+)
- Don't re-run measured runs live (6–9 min each) — show pre-generated
  artifacts: `evidence/advanced/h3/spring-petclinic/load-report.md` next to
  its `jfr/diagnosis-report.md` (the 71,193-monitor line)
- The 10-second live demo: the `evaluate.py --label h3 ... --resume` command
  from REPRODUCTION.md printing ρ = 0.973
- Have `evidence/eval/baseline/` and `evidence/eval/h3/` eval reports open
  side-by-side for the score-table contrast (5-way tie at 90 vs full
  ordering)
- Do not read from script verbatim — bullet-point memory cards are fine
