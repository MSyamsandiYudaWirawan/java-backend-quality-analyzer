# Eval Report: h3

- Targets: service/targets.txt
- Expert ranking: service/eval/expert-ranking.txt
- Comparable repos: 10 of 10

| Repo | Score | Analyzer rank | Expert rank | Note |
|------|-------|---------------|-------------|------|
| spring-petclinic | 84 | 1.0 | 1 | reused from previous run (--resume) |
| practice-webflux-redis | 82 | 2.5 | 2 | reused from previous run (--resume) |
| REST-With-Spring-module6 | 82 | 2.5 | 3 | reused from previous run (--resume) |
| practice-webflux | 81 | 4.0 | 4 | reused from previous run (--resume) |
| practice-mvc-caffeine | 76 | 5.0 | 5 | reused from previous run (--resume) |
| practice-mvc | 69 | 6.0 | 6 | reused from previous run (--resume) |
| petclinic-degraded | 67 | 7.0 | 8 | reused from previous run (--resume) |
| gs-rest-service-complete | 50 | 8.0 | 7 | reused from previous run (--resume) |
| springboot-blog-rest-api | 42 | 9.0 | 10 | reused from previous run (--resume) |
| spring-mvc-showcase | 26 | 10.0 | 9 | reused from previous run (--resume) |

**Spearman rho vs expert ranking: 0.973** (n=10)

Tie check: 2 of 10 scored repos sit in 1 tie group(s); within a tie the analyzer carries no ordering information. If every tie broke luckily/unluckily, rho would be in [0.964, 0.976].

Pair check: of 45 repo pairs, 42 concordant, 2 discordant, 1 tied by the analyzer (no ordering opinion).
