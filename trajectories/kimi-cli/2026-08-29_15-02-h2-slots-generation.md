# Session: h2 slots generation + webflux-redis bug claim refuted by live test
- Date: 2026-08-29
- Tool: Kimi Code CLI
- Model: kimi-k2
- Human Checkpoint: yes

## Prompt Given

"okay start with step 1" (README §3 NEXT: generate slots+scripts per repo by
inspecting the API surface, commit them, then the 10 measured docker runs).

Mid-task the human steered twice:
1. "if you cant test and fail in some service dont too much fighting into it,
   lets discuss first about can we lower the score for it"
2. "how is this possible are you sure because i should already test this"
   (challenging the agent's claim that practice-webflux-redis create returns
   id:null) → "find the issue i think i will need to fix this"

## Key Decisions Made

- **API-surface inspection delegated to 4 parallel explore subagents** (10 repos
  grouped by similarity). 3 subagents reported 6 repos as
  NOT_TESTABLE-BY-TEMPLATE — including a claim that practice-webflux-redis's
  create returns 201 with `id:null` (service returns the pre-persist entity).
- **Human challenged the webflux-redis claim; live test refuted it.** Booted
  the rebuilt jar against practice-postgres/practice-redis: first POST 500'd
  ("null value in column id") — root cause was a STALE `product` table in the
  long-lived container created without the `gen_random_uuid()` default;
  `CREATE TABLE IF NOT EXISTS` never upgrades it. Dropped the table, schema.sql
  recreated it correctly, POST then returned 201 with a real UUID, GET by id
  200 on both DB and Redis-cache paths. Spring Data R2DBC writes the
  DB-generated id back onto the same mutable entity instance, so
  `thenReturn(product)` is correct. **No code fix needed; webflux-redis stays
  testable.** Recorded as a minor finding instead: no schema migrations, stale
  tables break creates.
- **Testability map settled:** 5 cleanly testable (4 practice + module6),
  petclinic/degraded need a form variant, blog-rest-api runs into its own JWT
  wall at the smoke gate (finding by design), gs-rest/showcase get
  hand-recorded findings (no create endpoint / build fails — evidence already
  exists).
- **ρ-driven scoring decision (human-approved via options):** blanket Runtime=0
  for template-scope repos would cap petclinic (expert #1) at 72 and drop it to
  ~5th → est. ρ 0.55–0.65, below baseline 0.811. Human chose the small
  form-variant template over Runtime-0-frozen and rescale alternatives.
- **Form variant design:** separate `template-form.js` + `scenario` slot
  (json|form) in gen-k6.py rather than overloading the JSON template;
  identical load profile/thresholds/report shape, only the protocol binding
  differs (form POST → 302 → id from `Location` regex → HTML read).
- **module6 jar selection:** largest-jar heuristic picks the wrong module
  (url-changes-end 61.4MB, not resource-changes). Human approved `jarGlob`
  slot; unmatched glob is a finding (exit 3), never a silent fallback.
- **blog-rest-api slots authored anyway** so the pipeline itself produces the
  NOT_TESTABLE finding with fresh k6 evidence (401 on JWT-protected creates)
  instead of a hand-written note.

## Agent Output Summary

- Files created: `service/advanced/k6/template-form.js`; 8 ×
  `evidence/advanced/h2/<repo>/{slots.json,load-test.js}` (5 JSON practice/
  module6, 2 form petclinic, 1 JSON blog).
- Files modified: `service/advanced/gen-k6.py` (scenario + jarGlob slots),
  `run-experiment.sh` (jarGlob override + header docs).
- Tests added: +16 form-scenario +3 jarGlob (test_gen_k6.py → 31), +1
  unmatched-jarGlob exit-3 pipeline test (test-run-experiment.sh → 6).
  Full sanity suite green.
- Commits (human-approved, two): `bc9212f` tooling, `e401654` evidence.
- Bug found and root-caused in local env (stale practice-postgres table), not
  in any target.

## Human Checkpoint

- Human reviewed and approved every decision point via structured options:
  form-variant vs Runtime-0 vs rescale; webflux-redis handling (challenge led
  to live refutation); jarGlob vs re-import vs heuristic-as-is; two commits.
- No manual changes after agent output; human independently re-ran the
  webflux-redis unit tests in their ORIGINAL repo (C:\study\practice-webflux-redis)
  to cross-check the agent's claim — key reason the wrong static claim was
  caught before becoming a bogus "finding".

## Retries / Corrections

- **Subagent static-analysis claim was WRONG and the agent initially relayed it
  as fact** ("genuine API-contract bug in the #2 repo"). Human pushback ("i
  should already test this") triggered live verification, which refuted it and
  traced the real 500 to a stale local DB table. Lesson recorded: claims that a
  target's endpoint contract is broken must be verified against a running
  service before being reported as findings — the smoke gate exists for
  exactly this.
- First live verification attempt hit a stale container table (500); initial
  misread risked blaming the app. Corrected by inspecting the actual table DDL
  (`\d product` — no default) vs schema.sql (`DEFAULT gen_random_uuid()`).
- docker compose name conflict on practice-postgres (already existed, stopped);
  resolved by `docker start` of the existing containers instead of recreating.
