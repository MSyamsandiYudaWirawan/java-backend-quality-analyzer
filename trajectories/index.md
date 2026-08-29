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
