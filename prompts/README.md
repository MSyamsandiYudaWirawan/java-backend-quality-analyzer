# Agent Prompt Templates

Reference material for the hackathon workflow. These are **starting points** — adapt or ignore them as needed.

## My workflow

I write the code. The AI is a sparring partner, not a code generator. No end-to-end prompts.

```
implement baseline (MVC + JPA)  ← I do this
    ↓
JFR (baseline) → identify hotspots
    ↓
COMMIT baseline, tag it
    ↓
Macro-prompt AI: "Here's my JFR + k6. I think X is the bottleneck." → hypothesis
    ↓
CHECKOUT exp/<hypothesis> from baseline
    ↓
Implement experiment ← I do this (micro-prompt AI on stuck details)
    ↓
JFR / JMH / k6 — prove or reject
    ↓
CEILING EXPERIMENT — find where baseline collapses, run advanced at same load, push beyond
    ↓
SAVE TRAJECTORY ← AI MUST REMIND ME BEFORE ENDING ANY SESSION
    ↓
if KEEP: commit, find next hotspot → repeat
    ↓
last: branch `advanced`, merge last kept experiment
    ↓
FINALIZE: write IMPROVEMENTS.md, README.md, REPRODUCTION.md, trajectories
    ↓
Macro-prompt AI: "Review my evidence. What did I miss?"
```

> **AI HARD RULE:** Before ending any session, the AI MUST ask: "Did you save the trajectory? Run `./save-traj.sh '[current-branch-name]'` now." No exceptions. Trajectories are a scored rubric item.

---

## Event Rules (from micro1 post.txt)

These are non-negotiable. A submission that violates any of these may be disqualified before scoring.

### Required Solutions
- **Baseline + Advanced are both mandatory.** The advanced solution must show meaningful improvement in capability, reliability, efficiency, coverage, or engineering quality — not a cosmetic variation.
- **Coding-agent use is required.** Must disclose tools used and submit trajectories.
- **Make it clear what existed before the competition and what you added.**

### Data & Ethics
- Use public or synthetic data. Keep credentials and private information outside the submission.
- Choose a legal and ethical use case.
- Keep consequential actions controlled through a sandbox or simulation; add human approval.

### Evidence & Reproducibility
- **Connect every claim about results to submitted evidence.**
- **Give judges enough access to run the project and reproduce the main result.**
- A submission is scored only after passing eligibility, completeness, integrity, trace, and reproducibility checks.

### Submission Package (5 items)
1. **Complete solution code + Improvement Changelog** — every meaningful iteration, connected to evidence that guided the next decision. Main failure mode + hot take.
2. **README.md** — introduce intended user, explain bottleneck, why solving it is valuable.
3. **REPRODUCTION.md** — clean-environment setup, exact commands, required data, expected output, versions, runtime, cost.
4. **Solution video (up to 5 minutes)** — problem → baseline → one realistic execution → final comparison → explain changelog. Highlight the change that contributed most, and one experiment removed.
5. **Agent trajectories** — for every agent used. Show what the agent did, how tools responded, feedback that shaped next steps, retries, human checkpoints.

---

## Scoring & Tie-Break Order

Scored out of 100 by micro1's engineering team. **Qualification gate first** — a project that cannot be run or verified may be disqualified before rubric scoring.

Tie-break order (higher wins):
1. **Agent Solution & Engineering** ← optimize here first
2. **Reproducibility**
3. **Measured Improvement**
4. **End to End Quality**
5. Final panel review of documented evidence

**Implication:** Trajectory quality, clear evidence, and honest keep/reject decisions matter more than marginal benchmark gains.

---

## Ceiling Experiment

A benchmark that never stresses the baseline cannot distinguish architectural wins from noise.
Run these three stages in order before finalizing.

**Stage 1 — Find the baseline ceiling.**
Ramp VUs until RPS plateaus or p99 exceeds 500ms. That is `CEILING_VUS`.

```bash
VUS=150 DURATION=60s RAMP=10s ENTITY_COUNT=100 ./run-experiment.sh baseline --docker
VUS=200 DURATION=60s RAMP=10s ENTITY_COUNT=100 ./run-experiment.sh baseline --docker
VUS=300 DURATION=60s RAMP=10s ENTITY_COUNT=100 ./run-experiment.sh baseline --docker
```

JFR signal to confirm: `ThreadPark` on `HikariPool-1:connection-adder` or `HikariPool-1:housekeeper`, `SocketRead` p95 climbing.

**Stage 2 — Run advanced at the same ceiling load.**
Apples-to-apples. Same VUs, same duration, same entity spread.

```bash
VUS=<CEILING_VUS> DURATION=60s RAMP=10s ENTITY_COUNT=100 ./run-experiment.sh advanced --docker
```

JFR signal to confirm: `SocketRead` count = 0, `ThreadPark` count < 100, hottest frame in reactive pipeline.

**Stage 3 — Push advanced beyond the baseline ceiling.**
Find where the advanced stack saturates. This shows the headroom the architecture buys.

```bash
VUS=500 DURATION=90s RAMP=15s ENTITY_COUNT=100 ./run-experiment.sh advanced --docker
```


## How I prompt

| Type | When | Example |
|------|------|---------|
| **Micro** | Stuck on one specific thing | "`GenericJacksonJsonRedisSerializer` no-arg constructor is missing in Spring Data Redis 4.1.1. What's the right fix?" |
| **Macro** | Strategic decision, report review, blind spot check | "Here's my baseline JFR + 3 experiment branches. Which hypothesis has the strongest evidence? What should I try next?" |
| **None** | Straightforward code I can write faster than explaining | Scaffold, CRUD, wiring, config I already know |

## Template index

| File | What's inside |
|------|---------------|
| `01-scaffold-service.md` | **Baseline:** MVC + JPA + PostgreSQL — reference if I forget the exact pom.xml deps |
| `00-scaffold-reactive-service.md` | **Advanced:** WebFlux + R2DBC + Redis — reference for reactive migration experiments |
| `02-implement-cas-update.md` | Optimistic locking pattern |
| `03-idempotency-filter.md` | Deduplication / retry safety |
| `04-chaos-sigkill-test.md` | Crash recovery test |
| `05-outbox-publisher.md` | Dual-write safety |

## Rule

Use only what the problem requires. "Minimal" means **no unnecessary architecture theater** — not "stop optimizing."

- Baseline must pass tests first.
- **Every branch (baseline + every experiment + advanced) must have unit tests and integration tests.** Integration tests must use Testcontainers for Postgres (and Redis/Kafka if used). Do not skip this — "tests" is a required submission item.
- Then optimize based on **measured evidence** (JFR → hypothesis → experiment → keep/reject).
- Do NOT keep optimizing past the deadline. A clean submission with honest rejected experiments beats an unfinished advanced solution.

## Branches

| Branch | Purpose |
|--------|---------|
| `baseline` | First working solution. Tag this. |
| `exp/<hypothesis>` | One experiment per branch. Throw away if rejected. |
| `advanced` | Final improved solution. Merge last kept experiment here. |

> **When referencing an experiment stage in your report, point to the exact branch.** Judges can `git checkout exp/<name>` to reproduce that exact state and verify your numbers.

## Evidence folder

```
evidence/
├── experiments/
│   ├── h1-cache-warmup.md
│   ├── h2-connection-pool.md
│   └── ...
├── baseline.jfr
├── advanced.jfr
├── k6-baseline.json
└── k6-advanced.json
```

Every hypothesis gets a markdown file with:
- The observed hotspot (with JFR flame graph reference)
- The proposed change
- Benchmark result (before vs after)
- Keep or reject decision

## Finalize & Submit

After the last experiment is merged into `advanced`, stop optimizing and **package the submission**:

| Artifact | What to write | Where |
|----------|--------------|-------|
| **IMPROVEMENTS.md** | Changelog: every experiment, evidence, measured delta, keep/reject decision | Repo root |
| **README.md** | Problem, user, bottleneck, baseline vs advanced numbers, key failure mode, hot take, trade-offs | Repo root |
| **REPRODUCTION.md** | Exact commands, versions, expected output, runtime, how to checkout each branch | Repo root |
| **Trajectories** | Agent session logs with prompts, decisions, retries, human checkpoints | `trajectories/` |
| **Video script** | 5-min walkthrough: problem → baseline → one kept experiment → one rejected experiment → advanced comparison | `video/script.md` (optional) |

> **Rule:** Do not keep iterating past the deadline. A clean submission with honest rejected experiments beats an unfinished advanced solution.

---

## Clean Template Structure (Post-Practice)

After deleting the practice-specific directories (`service/`, `evidence/`, `personal/`), the repo becomes a reusable kickoff template:

```
hackathon-template/
├── prompts/              # All prompt files + TIGERSTYLE + post rules
│   ├── 00-git-workflow.md
│   ├── 00-scaffold-reactive-service.md
│   ├── 01-scaffold-service.md
│   ├── 02-implement-cas-update.md
│   ├── 03-idempotency-filter.md
│   ├── 04-chaos-sigkill-test.md
│   ├── 05-outbox-publisher.md
│   ├── README.md         # This file
│   ├── TIGERSTYLE.md
│   └── post.txt
├── benchmarks/           # k6.js, k6-report.js, orchestrate.js
├── tests/                # unit/, integration/, chaos/ (populate per problem)
├── trajectories/         # README.md + session logs
├── docker-compose.yml    # Postgres + Redis + Kafka + optional profiles
├── prometheus.yml
├── jfr-diagnose.sh       # Generic JFR analyzer
├── run-experiment.sh     # Full pipeline wrapper
├── README.md             # ← Template with placeholders
├── REPRODUCTION.md       # ← Template with placeholders
├── IMPROVEMENTS.md       # ← Template with placeholders
└── .gitignore
```

### Mandatory root files (template version)

These were replaced from practice content into structured placeholders so the AI can fill them during the event without guessing the rubric sections.

   ┌─────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   │ File            │ What's Inside                                                                                                                                                      │
   ├─────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ README.md       │ Skeleton with Problem & User, Baseline, Advanced, Key Failure Mode, Hot Take, Trade-offs. All practice content replaced with [bracketed placeholders].             │
   ├─────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ REPRODUCTION.md │ Full structure: Prerequisites, Versions, Setup, Endpoints, Tests, Load Test, Branch Checkout, JFR Analysis, Runtime table. Placeholders for URLs and expected      │
   │                 │ numbers.                                                                                                                                                           │
   ├─────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ IMPROVEMENTS.md │ Experiment log table template, REJECTED/KEPT detail sections, "What Mattered Most / What Did Not Matter," and a 30-second video script template.                   │
   └─────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

## AI Operating Rules for This Event

I (the AI agent) must follow these rules on every session. The human will hold me accountable.

1. **Before ending any session, ask:** "Did you save the trajectory? Run `/export-md trajectories/kimi-cli/YYYY-MM-DD_HH-MM-{topic}.md` now."
2. **Every branch must have tests.** If I generate code without tests, stop and add them. Integration tests must use Testcontainers.
3. **Measured evidence first.** No optimization without JFR/k6 numbers. No keeping an experiment without a benchmark delta.
4. **One experiment per branch.** Name it `exp/<hypothesis>`.
5. **Document every experiment** in `evidence/experiments/h[N]-[name].md` before moving on.
6. **Pre-existing vs new:** I must not claim template files (prompts, benchmarks, scripts) as event work. Only solution code, tests, experiments, and evidence are new.
7. **Macro-prompt at milestones:** After baseline JFR, after final experiment merge, and before submission, the human will run a macro-prompt for blind-spot review.
8. **Stop on deadline:** Do not start new experiments in the final 4 hours. Docs and video take longer than expected.

## References

| File                                           | What it is |
|------------------------------------------------|-----------|
| [`post.txt`](post.txt)                         | Event details — micro1 Frontier Engineering Challenge rules, timeline, evaluation criteria, prizes |
| [`TIGERSTYLE.md`](TIGERSTYLE.md)               | Coding principles I enforce on all generated code |
| [`../run-experiment.sh`](../run-experiment.sh) | Full pipeline: `mvn clean package` → `node benchmarks/orchestrate.js <mode>` → `./jfr-diagnose.sh <mode>` |
| [`../jfr-diagnose.sh`](../jfr-diagnose.sh)     | JFR analysis script — dumps events, computes percentiles, classifies severity, generates hypothesis-driven diagnosis report |
