# Expert Ranking Notes — audit trail for the ground-truth ranking

One section per repo: score + justification.
This file is what makes `service/eval/expert-ranking.txt` defensible to
judges. Rubric: `service/rubric/quality-rubric.md`.

Date of session: 2026-08-29  ·  Expert: repo owner (MSyamsandiYudaWirawan)

**Ranking basis policy (agreed Day 2):** v1 is graded on structure, pom.xml,
collected build/test facts, and — for the 4 practice repos ONLY — the
expert's measured runtime knowledge (they are the method-validation set;
their ordering must come from measurement, not structure). Repos where
Runtime was not measured say so in the justification. If h3 runtime evidence
(JFR/k6) later contradicts v1, the correct response is a documented v2
revision of `expert-ranking.txt` + re-run of the eval against v2 — never
treating the resulting low ρ as an analyzer failure. Both versions and the
revision rationale are kept in this file.

**Grading granularity note:** v1 was graded holistically against the rubric
anchors (dimension-level subscores not itemized). Totals below are the
expert's rubric-guided scores out of 100.

---

## v1 ranking (2026-08-29)

### 1. spring-petclinic — 92/100
- Working reference standard. Full app, green tests, docs, infra, k8s.

### 2. practice-webflux-redis — 80/100
- The expert's best work. Built from scratch, modern reactive stack, Redis,
  Testcontainers, green tests. Runtime measured during practice.

### 3. REST-With-Spring-module6 — 78/100
- Professional courseware. Clean multi-module architecture, MapStruct,
  SpringDoc, solid patterns. (Runtime not measured — structural grading.)

### 4. practice-webflux — 76/100
- Same as #2 minus Redis. Still a genuinely good scratch-built reactive
  project. Runtime measured during practice.

### 5. practice-mvc-caffeine — 72/100
- MVC + caching + JMH benchmarks. Shows performance awareness. Working tests.
  Runtime measured during practice.

### 6. springboot-blog-rest-api — 65/100
- Real features (JWT auth, OpenAPI, full CRUD), but terrible repo hygiene
  drags it down. (Runtime not measured — structural grading.)

### 7. practice-mvc — 62/100
- Simple but solid. Green tests, Testcontainers, modern Spring Boot 4.1.1.
  No frills, no lies. Runtime measured during practice.

### 8. gs-rest-service-complete — 50/100
- Minimal guide. Clean, green, but barely an application.

### 9. petclinic-degraded — 30/100
- Inherited great structure, but broken tests (deliberately, by the expert) =
  red build = untrustworthy. A broken fork is worse than a simple green
  project.
- Ranked below #8 on the expert's stated principle: a repo whose tests fail
  is untrustworthy and ranks below an honest minimal project that is green.
  (Initially tied at 50; the expert then re-scored degraded to 30, making the
  principle explicit in points as well as order.)

### 10. spring-mvc-showcase — 15/100
- Legacy museum piece. Pre-Boot, Java 1.8, JUnit 4. Fails to build on
  Java 21 (javax.xml.bind). Historical value only.

---

## v2 revisions (post-h1 evidence, 2026-08-29)

Ruled by the human expert after reviewing the h1 blind-scoring discordances
(decision memo: `evidence/experiments/expert-ranking-v2-decision.md`).
One revision, one keep-with-note.

### REVISED: springboot-blog-rest-api — 6th → 10th (last)

Justification (evidence, verified in `evidence/advanced/h1/springboot-blog-rest-api/`):

- **Undeclared MySQL requirement, proven:** the only test (`contextLoads`)
  fails out of the box with `CommunicationsException` — the repo declares
  the mysql-connector *driver* and hardcodes datasource URLs/credentials,
  but provides no way to obtain a MySQL server (no docker-compose, no
  Testcontainers, no H2 test scope) and the README never mentions one.
- **Committed secrets, verbatim:** a real JWT secret at
  `application.properties:11` plus DB passwords in all four
  `application*.properties` files.
- **No meaningful tests:** 1 test file, 13 LOC, 0 assertions.

The revision applies the expert's own v1 principle consistently: "a repo
whose tests fail is untrustworthy and ranks below an honest minimal project
that is green." blog's tests fail AND it commits secrets AND it documents
nothing — so it ranks below gs-rest-service-complete, below
petclinic-degraded, and below spring-mvc-showcase: showcase fails to build
on a modern JDK but is an honest legacy artifact with historical value;
blog builds but is actively untrustworthy out of the box. Passive
obsolescence ranks above active untrustworthiness.

### KEPT WITH NOTE: petclinic-degraded — stays at its v1 relative position (8th in v2)

**Intentional-degradation context (the note):** petclinic-degraded is a
fork of spring-petclinic created by the expert with **deliberately injected
breakage** — the `ClinicServiceTests` failures (1 failure + 1 error of 76)
and the removed README are sabotage, not accidents. It was designed as a
synthetic bottom for the eval set. That design intent is **not a code
property**: it exists only in the expert's knowledge, and no analyzer —
however good — can see it. An analyzer scoring it mid-pack on visible
evidence (petclinic-grade architecture, current dependencies, 74/76 tests
passing) is not wrong about the code; it is blind to the intent by
construction.

The expert keeps it below the green, honest projects on the stated
principle (red build = untrustworthy), and credits it above showcase and
blog because its underlying code is genuinely petclinic-grade and its
failures are narrow. Forward risk, recorded: degraded boots and behaves
like petclinic under load, so h2/h3 runtime evidence may legitimately push
it UP — if that happens the correct response is this same policy (revise
with justification or keep with note), never blaming ρ on the analyzer.

### v2 ranking (2026-08-29) — now the ground truth in `expert-ranking.txt`

1. spring-petclinic (92)
2. practice-webflux-redis (80)
3. REST-With-Spring-module6 (78)
4. practice-webflux (76)
5. practice-mvc-caffeine (72)
6. practice-mvc (62)
7. gs-rest-service-complete (50)
8. petclinic-degraded (30 — kept, see note above)
9. spring-mvc-showcase (15)
10. springboot-blog-rest-api — **0/100** (revised down from 65). Zeroed on
    a single unforgivable violation: a real JWT secret committed in plain
    text (`application.properties:11`), with DB passwords in all four
    profile files on top. The expert's ruling: a committed signing secret
    compromises every token the service ever issued — no amount of working
    features offsets it. Score 0 is a statement about trust, not a rubric
    sum. (Untrustworthy out of the box via the undeclared-MySQL test
    failure independently justifies last place.)

### Re-run eval against v2

- h1 scores re-evaluated against v2 (same committed score sheets, no
  re-scoring): `evidence/eval/h1-v2/`. Headline numbers recorded in
  `evidence/experiments/expert-ranking-v2-decision.md`.
