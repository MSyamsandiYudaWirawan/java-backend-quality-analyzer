# Experiment h1 — rubric scoring by agent judgment

> Status: **hypothesis pre-registered** (written after evidence collection,
> before any repo was scored). Harness numbers and verdict are filled in
> after the eval run. Scoring is done blind: the agent reads only the
> collected evidence, never `service/eval/expert-ranking.txt`.

## Hypothesis

An agent that reads mechanically-collected evidence (build/test logs, test
census, package tree, dependency analysis, repo scan) and scores the shared
rubric (`service/rubric/quality-rubric.md`) with per-item citations will
rank the 10-repo eval set **closer to the expert ranking than the baseline
analyzer does** (baseline ρ = 0.811, `evidence/eval/baseline/`).

Mechanism: the baseline's ρ is carried by 3 anchors while 5 repos tie at
90/100 spanning expert ranks 2–8. Agent judgment on Architecture,
Dependencies, and Maintainability — dimensions a shell script cannot see —
should break that tie and put those 5 repos in a defensible order.

## Design (DECIDED Day 2, Option A)

- Branch: `exp/h1-rubric-scoring`
- `service/advanced/collect.sh` — mechanical collector, facts only, no
  judgments. Per repo: build/test logs, surefire summary, test census
  (files/LOC/assertions), package tree, top-20 classes by LOC,
  `dependency:analyze` + `dependency:list`, repo scan
  (README/license/config/binaries/secrets).
- Agent scores each repo against the rubric; per-item citations point at
  the collected evidence files. Score sheets committed as
  `evidence/advanced/h1/<repo>/score-sheet.json`.
- `service/advanced/analyze-h1.sh` — thin harness wrapper: maps target →
  repo name (same rule as `evaluate.py`), validates the committed sheet,
  emits `h1-score.json`. No re-scoring at eval time → reproducible.
- **Runtime dimension scores 0 for ALL repos** (uniform "not yet measured"
  rule) so the missing capability cannot distort ρ.

## Explicit pre-registration of what would falsify it

- KEPT if h1 ρ > baseline ρ (0.811) **and** the 5-way tie at 90 is broken
  into an order defensible from the cited evidence.
- MIXED if ρ improves only via the anchors while the tie repos stay
  scrambled — would mean judgment adds noise, not signal.
- REJECTED if ρ ≤ 0.811 or the tie order contradicts evidence.

## Environment record (fill in at eval time)

- Collection ran 2026-08-29 ~05:00–05:14 UTC with `practice-postgres`
  UP (needed by practice-mvc / mvc-caffeine tests).
- KNOWN SENSITIVITY CONFIRMED: with the container up, spring-petclinic's
  `PostgresIntegrationTests` failed (port 5432 conflict) — the Day-2
  incident reproduced. spring-petclinic and petclinic-degraded were
  RE-COLLECTED with the container stopped: petclinic went fully green
  (76/76); degraded kept only its genuine injected failures
  (ClinicServiceTests 1 failure + 1 error). The container was left
  STOPPED after collection.
- Collector bug found and fixed during the run: `mvn -B -q` suppresses
  dependency-plugin output, leaving empty `dependency-analyze.log` /
  `dependency-list.txt`. Fixed in `collect.sh` (dependency goals run
  without `-q`); dep evidence re-collected for all build-pass repos.
- Collector limitation (documented, not fixed): the assertion census
  regex misses MockMvc `andExpect` / WebTestClient `expectBody` chains —
  gs-rest-service-complete and spring-mvc-showcase show 0 "assertions"
  that are not really 0. Noted in the affected score sheets.

## Harness numbers

Run: `python service/eval/evaluate.py --label h1 --analyzer "bash service/advanced/analyze-h1.sh {target} --out {out}" ...`
(full artifacts: `evidence/eval/h1/`, score sheets: `evidence/advanced/h1/*/score-sheet.json`)

| Repo | h1 score | h1 rank | Expert rank | Baseline score |
|------|----------|---------|-------------|----------------|
| spring-petclinic | 72 | 1 | 1 | 100 |
| REST-With-Spring-module6 | 63 | 2 | 3 | 100 |
| practice-webflux-redis | 57 | 3 | 2 | 90 |
| practice-webflux | 56 | 4 | 4 | 90 |
| practice-mvc | 55 | 6 | 7 | 90 |
| practice-mvc-caffeine | 55 | 6 | 5 | 90 |
| petclinic-degraded | 55 | 6 | 9 | 55 |
| gs-rest-service-complete | 50 | 8 | 8 | 90 |
| springboot-blog-rest-api | 42 | 9 | 6 | 65 |
| spring-mvc-showcase | 26 | 10 | 10 | 40 |

- **ρ = 0.865** (baseline 0.811). Tie bounds [0.835, 0.929] — tight,
  vs baseline's [0.527, 0.915].
- Pair check: 37 concordant / 5 discordant / 3 unjudged (baseline:
  31 / 3 / 11). The 90-tie is broken: the 5 repos the baseline tied
  now span 50–63 with per-item citations.
- The 3-way tie at 55 (mvc, caffeine, degraded) is honest: the two
  practice variants are structurally near-identical, and degraded is
  literally petclinic-minus-README-minus-passing-tests. Their real
  differences are runtime behavior — out of h1 scope by design.

## Verdict: **KEPT**

Pre-registered criteria: ρ > 0.811 ✓ (0.865); 90-tie broken into an
evidence-defensible order ✓ (every score cites collector artifacts).

Honest caveats:

- The ρ gain (+0.054) is modest at n=10 and sits inside the baseline's
  own luck envelope — the strong claim is NOT the headline number but
  the pair check (11 → 3 unjudged pairs) and the tight tie bounds.
- 5 discordant pairs concentrate on two repos: blog-rest-api (h1: 9th,
  expert: 6th — h1 punishes the genuine undeclared-MySQL test failure +
  committed JWT secret harder than the expert did) and petclinic-degraded
  (h1: 5–7th, expert: 9th — h1 credits its petclinic-grade architecture;
  the synthetic-bottom design intent is a ranking choice, not a code
  property). **This triggers the v2 ranking-revision policy**: the human
  decides whether to revise the expert ranking with justification or
  keep v1. That call is recorded before h2 starts.
- Runtime is 0 everywhere, so 25 rubric points are still dark. h2
  (k6 generation) is where the practice-repo ordering gets tested.
