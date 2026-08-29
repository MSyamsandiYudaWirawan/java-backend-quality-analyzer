# Eval Report: baseline

- Targets: service/targets.txt
- Expert ranking: service/eval/expert-ranking.txt
- Comparable repos: 10 of 10

| Repo | Score | Analyzer rank | Expert rank | Note |
|------|-------|---------------|-------------|------|
| spring-petclinic | 100 | 1.5 | 1 | reused from previous run (--resume) |
| REST-With-Spring-module6 | 100 | 1.5 | 3 | reused from previous run (--resume) |
| practice-mvc | 90 | 5.0 | 7 | reused from previous run (--resume) |
| practice-mvc-caffeine | 90 | 5.0 | 5 | reused from previous run (--resume) |
| practice-webflux | 90 | 5.0 | 4 | reused from previous run (--resume) |
| practice-webflux-redis | 90 | 5.0 | 2 | reused from previous run (--resume) |
| gs-rest-service-complete | 90 | 5.0 | 8 | reused from previous run (--resume) |
| springboot-blog-rest-api | 65 | 8.0 | 6 | reused from previous run (--resume) |
| petclinic-degraded | 55 | 9.0 | 9 | reused from previous run (--resume) |
| spring-mvc-showcase | 40 | 10.0 | 10 | reused from previous run (--resume) |

**Spearman rho vs expert ranking: 0.811** (n=10)

Tie check: 7 of 10 scored repos sit in 2 tie group(s); within a tie the analyzer carries no ordering information. If every tie broke luckily/unluckily, rho would be in [0.527, 0.915].

Pair check: of 45 repo pairs, 31 concordant, 3 discordant, 11 tied by the analyzer (no ordering opinion).

---

## Analyst note (added post-run): 0.811 overstates the baseline

The tie/pair checks above are the substance: the baseline orders the
anchors (petclinic top; degraded/showcase bottom — deleted README/broken
tests, and a repo that does not compile) and is **silent on the middle** —
a 35-LOC tutorial skeleton (gs-rest-service-complete, expert #8) scores
identically to the expert's #2 repo (practice-webflux-redis).

Two independent luck estimates agree with the [0.527, 0.915] bound:

- Monte Carlo (20k runs, seed 42, harness's own spearman): if the 7 tied
  repos were forced into distinct scores in **random** order, ρ lands in
  0.564–0.952 (median 0.758); **P(ρ ≥ 0.811 by pure luck) ≈ 29%**.
- Day-2 environment incident: the same analyzer scored ρ = 0.493 when a
  stray Docker container held port 5432 during petclinic's tests — the
  statistic is fragile at n=10.

Breaking the 90-tie with evidence-based judgment is what h1 is measured
on. Never cite 0.811 without the tie and pair checks.
