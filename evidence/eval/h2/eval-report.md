# Eval Report: h2

- Targets: service/targets.txt
- Expert ranking: service/eval/expert-ranking.txt
- Comparable repos: 10 of 10

| Repo | Score | Analyzer rank | Expert rank | Note |
|------|-------|---------------|-------------|------|
| spring-petclinic | 82 | 1.0 | 1 | ok in 0s |
| REST-With-Spring-module6 | 78 | 2.0 | 3 | ok in 0s |
| practice-webflux-redis | 72 | 3.0 | 2 | ok in 0s |
| practice-webflux | 71 | 4.0 | 4 | ok in 0s |
| practice-mvc-caffeine | 70 | 5.0 | 5 | ok in 0s |
| practice-mvc | 65 | 6.5 | 6 | ok in 1s |
| petclinic-degraded | 65 | 6.5 | 8 | ok in 0s |
| gs-rest-service-complete | 50 | 8.0 | 7 | ok in 0s |
| springboot-blog-rest-api | 42 | 9.0 | 10 | ok in 0s |
| spring-mvc-showcase | 26 | 10.0 | 9 | ok in 0s |

**Spearman rho vs expert ranking: 0.954** (n=10)

Tie check: 2 of 10 scored repos sit in 1 tie group(s); within a tie the analyzer carries no ordering information. If every tie broke luckily/unluckily, rho would be in [0.939, 0.964].

Pair check: of 45 repo pairs, 41 concordant, 3 discordant, 1 tied by the analyzer (no ordering opinion).
