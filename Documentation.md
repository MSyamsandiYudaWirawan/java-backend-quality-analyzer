# Codebase Map

Structural orientation for judges and reproducers. This file says WHAT each
part of the repo is and WHERE the authoritative detail lives — it deliberately
contains no detail itself. Usage, flags, and exit codes are documented in the
header block at the top of each script; design rationale and numbers live in
the evidence files.

## What this is

An evidence-based code-quality analyzer for Java backend repos (micro1
Frontier Engineering Challenge, Aug 2026). Two analyzers — a naive baseline
and an advanced agent workflow — are scored by Spearman rank correlation
against a human-expert ranking over a fixed 10-repo eval set. The full
problem, metric, and results story is in [README.md](README.md); this file
only maps the code.

## Branch map

| Branch | What it is |
|--------|------------|
| `template/init` | Pre-event template snapshot — the repo as it stood before the event (renamed from `master` in the refinement pass). |
| `exp/h1-rubric-scoring` | Baseline + blind rubric scoring on collected mechanical evidence. KEPT. |
| `exp/h2-k6-generation` | h1 + agent-generated k6 load tests against the booted target. KEPT. |
| `exp/h3-full-pipeline` | h2 + JFR profiling during the generated load. KEPT. |
| `advanced` | h3 tip under a new name (chained KEPT branches, so it IS baseline + h1 + h2 + h3). **The deliverable.** |

The baseline control has no branch of its own: `service/baseline/analyze.sh`
and its committed evidence (`evidence/eval/baseline*/`) exist on every branch
above, so the baseline runs from whichever branch you check out.

## Directory map

```
service/                            The analyzer itself (event work)
  baseline/analyze.sh               Baseline analyzer: 5 shallow checks -> 0-100 score
  advanced/collect.sh               h1: mechanical evidence collector; makes no judgments
  advanced/analyze-h1.sh            h1: thin wrapper serving the committed score sheet to the harness
  advanced/gen-k6.py                h2: renders k6 template + slots.json -> load-test.js (stdlib-only)
  advanced/k6/                      k6 templates: template.js (JSON APIs), template-form.js (form POST apps)
  advanced/docker/                  Benchmark envelope: Dockerfile.target + h2-*.yml compose addendums
  eval/evaluate.py                  Eval harness (stdlib-only): runs any analyzer, computes Spearman rho
  eval/expert-ranking.txt           Human-expert ground-truth ranking (v2, best first)
  eval/expert-worksheet.md          The expert's working instructions for the ranking session
  rubric/quality-rubric.md          Shared 100-pt scoring contract (expert ranks with it, agent scores with it)
  targets.txt                       The 10-repo eval set, with pins, drops, and validation record
evidence/                           Every measured claim (event work)
  baseline/                         Per-repo baseline reports (saturation/blindness evidence)
  advanced/h1/                      Per-repo collected evidence + committed score-sheet.json (score of record)
  advanced/h2/                      200-VU stress runs: committed load-test.js + slots.json + load report
  advanced/h2-50vus/                50-VU efficiency runs (dual-profile scoring input)
  advanced/h3/                      JFR runs: profile.jfr + per-event dumps + diagnosis + load report
  eval/{baseline,baseline-v2,h1,h1-v2,h2,h3}/
                                    Harness output per experiment: full-set scores + rho + tie bounds
  experiments/                      One h[N]-*.md per experiment: hypothesis -> numbers -> KEPT/REJECTED
  expert-ranking-notes.md           Ranking rationale, incl. the pre-authorized v1 -> v2 revision
tests/                              Test suites (event work)
  unit/                             Bash + Python unit tests for every analyzer script, plus fixtures/
  integration/                      Template README only; end-to-end coverage is the measured pipeline itself
  chaos/                            Legacy practice-problem chaos template (sigkill-test.sh, load-test-template.js)
benchmarks/                         Pre-existing benchmark tooling (template, re-pointed at targets in h2)
  k6.js                             LEGACY free-form k6 template — superseded by service/advanced/k6/ + gen-k6.py
  orchestrate.js                    Native-mode runner: boot target jar -> smoke gate -> k6 full run
  k6-report.js                      k6 summary JSON -> fixed-shape load report (also NOT_TESTABLE findings)
prompts/                            Event brief + policies (pre-existing template)
  README.md                         Single source of truth: problem, metric, k6 policy, working agreements, state log
  post.txt, problem.txt             Event rules and the full problem statement
  TIGERSTYLE.md                     Coding principles enforced on all generated code
  00-git-workflow.md                Branch/commit workflow
                                    (legacy practice-problem scaffolds 00/01-scaffold-*.md, 02-05-*.md
                                    removed in the refinement pass; reachable via git history / template/init)
trajectories/                       Curated agent-session records (event work)
  index.md                          One row per session, with the key decision of each
  kimi-cli/                         The session files themselves (the submission's trajectory record)
  kimi-api/, kimi-web/              Template scaffolding (example file / empty export dirs)
targets/                            Local clones of eval repos — GITIGNORED, not part of the repo.
                                    URL invocation is the working path (prompts/README.md §3)
video/script.md                     5-minute submission video script
personal/                           Personal study notes from practice — NOT part of the submission
run-experiment.sh                   Root runtime pipeline: build target -> k6 load -> report -> optional --jfr
jfr-diagnose.sh                     JFR hypothesis-driven diagnosis; also works standalone on any .jfr
docker-compose.yml, docker-compose.benchmark.yml, prometheus.yml
                                    Pre-existing infra / original benchmark envelope / monitoring config
REPRODUCTION.md                     Exact reproduction commands, versions, expected output
IMPROVEMENTS.md                     Experiment changelog with measured deltas and keep/reject decisions
CHECKLIST.md                        Submission gate checklist
```

## Pipeline flow

Two paths meet at the eval harness. Everything schematic; the scripts' header
blocks carry the real flags.

### (a) Eval path — how a headline rho is produced

```
service/eval/evaluate.py  --targets service/targets.txt
                          --ranking service/eval/expert-ranking.txt
                          --analyzer "<any analyzer command>"  --out evidence/eval/<label>
        |
        +--> per-repo *-score.json  +  eval-report (Spearman rho, tie bounds,
             unjudged-pair share, NOT ROBUST stamp when applicable)
```

Analyzers plugged into `--analyzer`:

- **baseline** — `bash service/baseline/analyze.sh {target} --out {out}`
  (runs live each time; it is cheap).
- **advanced** — `collect.sh` gathers mechanical evidence per repo, the agent
  scores the rubric blind, and the sheet is committed as
  `evidence/advanced/h1/<repo>/score-sheet.json`; `analyze-h1.sh` merely
  validates and serves that committed sheet, so eval runs are fast and
  reproducible.

### (b) Runtime path — how per-repo runtime evidence is produced (h2/h3)

```
author slots.json (agent, from the target's API surface)
  -> gen-k6.py renders k6/template.js (or template-form.js) -> load-test.js   [committed once]
  -> run-experiment.sh <target> --docker [--jfr]
       mvn package
       -> docker build/up: target + infra addendums (service/advanced/docker/h2-*.yml,
          same resource envelope for every repo)
       -> k6 smoke gate -> full k6 run with the COMMITTED script
       -> benchmarks/k6-report.js -> load-report.{json,md}
       -> --jfr only: in-memory JFR + dumponexit -> jfr-diagnose.sh
          -> per-event dumps + hypothesis-ranked diagnosis report
```

Committed h2 inputs (`evidence/advanced/h2/<repo>/`) are immutable; `--jfr`
writes all outputs to `evidence/advanced/h3/<repo>/`. A target that cannot be
built/booted/load-tested gets a NOT_TESTABLE report — a finding (Runtime 0),
not a harness failure.

## Where the detail lives

| Question | Authoritative source |
|----------|----------------------|
| Script usage, flags, exit codes | Header block at the top of each script: `run-experiment.sh`, `jfr-diagnose.sh`, `service/baseline/analyze.sh`, `service/advanced/collect.sh`, `service/advanced/analyze-h1.sh`, `benchmarks/orchestrate.js`, `benchmarks/k6-report.js` |
| k6 slots schema (required keys, defaults, scenarios) | Docstring + `REQUIRED`/`DEFAULTS` in `service/advanced/gen-k6.py` |
| Scoring contract (dimensions, items, evidence per point) | `service/rubric/quality-rubric.md` |
| Exact reproduction commands and expected output | `REPRODUCTION.md` |
| Experiment history: hypothesis -> numbers -> KEPT/REJECTED | `evidence/experiments/h[N]-*.md` |
| Improvement story with measured deltas | `IMPROVEMENTS.md` |
| Agent sessions and key decisions | `trajectories/index.md` |
| Project state, k6 generation policy, working agreements | `prompts/README.md` |

## Applying the pipeline to a NEW repo

1. Inspect the target's API surface (OpenAPI/springdoc if present, controllers otherwise).
2. Author a `slots.json` for it — schema and scenario variants (`json`, `form`),
   `jarGlob`, and infra addendums are documented in the `gen-k6.py` docstring.
3. Render: `python service/advanced/gen-k6.py --slots slots.json --out load-test.js`.
4. Run: `./run-experiment.sh <git-url|local-path> --docker [--jfr]` — the smoke
   gate inside the pipeline validates the scenario before the full run.

Standing warning: for the 10 committed eval repos, the committed
`evidence/advanced/h2/<repo>/load-test.js` is the artifact of record and must
NEVER be regenerated — re-runs use the committed script (policy:
prompts/README.md §5).

## Pre-existing vs event work

`prompts/`, `benchmarks/`, `run-experiment.sh`, `jfr-diagnose.sh`,
`docker-compose*.yml`, and the doc scaffolding are the pre-existing personal
hackathon template (snapshot on `template/init`). `service/`, `tests/`, `evidence/`,
the filled docs, and `trajectories/` are event work built during the August
2026 event. This distinction is a submission requirement — never blur it
(prompts/README.md §6.6).
