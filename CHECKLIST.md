# Pre-Event & Pre-Flight Checklist

## Machine Setup (Do Once Before Event)

- [ ] Docker Desktop installed and running
- [ ] Docker Compose plugin works: `docker compose version`
- [ ] Java 21 installed: `java -version`
- [ ] Maven wrapper executable (Git Bash / WSL): `cd service && ./mvnw -version`
- [ ] k6 installed: `k6 version`
- [ ] JFR available: `jfr summary` or `$JAVA_HOME/bin/jfr summary`
- [ ] Node.js installed (for orchestrator): `node -v`
- [ ] Git configured with name/email

## Repo Sanity (Do Before Each Experiment)

- [ ] `git status` clean on baseline
- [ ] `git branch` shows baseline tagged
- [ ] `docker compose up -d` — Postgres (+ Redis if needed) healthy
- [ ] `cd service && ./mvnw clean package -DskipTests` compiles
- [ ] `curl http://localhost:8080/actuator/health` returns UP
- [ ] `./run-experiment.sh baseline` produces `evidence/baseline.jfr` and `evidence/k6-baseline.json`
- [ ] `./jfr-diagnose.sh baseline` produces a report with no errors

## Before Kickoff (Day Of)

- [ ] `docker system prune` to free disk space
- [ ] Close browsers, Slack, Spotify — free RAM for Docker + JVM + k6
- [ ] Terminal windows ready: one for service, one for k6, one for git
- [ ] `git checkout baseline` — verified clean
- [ ] Kimi CLI open in repo root
- [ ] `/log` export location known (for trajectory capture)

## Post-Experiment (Before Starting Next)

- [ ] `./run-experiment.sh [mode]` completed successfully
- [ ] `evidence/k6-[mode].json` exists and non-empty
- [ ] `evidence/[mode].jfr` exists
- [ ] `evidence/[mode]/diagnosis-report-[mode].md` exists
- [ ] Numbers copied into `evidence/experiments/h[N]-[name].md`
- [ ] `./save-traj.sh "experiment/h[N]-[name]"` executed
- [ ] Git committed on experiment branch
- [ ] Decision recorded (KEPT / REJECTED with numbers)

## Qualification Gate (Must Pass Before Rubric Scoring)

A submission is disqualified if any of these fail. Verify ruthlessly.

- [ ] Eligibility: individual entry, 18+, not employee/administrator
- [ ] Completeness: baseline + advanced both exist and compile
- [ ] Integrity: no plagiarism, legal/ethical use case, public/synthetic data only
- [ ] Trace: trajectories submitted for every major agent session
- [ ] Reproducibility: `REPRODUCTION.md` commands work on a clean machine

## Final Submission — 5 Mandatory Items (from post.txt)

### 1. Solution Code + Improvement Changelog
- [ ] `baseline` branch — simplest working solution, all tests pass
- [ ] `advanced` branch — meaningful improvement, all tests pass
- [ ] Every experiment on its own branch (`exp/<name>`)
- [ ] `IMPROVEMENTS.md` has every experiment logged with evidence, measured delta, keep/reject
- [ ] `IMPROVEMENTS.md` includes "What Mattered Most" and "What Did Not Matter"
- [ ] `IMPROVEMENTS.md` includes main failure mode and hot take
- [ ] `README.md` introduces intended user, explains bottleneck, why solving it is valuable
- [ ] `README.md` has baseline vs advanced numbers
- [ ] `README.md` states tools used and what was built during the event vs pre-existing

### 2. Reproduction Guide
- [ ] `REPRODUCTION.md` has prerequisites, versions, setup steps
- [ ] Exact commands for solution, baseline, and evaluation
- [ ] Required data explained
- [ ] Expected output documented
- [ ] Approximate runtime and cost stated
- [ ] Verified end-to-end on a clean checkout

### 3. Solution Video (up to 5 minutes)
- [ ] Problem stated in first 15 seconds
- [ ] Baseline shown with stack + numbers
- [ ] One kept experiment walked through with before/after numbers
- [ ] One rejected experiment mentioned with reason
- [ ] Advanced solution shown with final numbers
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
- [ ] `evidence/baseline.jfr` and `evidence/advanced.jfr` exist
- [ ] `evidence/k6-baseline.json` and `evidence/k6-advanced.json` exist
- [ ] `evidence/experiments/` has one markdown file per hypothesis
- [ ] All claims in README/IMPROVEMENTS connect to evidence files

## Submit
- [ ] `git push` or archive exported per submission form
- [ ] Double-check deadline timezone (event is online, confirm UTC vs local)
