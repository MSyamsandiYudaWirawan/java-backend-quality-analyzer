# Java Backend Quality Rubric v1

The shared scoring contract. The **human expert** ranks repos with this rubric
(ground truth), and the **advanced agent** scores repos with this rubric
(measured against the expert via Spearman ρ). Every point must cite evidence:
a file path, a test report, a build log, a k6 result, or a JFR diagnosis.

Total: **100 points**, 5 dimensions.

---

## 1. Build & Test Health — 25 pts

| Item | Pts | Full credit | Half credit | Zero | Evidence |
|------|-----|-------------|-------------|------|----------|
| Build passes | 10 | Clean `mvn package` / `gradle build` on Java 21 | Passes with warnings/skipped steps | Fails | build log |
| Tests pass | 10 | Full suite green | Green only with exclusions | Any failure / no tests run | surefire/gradle test report |
| Test depth | 5 | Real coverage of core logic (not just smoke tests); test sources ≳ 30% of main sources | Tests exist but shallow (few assertions, happy path only) | No meaningful tests | test file census + sampled test classes |

## 2. Architecture & Structure — 20 pts

| Item | Pts | Full credit | Half credit | Zero | Evidence |
|------|-----|-------------|-------------|------|----------|
| Layering | 10 | Clear controller / service / persistence separation (or justified alternative); no business logic in controllers or entities | Separation exists but leaky (fat controllers, anemic services) | Big-ball-of-mud | package tree + cited classes |
| Framework fit | 5 | MVC vs WebFlux (or other) matches the app's I/O profile | Workable but questionable choice | Choice actively fights the workload | cited endpoints + deps |
| Structural sanity | 5 | No god classes (>~500 LOC), config externalized, no secrets in repo | One violation | Two or more | file citations |

## 3. Dependency Health — 15 pts

| Item | Pts | Full credit | Half credit | Zero | Evidence |
|------|-----|-------------|-------------|------|----------|
| Currency | 8 | Deps within ~1 major version of current | Noticeably behind | Multiple majors behind / EOL framework | `versions:display-dependency-updates` or equivalent |
| Risk & bloat | 7 | No known-vulnerable flags, no unused/duplicate deps | Unused deps only | Known-vulnerable deps | `dependency:analyze` / audit output |

## 4. Runtime Behavior — 25 pts

| Item | Pts | Full credit | Half credit | Zero | Evidence |
|------|-----|-------------|-------------|------|----------|
| Boots & stays up | 5 | Starts cleanly, health endpoint OK under load | Starts but degraded | Doesn't run | run log |
| Latency / throughput | 10 | p95 within expectation for the app class at agreed load (VUs/DURATION fixed per eval) | p95 degraded but functional | Errors/timeouts under load | k6 JSON |
| JFR profile | 10 | No dominant hotspot: GC pauses modest, no long blocking socket reads on request threads, no lock contention | One concerning signal | One or more critical signals | `jfr-diagnose.sh` report |

> If a repo cannot be made to run (not bootable as a service, e.g. a library),
> dimension 4 is scored 0 and the report must say so explicitly — that absence
> of runtime evidence is itself a finding for a "backend" being acquired.

## 5. Maintainability & Docs — 15 pts

| Item | Pts | Full credit | Half credit | Zero | Evidence |
|------|-----|-------------|-------------|------|----------|
| README / onboarding | 5 | Setup steps exist and actually work when followed | Exists but stale/incomplete | Missing or wrong | followed steps verbatim |
| Code legibility | 5 | Consistent naming/style, comments explain why | Inconsistent but readable | Obfuscated / generated mess | cited samples |
| Repo hygiene | 5 | License present, no committed binaries/secrets, sane history | One violation | Two or more | repo scan |

---

## Ranking Procedure (expert)

1. Score each eval repo independently with this rubric. Fill every cell.
2. Total → rank. Ties broken by dimension 4 subtotal, then dimension 1.
3. Write 2–3 sentences of justification per repo — this is the audit trail
   that makes the ground truth defensible to judges.
4. Record the ranking in `service/eval/expert-ranking.txt` (best first).

## Rules for the Agent

- Same rubric, same anchors, same evidence requirement. No self-assigned
  partial credit without a citation.
- Every dimension score in the report links to its evidence artifact.
- Uncertainty is reported, not guessed around: "could not verify X because Y"
  scores 0 with a note, never an assumed pass.

## Known Limitation (by design)

The baseline analyzer (`service/baseline/analyze.sh`) observes only items
1.1, 1.2, and a shadow of 1.3 — roughly 25 of 100 rubric points, scored
binary. Its expected ρ against the expert ranking is low. That gap *is* the
measured-improvement story.
