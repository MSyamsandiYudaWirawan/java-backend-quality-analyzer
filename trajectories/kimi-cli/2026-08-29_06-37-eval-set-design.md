# Session: Eval-set design — k6 generation policy, controlled repos, scope limits

- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k3
- Branch: `baseline`
- Human Checkpoint: yes (human explicitly opened with "DONT WRITE ANYTHING
  FIRST, I just want to discuss" — design was settled in conversation before
  any file was touched)

---

## Prompt Given

Three purposeful prompts shaped this session:

1. **Pipeline limitations + the controlled-repos reveal.** The human laid out
   a real problem: `run-experiment.sh` needs a k6 load test, Dockerfile, and
   compose setup per target — but arbitrary third-party repos have no k6
   tests, and even when they do, their quality can't be vouched for ("is the
   scenario just fetching a single product a million times?"). The pipeline
   also tests only a single service, not multi-service/Kafka/outbox
   architectures. Then the good news: the human has 4 practice repos from
   pipeline testing — the same product create/get-by-id service as MVC,
   MVC+Redis, WebFlux, and WebFlux+Redis. Question: "How to generate k6 load
   tests — can asking AI with the same prompt make it reproducible and
   deterministic enough?"
2. **"Scope out multi-service. Update `prompts/README.md` so next session
   when I tell AI to read this README it should know everything — goal,
   current progress, etc."**
3. **"Any idea for the remaining 6 repos — should I create or get from
   public?"**

## Key Decisions Made

- **Determinism lives in the artifact, not the authoring.** AI-generated k6
  scripts do not need to be bit-identical across regenerations; they need to
  produce reproducible *measurements*. So: generated scripts are committed
  per repo as evidence, re-runs never regenerate, and generation is
  constrained to a fixed template + slots (base URL, endpoints, payloads,
  checks) with one fixed load profile (VUs/duration/ramp) across all repos —
  cross-repo comparability comes from the fixed profile, not from the LLM.
- **Quality of generated tests is vouched by validation, not trust.** A
  smoke gate: the generated script must pass a short run (setup succeeds,
  response checks pass) before acceptance. The scenario standard (mixed
  create→read from the real API surface — OpenAPI/springdoc if present,
  controllers otherwise) is defined once and applied everywhere, answering
  the "single product fetched a million times" concern.
- **Multi-service is scoped out as a *documented* limitation.** The pipeline
  measures one deployable unit (the service or its gateway). Kafka/outbox/
  microservice internals get static signals only, and reports state the
  boundary plainly. Rationale: an honest edge beats a fragile half-working
  multi-service harness built under deadline — and "runtime evidence is
  bounded by deployability" is a defensible hot-take candidate.
- **The 4 controlled repos are the method-validation set.** Their quality
  ordering is already known (runtime-measured during pipeline practice), so
  if the advanced agent recovers that ordering blind, the method itself is
  validated — something no public repo can prove. Bonus: all four score
  ~100/100 on the baseline despite wildly different runtime behavior, which
  is the baseline-blindness demonstration for the video.
- **Eval set composition: 4 controlled + 5 public + 1 synthetic degraded.**
  Remaining slots go mostly public (credibility/generalization; an
  all-self-made set invites "did you tune the eval?"), plus one degraded
  petclinic fork as a known-correct bottom anchor. Candidates: petclinic
  (public good), gs-rest-service (weak-minimal, boots without DB),
  RameshMF/springboot-blog-rest-api (average, needs MySQL → exercises
  Testcontainers), spring-mvc-showcase (legacy/archived),
  iluwatar/java-design-patterns (library edge case → triggers the Runtime=0
  rule). `eugenp/tutorials` dropped: multi-hour build, tier already covered.
  All public candidates must pass a validation gate (clones, builds on
  Java 21 < ~10 min, license OK, boots as a service — or is deliberately the
  library case); drops are recorded in `targets.txt` as eval-hygiene evidence.
- **k6 generation becomes its own experiment (`exp/h3-k6-generation`)** with
  a built-in success criterion: generated tests must recover the known
  ordering of the 4 controlled repos. If they do, the method is proven; if
  not, it's an honest REJECTED entry.

## Agent Output Summary

- Rewrote `prompts/README.md` as the session-onboarding brief: problem,
  metric, current state (commits, tests, environment gotchas), ordered Day 2
  plan, k6 generation policy, working agreements (curated trajectories, git
  confirmation, evidence-linked claims), scoring reality check, and a
  current-vs-legacy map of the template files.
- Added **Scope & Limitations** to `README.md` (single deployable unit;
  deployability-bounded runtime evidence; agent-generated-then-frozen load
  scenarios), worded consistently with the rubric and the onboarding brief.
- No code changes; no new tests needed (docs only).

## Human Checkpoint

- Reviewed before accepting: yes — the entire design was settled in
  discussion first at the human's explicit request; only then were the two
  markdown files written.
- The human chose the scope-out and the eval-set composition; the agent's
  role was analysis and writing.
- Pending at session end: human to provide the location of the 4 practice
  repos for import; commit of this session's doc changes.

## Retries / Corrections

- None this session — design discussion only, no code paths exercised.
