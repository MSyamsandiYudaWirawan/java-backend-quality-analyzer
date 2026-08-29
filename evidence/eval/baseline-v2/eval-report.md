# Eval Report: baseline-v2

- Targets: service/targets.txt
- Expert ranking: service/eval/expert-ranking.txt
- Comparable repos: 10 of 10

| Repo | Score | Analyzer rank | Expert rank | Note |
|------|-------|---------------|-------------|------|
| spring-petclinic | 100 | 1.5 | 1 | reused from previous run (--resume) |
| REST-With-Spring-module6 | 100 | 1.5 | 3 | reused from previous run (--resume) |
| practice-mvc | 90 | 5.0 | 6 | reused from previous run (--resume) |
| practice-mvc-caffeine | 90 | 5.0 | 5 | reused from previous run (--resume) |
| practice-webflux | 90 | 5.0 | 4 | reused from previous run (--resume) |
| practice-webflux-redis | 90 | 5.0 | 2 | reused from previous run (--resume) |
| gs-rest-service-complete | 90 | 5.0 | 7 | reused from previous run (--resume) |
| springboot-blog-rest-api | 65 | 8.0 | 10 | reused from previous run (--resume) |
| petclinic-degraded | 55 | 9.0 | 8 | reused from previous run (--resume) |
| spring-mvc-showcase | 40 | 10.0 | 9 | reused from previous run (--resume) |

**Spearman rho vs expert ranking: 0.850** (n=10) — NOT ROBUST: tie-sensitive, range [0.552, 0.867], 24% of pairs unjudged

Tie check: 7 of 10 scored repos sit in 2 tie group(s); within a tie the analyzer carries no ordering information. If every tie broke luckily/unluckily, rho would be in [0.552, 0.867].

Pair check: of 45 repo pairs, 31 concordant, 3 discordant, 11 tied by the analyzer (no ordering opinion).
