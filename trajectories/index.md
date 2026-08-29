# Trajectory Index

| # | Date | File | Topic | Tool | Key Decision |
|---|------|------|-------|------|--------------|
| 1 | 2026-08-26 | `kimi-cli/EXAMPLE-2026-08-26_dry-run.md` | Dry-run scaffold | Kimi Code CLI (k3-high) | Established MVC + JPA baseline structure |
| 2 | 2026-08-27 | *(CLI session)* | RedisConfig fix + reactive scaffold | Kimi Code CLI (k3-high) | Switched from `GenericJackson2JsonRedisSerializer` (deprecated) to Jackson 3 `GenericJacksonJsonRedisSerializer` builder with `enableDefaultTyping()` |
| 3 | 2026-08-27 | *(CLI session)* | Experiment H4 analysis + submission packaging | Kimi Code CLI (k3-high) | Filled H4 report with actual k6/JFR data; wrote IMPROVEMENTS.md, README.md, REPRODUCTION.md |
| 4 | 2026-08-28 | `kimi-cli/2026-08-28_22-59-baseline-analyzer-scaffold.md` | Baseline analyzer scaffold + template reframe | Kimi Code CLI (kimi-k2) | Bash script as naive control; experiment metric reframed from throughput to ranking correlation (Spearman ρ) over a fixed eval set |
| 5 | 2026-08-28 | `kimi-cli/2026-08-28_23-32-rubric-eval-harness.md` | Quality rubric + Python eval harness | Kimi Code CLI (kimi-k2) | Rubric as shared expert/agent contract; stdlib-only harness; smoke test caught Windows path-mangling bug before real eval |
| 6 | 2026-08-29 | `kimi-cli/2026-08-29_06-37-eval-set-design.md` | Eval-set design: k6 generation policy, controlled repos, scope limits | Kimi Code CLI (kimi-k2) | Determinism in the committed artifact, not the authoring; 4 controlled repos as method-validation set; multi-service scoped out as documented limitation |
| 7 | 2026-08-29 | `kimi-cli/2026-08-29_09-59-controlled-repos-import.md` | Controlled practice repos import + baseline blindness check | Kimi Code CLI (kimi-k2) | Local gitignored clones under `targets/`; baseline ties all four at 90/100 (blindness confirmed); MVC test failures traced to undeclared localhost Postgres, not repo defects |
| 8 | 2026-08-29 | `kimi-cli/2026-08-29_10-20-public-target-validation.md` | Public target validation + eval set finalization | Kimi Code CLI (kimi-k2) | 10-repo set fixed; non-root-buildable repos (gs-rest-service, REST-With-Spring) imported as pinned local clones; spring-mvc-showcase kept as fail-fast legacy anchor |
| 9 | 2026-08-29 | `kimi-cli/2026-08-29_11-37-expert-ranking-baseline-rho.md` | Expert ranking v1 + baseline ρ headline | Kimi Code CLI (kimi-k2) | Expert grades structure-only except practice repos (runtime-measured), with pre-authorized v2 revision path; baseline ρ = 0.811 with 5-way tie at 90; URL-mangling harness bug fixed; ρ swings ±0.3 from one stray Docker container |
| 10 | 2026-08-29 | `kimi-cli/2026-08-29_11-55-h1-design-closeout.md` | h1 design decision + Day 2 close-out | Kimi Code CLI (kimi-k2) | h1 = Option A (agent judgment, committed score sheets, uniform Runtime=0); h2 redefined as generate+run+report; high-RPS-with-critical-hotspot scores lower in h3 |
| 11 | 2026-08-29 | `kimi-cli/2026-08-29_05-43-h1-implementation-kept.md` | h1 implementation: collector, blind scoring, tie-aware harness, KEPT | Kimi Code CLI (kimi-k2) | h1 ρ = 0.865 vs baseline 0.811; custom weighted ρ rejected in favor of standard ρ + tie bounds + pair counts; port-5432 env incident reproduced and attributed; v2 ranking-revision decision parked for human |
| 12 | 2026-08-29 | `kimi-cli/2026-08-29_14-20-v2-ruling-h2-tooling.md` | Expert-ranking v2 ruling + h2 tooling (k6 generation + pipeline re-point) | Kimi Code CLI (kimi-k2) | blog-rest-api to 10th/0-pts on verified committed JWT secret (ρ vs v2 = 0.939); docker-limited runs are the official path; template+slots generation standalone; infra split into `service/advanced/docker/h2-*.yml` after 4 design reversals |
| 13 | 2026-08-29 | `kimi-cli/2026-08-29_15-02-h2-slots-generation.md` | h2 slots generation for 8 repos + webflux-redis bug claim refuted live | Kimi Code CLI (kimi-k2) | Subagent's webflux-redis null-id claim refuted by live test (human pushback caught it — stale local DB table was the real 500 cause); form-variant template for petclinic chosen over Runtime-0 (ρ math: blanket-0 drops est. ρ to 0.55–0.65 < baseline); jarGlob slot pins module6's boot jar |
| 14 | 2026-08-29 | `kimi-cli/2026-08-29_16-30-h2-measured-runs.md` | h2 measured runs: dual 50/200-VU profile, petclinic collapse, blog boot-crash root cause | Kimi Code CLI (kimi-k2) | Sequential over parallel (envelope fairness = the port-5432 lesson); 200-VU re-profile before any evidence committed (50 VU = vacuous thresholds); 50-VU reports preserved for dual-profile scoring; blog Runtime 0 with root-cause evidence (MySQL 8.4 public-key boot crash), no workarounds |
| 15 | 2026-08-29 | `kimi-cli/2026-08-29_16-19-h2-blind-scoring-kept.md` | h2 blind Runtime scoring + eval — KEPT (ρ = 0.954) | Kimi Code CLI (kimi-k2) | Blind scoring from load reports only (expert ranking untouched until harness); JFR item 0-for-all so h3 can't distort ρ; full latency credit only for PASS at both profiles; NOT_TESTABLE = Runtime 0 by pre-committed policy even for bootable gs-rest; controlled-repo ordering recovered exactly |
| 16 | 2026-08-29 | `kimi-cli/2026-08-29_17-10-h3-jfr-tooling.md` | h3 tooling: --jfr pipeline, three failure rounds, petclinic lock-contention evidence | Kimi Code CLI (kimi-k2) | In-memory JFR + dumponexit over disk=true (chunk writes fail on Windows bind mount — human's template recipe beat agent's docker-cp workaround); MSYS_NO_PATHCONV on ALL compose calls (4th path-mangling instance, first on `up`); h2 inputs immutable, h3 outputs isolated; petclinic collapse explained: 71k monitor waits on fat-jar classloader lock |
| 17 | 2026-08-29 | `kimi-cli/2026-08-29_17-45-h3-scoring-kept.md` | h3 measured runs, blind JFR scoring, eval — KEPT (ρ = 0.973) | Kimi Code CLI (kimi-k2) | Uniform 0–10 JFR rubric pre-registered then applied blind (diagnose severity labels rejected as scores — count × duration on request path instead); module6 k6-PASS held to a tie by its critical JFR signal (grading rule applied against k6 verdict); cp1252 json.dump corruption caught by harness, re-scored utf-8; 4/4 pre-registered predictions confirmed |
| 18 | 2026-08-29 | `kimi-cli/2026-08-29_18-30-packaging-advanced.md` | Packaging: advanced branch, 4-stage eval table, all docs filled | Kimi Code CLI (kimi-k2) | advanced = h3 tip (chained KEPT branches fast-forward); baseline re-ranked vs v2 from COMMITTED scores only (--skip-build re-run caught producing wrong 40/30 scores — no new measurement); README eval set corrected to targets.txt reality; every REPRODUCTION command verified before commit |

---

## Legend

- **Tool**: `kimi-cli` (Kimi Code CLI), `cursor`, `claude-code`, `chatgpt`, `deepseek`, etc.
- **Key Decision**: One-line summary of the most important choice made in that session.

## Other Tools Used (micro queries, quick lookups)

The rules require disclosing **every agent/tool used**, but "representative" trajectories are sufficient. For micro questions that did not produce meaningful code changes, summarize below. For any tool that wrote or shaped significant solution code, save a dedicated trajectory entry above.

### Template — fill during the event

```markdown
| Tool | Count | Purpose | Led to code change? | Notes |
|------|-------|---------|---------------------|-------|
| ChatGPT (web) | ~5 | API syntax, Redis config tweaks | No | Summarized below |
| DeepSeek (web) | ~2 | JFR event interpretation | No | Summarized below |
| kimi-for-coding-highspeed (separate terminal) | ~3 | Micro debugging, quick refactors | Yes (H2) | See entry #4 above |
```

### Summaries (copy-paste or describe)

**ChatGPT — Redis Serializer Fix**
- Prompt: "`GenericJacksonJsonRedisSerializer` no-arg constructor missing in Spring Data Redis 4.1.1"
- Answer: Use builder pattern with `new GenericJacksonJsonRedisSerializer(ObjectMapper)`
- Outcome: No direct code change — confirmed what k3-high subagent already suggested.

**DeepSeek — JFR Thread Dump Reading**
- Prompt: "What does `jdk.ThreadSleep` > 30% in JFR mean for a Spring app?"
- Answer: Likely synchronous blocking on external I/O; consider async migration.
- Outcome: Reinforced H3 hypothesis (reactive migration); not a new insight.

> **Rule:** If a micro query leads to a meaningful code change, upgrade it to a full trajectory entry in the table above with date, file, and key decision.

---

## Folder structure

```
trajectories/
├── kimi-cli/
│   ├── 2026-08-28_09-00-scaffold-baseline.md
│   ├── 2026-08-28_14-30-implement-saga.md
│   ├── 2026-08-29_10-00-chaos-test.md
│   └── debug-20260828.zip       # diagnostic ZIP for tool traces
├── README.md
└── index.md
```

> **Note on CLI sessions:** Kimi Code CLI sessions are auto-saved under `~/.kimi-code/sessions/`. Export them with `/export-md trajectories/kimi-cli/YYYY-MM-DD_HH-MM-{topic}.md` during the session, or with `kimi export <sessionId>` from your shell after the session ends.
