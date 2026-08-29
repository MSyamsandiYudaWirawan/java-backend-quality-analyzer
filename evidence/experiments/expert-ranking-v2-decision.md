# Expert-ranking v2 — decision memo (AWAITING HUMAN RULING)

> Status: **draft for the human's ruling**, prepared before the h2 eval per
> `prompts/README.md` §3. The ruling itself (revise with justification, or
> keep v1 with a note) is the human's; record it here and in
> `evidence/expert-ranking-notes.md` when made.

## What is contested

h1 blind scoring (`evidence/advanced/h1/*/score-sheet.json`, scored without
seeing the expert ranking) disagrees with expert v1 on exactly two repos.
All 5 h1-discordant pairs concentrate here.

| Repo | Expert v1 | h1 | Gap |
|------|-----------|----|-----|
| springboot-blog-rest-api | 6th (65) | 9th (42) | h1 much harsher |
| petclinic-degraded | 9th (30) | 5–7th (55, 3-way tie) | h1 much kinder |

## Circularity warning (read before ruling)

Revising the ground-truth ranking *toward* the analyzer mechanically
inflates ρ and is worthless to judges. A v2 revision is only legitimate if
the justification stands on the **evidence itself**, would have been made
even if ρ had moved the other way, and is written down before the h2 eval
runs. The ρ figures below are predicted consequences, NOT arguments.

## Case 1 — blog-rest-api (expert 6th vs h1 9th)

h1's harsher score rests on three evidence-cited findings:

- **Undeclared MySQL** (`surefire-summary.txt`, `test.log`): the only test
  (`contextLoads`) fails — the app cannot boot or test out of the box; no
  docker-compose, no Testcontainers, no H2 test scope. README setup steps
  don't mention MySQL.
- **Committed secrets** (`repo-scan.txt`): a real JWT secret plus DB
  passwords in four `application*.properties` files.
- **Test depth**: 1 test file, 13 LOC, 0 assertions.

The expert's v1 justification already says "terrible repo hygiene drags it
down" — the dispute is magnitude, not facts. The strongest argument for
revision is the **expert's own stated principle**, applied consistently: for
petclinic-degraded the expert ruled "a repo whose tests fail is
untrustworthy and ranks below an honest minimal project that is green."
blog-rest-api's tests also fail out of the box, and it additionally commits
secrets — which gs-rest-service-complete (8th, green, honest) does not.

Also relevant: blog-rest-api cannot be load-tested without an undeclared
MySQL, so h2 will likely score its Runtime = 0 with the designed
"could not generate a valid load scenario" note — independent evidence
arriving in h2 either way.

## Case 2 — petclinic-degraded (expert 9th vs h1 5–7th)

h1's kinder score rests on evidence-cited facts: 74/76 tests pass (only the
injected `ClinicServiceTests` failures remain after re-collection),
petclinic-grade architecture (18/20), current dependencies (14/15).

The expert's 9th rests on a **stated value principle** (red build =
untrustworthy, below honest-minimal-green) plus **design intent**: the
expert created this fork as a synthetic bottom. Design intent is not a code
property — no analyzer can see it, so an analyzer "missing" it is not an
analyzer failure. Note the forward risk: degraded boots and behaves like
petclinic, so h2/h3 runtime evidence may push it UP further and widen this
discordance. That was the original v2-policy trigger ("if h3 runtime
evidence contradicts v1, revise with justification") — this ruling may need
revisiting after h2.

## Options and predicted ρ (computed 2026-08-29, h1 scores, avg-rank ties)

| Option | Ruling | Predicted h1 ρ |
|--------|--------|----------------|
| Keep v1 | Note both discordances as explained (blog: expert underweighted secrets/undeclared dep; degraded: design intent + red-build principle) | 0.865 (unchanged) |
| A | blog 6th → 9th (below degraded); degraded unchanged | 0.951 |
| B | degraded 9th → 6th; blog unchanged | 0.926 |
| C | both revisions | 0.976 |

A revision here makes ρ **less** honest as a headline if taken alone — the
pair-check and per-repo table must accompany it as usual.

## Ruling (human, 2026-08-29)

- Decision: **blog-rest-api → 10th (last); petclinic-degraded KEPT at its
  v1 relative position (8th in v2) with an intentional-degradation note.**
  This matches none of A/B/C exactly — the expert moved blog below
  spring-mvc-showcase as well ("passive obsolescence ranks above active
  untrustworthiness").
- Justification (on the evidence, not the ρ): blog's out-of-the-box test
  failure (undeclared MySQL), committed JWT secret + DB passwords, and
  zero-assertion test suite are verified repo facts; the revision applies
  the expert's own red-build principle consistently. petclinic-degraded's
  failures are intentionally injected by the expert (synthetic bottom) —
  design intent is not a code property and no analyzer can see it, so the
  expert's placement is kept and the context is documented instead of
  revising. Full text: `evidence/expert-ranking-notes.md` (v2 section).
- Date: 2026-08-29
- Action taken: `service/eval/expert-ranking.txt` updated to v2; h1 scores
  re-evaluated against v2 (same committed score sheets, no re-scoring) →
  `evidence/eval/h1-v2/`. Official headline:
  **ρ = 0.939** (n=10), tie bounds [0.894, 0.965], pairs 39 concordant /
  3 discordant / 3 unjudged (was 0.865, [0.835, 0.929], 37/5/3 against
  v1). Remaining discordance: petclinic-degraded (h1 6th-tied vs expert
  8th — intentional-degradation note applies) and the blog/showcase swap
  (h1 9th/10th vs expert 10th/9th).
- Predicted ρ for the exact v2 order (avg-rank estimate, computed before
  the ruling was applied): 0.939.
