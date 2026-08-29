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

## v2 revisions (post-h3 runtime evidence)

*(empty — to be filled only if k6/JFR evidence contradicts v1, with
justification and the re-run eval results)*
