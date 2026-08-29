# Session: Public target validation pass + eval set finalization

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k2
- Branch: `baseline`
- Human Checkpoint: yes

---

## Prompt Given

- "btw what is the public target requirement to make my pipeline benchmark
  working? java 21?, single service? what else"
- "pick best for my case from your suggestion and this from your prev session:
  spring-projects/spring-petclinic public good, petclinic-degraded (your
  fork) synthetic bottom"

Day 2 plan item 1: validate the public candidates in `service/targets.txt`
(clone + Java 21 build), drop/replace failures, record drops. The human also
asked for the target requirements to be made explicit.

## Key Decisions Made

- **Requirements split into "pipeline works" vs "scores well".** Hard:
  publicly cloneable, builds on Java 21 (Maven or Gradle), single deployable
  unit, bootable HTTP service with discoverable API surface (for h3 k6
  generation), Docker-provisionable infra, build+test within the 1800s
  harness timeout. Soft items (Testcontainers, actuator, README, license)
  affect evidence quality, not pipeline function — and *violating* them is
  desirable for bottom-tier anchors as long as failure is loud and fast.
- **Final 10-repo set:** 4 controlled practice repos + spring-petclinic
  (good) + petclinic-degraded (synthetic bottom, human building the fork) +
  springboot-blog-rest-api and REST-With-Spring (average) + gs-rest-service
  (weak-minimal) + spring-mvc-showcase (legacy). Dropped:
  iluwatar/java-design-patterns (library, not a backend — Runtime 0 by design,
  redundant bottom anchor) and eugenp/tutorials (build-time risk vs the 1800s
  harness timeout).
- **Non-root-buildable repos become pinned local clones, not URLs.** The
  harness's `analyze.sh` clones URLs at the default-branch root. Two
  validated repos break that assumption: gs-rest-service (root is guide
  scaffolding; service lives in `complete/`) and REST-With-Spring (default
  branch is a course landing page; code lives on per-module branches). Both
  were imported under `targets/` pinned to the validated unit:
  `targets/gs-rest-service-complete` (complete/ @ upstream 2ef8e28, no .git —
  commit recorded in targets.txt) and `targets/REST-With-Spring-module6`
  (module6 branch @ 9c06a66, .git intact).
- **spring-mvc-showcase kept despite build failure.** It fails fast on
  Java 21 (`javax.xml.bind` removed post-Java 8) — that is the designed
  legacy-bottom evidence, not a validation failure. Failing loudly in seconds
  is exactly what the harness needs from a bottom-tier target.

## Agent Output Summary

- Files modified: `service/targets.txt` (final set + inline validation
  results + drop records), `service/eval/expert-worksheet.md` (new: ranking
  worksheet for the Day 2 expert session, with pre-filled validation facts).
- Validation results: spring-petclinic PASS, springboot-blog-rest-api PASS,
  gs-rest-service/complete PASS, REST-With-Spring module6 PASS,
  spring-mvc-showcase FAIL-fast (kept by design).
- Directories created: `targets/gs-rest-service-complete`,
  `targets/REST-With-Spring-module6` (both under the gitignored `targets/`).

## Human Checkpoint

- Reviewed before accepting: yes — the human picked the set shape ("pick best
  for my case") and took ownership of creating the petclinic-degraded fork.
- No manual changes to agent output.

## Retries / Corrections

- **Retry 1 (3 of 5 first-pass build "failures" were layout, not code):**
  gs-rest-service and REST-With-Spring reported "no known build file" at repo
  root. Diagnosis showed guide-scaffolding root and landing-page default
  branch respectively; both build cleanly once pinned to the real unit
  (`complete/`, `module6` branch). Only spring-mvc-showcase is a genuine
  build failure. Lesson for the advanced analyzer: "repo root is not the
  buildable unit" is a structural finding worth reporting, not a harness
  error — but the *baseline* will score such repos 0 on the build-file check,
  which is baseline blindness of a different flavor (false negative).
- **Correction (lost .git on subdir move):** moving `complete/` out of the
  gs-rest-service clone left it without .git; `git log` inside it silently
  resolved to the parent project repo (showed our own commit e3040f1 — easy
  to misread as the upstream commit). Resolved by recording the upstream
  commit hash (2ef8e28) in targets.txt instead of relying on in-clone .git.
