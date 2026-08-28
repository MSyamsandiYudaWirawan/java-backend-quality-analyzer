# Session: Baseline analyzer scaffold + template reframe to eval metric

- Date: 2026-08-28
- Tool: Kimi Code CLI
- Model: kimi-k3
- Branch: `baseline`
- Human Checkpoint: yes

---

## Prompt Given

Session opened with a full hackathon context brief (paraphrased): micro1 Frontier
Engineering Challenge, problem chosen = "Code analysis: is this repository actually
good?" for a team evaluating a Java backend before acquisition/merge. Day-1
instructions were explicit:

1. Scaffold `service/` with a baseline analyzer (simple shell script or small Java app)
2. Pick 2–3 sample Java repos as test targets
3. Make the baseline run end-to-end on one repo and produce a score
4. Commit the baseline on its own branch, then start the first experiment branch

Follow-up prompts in the same session:

- "Don't focus on baseline, I'll do advanced tomorrow."
- "Help me reframe this template and refine your log and paste it in trajectories.
  Any ideas for the top-10 repo eval set?"

## Key Decisions Made

- **Baseline as a bash script, not a Java app.** The brief allowed either. A shell
  script keeps the naive control dependency-free and honest — a Java CLI with JUnit
  would have been engineering effort spent on the throwaway control instead of the
  advanced workflow. Trade-off accepted: scoring logic is unit-tested via fixture
  repos + grep assertions instead of JUnit.
- **Scoring weights 10/10/20/25/35.** Weighted toward *executed* evidence (build
  passes, tests pass) over *structural* evidence (files exist), so a repo cannot
  score well on appearances alone. Kept deliberately shallow — no partial credit,
  no static analysis — because the baseline must saturate to be a fair control.
- **`--skip-build` mode added for testability.** Unit tests run offline in seconds;
  the real Maven path is verified by the end-to-end petclinic run instead of slow
  unit tests.
- **jq avoided.** Not installed on this machine; JSON report is emitted via
  heredoc. Reproducibility docs now state jq is not required.
- **Experiment metric reframed from throughput to ranking correlation.** The
  pre-existing template measures req/s / p95 / JFR deltas of a service under load.
  For this problem the unit of improvement is *agent capability*: each experiment
  branch adds one capability (rubric scoring, parsed test evidence, runtime
  profiling, memory) and is measured by Spearman ρ against a human-expert ranking
  over a fixed ~10-repo eval set, with per-repo findings as co-primary evidence
  (ρ is coarse at n=10). The JFR/k6 tooling is not discarded — it is re-pointed at
  the *target* repo as one of the agent's analysis tools.
- **Synthetic degraded repos proposed for the eval set.** Public repos alone give
  no known-correct bottom rank; a degraded petclinic fork anchors the correlation
  and carries no license risk.
- **`.gitattributes` added pinning `*.sh` to LF.** Git warned it would convert
  scripts to CRLF on checkout, which would break them on Linux/macOS — a real
  reproducibility bug caught before committing.

## Agent Output Summary

- Files created: `service/baseline/analyze.sh`, `service/targets.txt`,
  `tests/unit/test-baseline.sh`, 6 fixture files under `tests/unit/fixtures/`,
  `.gitattributes`, this trajectory.
- Files reframed to the eval metric: `README.md` (problem/user, baseline with real
  measured result, advanced outline), `IMPROVEMENTS.md` (metric section + iteration
  log), `REPRODUCTION.md` (full rewrite for the analyzer), `CHECKLIST.md`.
- Tests added: 9 offline assertions over 3 fixture repos — all passing.
- End-to-end evidence: spring-petclinic @ `818c413` → **100/100**
  (`evidence/baseline/spring-petclinic/`: report, JSON, build.log, test.log).
  This saturation is the intended control behavior and is documented as the
  baseline's weakness the advanced workflow must overcome.
- Bugs found: none in the analyzer; one in the agent's own test (see Retries).

## Human Checkpoint

- Reviewed before accepting: yes.
- Git mutations were gated on explicit human approval via a structured question;
  the human chose "commit on a new `baseline` branch" (commit `6bbabd9`).
- The human redirected scope mid-session ("don't focus on baseline, advanced
  tomorrow"), after which no further baseline work was done beyond the requested
  doc reframe.
- No manual changes were made to agent output after acceptance.

## Retries / Corrections

- **Retry 1 (self-caught):** first unit-test run failed — the agent's expected
  score for the `no-tests-repo` fixture was 30/100 but the analyzer correctly
  produced 20/100 (README 10 + pom.xml 10; the agent had mis-added its own
  weights). The test expectation was fixed, not the analyzer. All 9 assertions
  then passed. Lesson: the executable check caught an arithmetic error in the
  agent's head — evidence over intuition, which is also the submission's thesis.
