# Pre-Event & Pre-Flight Checklist

## Machine Setup (Do Once Before Event)

- [ ] Docker Desktop installed and running (advanced workflow: isolated target infra)
- [ ] Docker Compose plugin works: `docker compose version`
- [ ] Java 21 installed: `java -version`
- [ ] Maven installed: `mvn -version`
- [ ] k6 installed: `k6 version` (advanced workflow: runtime profiling of target repos)
- [ ] JFR available: `jfr summary` or `$JAVA_HOME/bin/jfr summary`
- [ ] Node.js installed (for the benchmark orchestrator used against target services)
- [ ] Git configured with name/email

## Repo Sanity (Do Before Each Experiment)

- [ ] `git status` clean
- [ ] `git branch` shows `baseline` branch exists
- [ ] `tests/unit/test-baseline.sh` passes (fast, offline)
- [ ] `./service/baseline/analyze.sh <fixture-or-url> --skip-build` produces a report + JSON
- [ ] Eval set in `service/targets.txt` is current (each target validated: clones, builds on Java 21)

## Before Kickoff (Day Of)

- [ ] `docker system prune` to free disk space
- [ ] Close browsers, Slack, Spotify — free RAM for Docker + JVM + k6
- [ ] Terminal windows ready: one for analyzer runs, one for git
- [ ] `git checkout baseline` — verified clean
- [ ] Kimi CLI open in repo root
- [ ] Trajectory export location known (`trajectories/kimi-cli/`)

## Post-Experiment (Before Starting Next)

- [ ] Analyzer run over the full eval set completed for this iteration
- [ ] Per-repo scores recorded (markdown + JSON under `evidence/`)
- [ ] If runtime profiling was used: `evidence/` contains the target's `.jfr` + k6 JSON
- [ ] Numbers copied into `evidence/experiments/h[N]-[name].md`
- [ ] Ranking correlation (ρ) vs. expert ranking recomputed and recorded
- [ ] Trajectory saved for the session
- [ ] Git committed on the experiment branch
- [ ] Decision recorded (KEPT / REJECTED with numbers)

## Qualification Gate (Must Pass Before Rubric Scoring)

A submission is disqualified if any of these fail. Verify ruthlessly.

- [ ] Eligibility: individual entry, 18+, not employee/administrator
- [ ] Completeness: baseline + advanced both exist and run
- [ ] Integrity: no plagiarism, legal/ethical use case, public/synthetic repos only
- [ ] Trace: trajectories submitted for every major agent session
- [ ] Reproducibility: `REPRODUCTION.md` commands work on a clean machine

## Final Submission — 5 Mandatory Items (from post.txt)

### 1. Solution Code + Improvement Changelog
- [ ] `baseline` branch — naive analyzer, unit tests pass
- [ ] `advanced` branch — agent workflow, all tests pass
- [ ] Every experiment on its own branch (`exp/<name>`)
- [ ] `IMPROVEMENTS.md` has every experiment logged with evidence, measured delta (Δρ / findings), keep/reject
- [ ] `IMPROVEMENTS.md` includes "What Mattered Most" and "What Did Not Matter"
- [ ] `IMPROVEMENTS.md` includes main failure mode and hot take
- [ ] `README.md` introduces intended user, explains bottleneck, why solving it is valuable
- [ ] `README.md` has baseline vs advanced numbers (ranking correlation + findings)
- [ ] `README.md` states tools used and what was built during the event vs pre-existing

### 2. Reproduction Guide
- [ ] `REPRODUCTION.md` has prerequisites, versions, setup steps
- [ ] Exact commands for baseline, advanced, and the eval-set comparison
- [ ] Eval repos listed and licenses checked
- [ ] Expected output documented (score tables, report format)
- [ ] Approximate runtime and cost stated
- [ ] Verified end-to-end on a clean checkout

### 3. Solution Video (up to 5 minutes)
- [ ] Problem stated in first 15 seconds
- [ ] Baseline shown with its saturation problem (petclinic 100/100)
- [ ] One kept experiment walked through with before/after ranking evidence
- [ ] One rejected experiment mentioned with reason
- [ ] Advanced solution shown with final eval-set comparison
- [ ] Changelog briefly explained
- [ ] Change that contributed most is highlighted
- [ ] One experiment removed is highlighted with reason
- [ ] Video file under 5 minutes and playable

### 4. Agent Trajectories
- [ ] `trajectories/kimi-cli/` has one file per major session
- [ ] Each file contains original prompt, agent output, key decisions, retries
- [ ] Each file has metadata header (date, tool, model)
- [ ] Failed attempts included, not just successes
- [ ] Human checkpoints documented
- [ ] `trajectories/index.md` lists all files with one-line descriptions
- [ ] At least one diagnostic ZIP included (optional but recommended)

### 5. Git Branches & Evidence
- [ ] `baseline` branch tagged
- [ ] `advanced` branch merged from last kept experiment
- [ ] `evidence/baseline/` and `evidence/advanced/` contain per-repo analysis reports
- [ ] JFR/k6 recordings exist for every repo where runtime profiling is claimed
- [ ] `evidence/experiments/` has one markdown file per hypothesis
- [ ] All claims in README/IMPROVEMENTS connect to evidence files
- [ ] Expert ranking documented (who ranked, which rubric, when)

## Submit
- [ ] `git push` or archive exported per submission form
- [ ] Double-check deadline timezone (event is online, confirm UTC vs local)
