# Git Workflow for Performance Experiments

> Rule: Every experiment is a diff against `baseline`. The judge must be able to checkout any branch and reproduce the measurement.

---

## Branch Types

| Branch | Purpose | Created When |
|--------|---------|-------------|
| `master` | Initial scaffold, configs, empty project | Before kickoff |
| `baseline` | Simplest working solution + JFR + k6 evidence | After baseline passes tests and load |
| `experiment/<name>` | ONE optimization attempt | Before touching any code |
| `advanced` | Final solution: baseline + all KEPT experiments merged | After all experiments complete |

---

## The Golden Rule

**Every experiment branch starts from `baseline`.** Never from another experiment.

```bash
# CORRECT — one variable, isolated
git checkout baseline
git checkout -b experiment/h2-cache-layer

# WRONG — pollutes variables
git checkout experiment/h1-micro-opts
git checkout -b experiment/h2-cache-layer
```

---

## Two Types of Experiments

### Type A: Tweak (small diff)

Changes a config, adds a cache, swaps one method for another.

```bash
git checkout baseline
git checkout -b experiment/h2-cache-layer
# Edit application.properties / application.yml
# Run k6 + JFR
# Commit result
```

Diff size: small. Easy to review.

### Type B: Rewrite (large diff)

Replaces the entire stack or architecture pattern.

```bash
git checkout baseline
git checkout -b experiment/h5-reactive-rewrite
# rm -rf service/src/main/java/...
# Scaffold new stack
# Run k6 + JFR
# Commit result
```

Diff size: massive. That's correct — it's a full rewrite experiment.

**Both branch from `baseline`.** The only difference is how much code changes.

---

## Commit Message Template

```
experiment/<name>: <one-line summary> — <KEPT/REJECTED/FALSIFIED>

- Hypothesis: <what you thought would improve>
- Evidence: <JFR signal / JMH result / k6 numbers>
- Result: <what actually happened>
- Decision: <why kept or rejected, with numbers>
```

Example (REJECTED):
```
experiment/h1: CPU micro-optimizations — FALSIFIED

- Hypothesis: Replacing UUID parsing and Builder with hand-rolled variants reduces latency
- Evidence: JMH isolated benchmarks (see evidence/experiments/h1.md)
- Result: All three already optimal or JIT-eliminated. No measurable improvement.
- Decision: Rejected. ~100ns operation is invisible next to 30ms p95 latency.
```

Example (KEPT):
```
experiment/h2: Add read-through cache — KEPT

- Hypothesis: Caching GET lookups will eliminate DB round-trips for hot keys
- Evidence: JFR SocketRead p95=25ms, 155 events under 50 VUs
- Result: k6 RPS 3,500→14,200 (+305%), p95 30ms→5ms (-83%)
- Decision: Kept. Largest measured win by far; simple one-annotation change.
```

---

## Workflow Step by Step

### 1. Baseline is sacred

```bash
# After baseline works and JFR is captured
git add .
git commit -m "baseline: [description]
- JFR: evidence/baseline.jfr
- k6: [RPS], [p95], [p99], [errors]
- Tests: [pass/fail]"
git tag baseline-v1.0
```

### 2. Start an experiment

```bash
git checkout baseline
git checkout -b experiment/<name>
# Make changes. Run measurements.
```

### 3. Commit the experiment

```bash
git add .
git commit -m "experiment/<name>: ..."
```

### 4. Decide: keep or reject

**If REJECTED:**
- Do NOT merge to `advanced`
- The branch stays as evidence
- Fill `evidence/experiments/<name>.md` with results

**If KEPT:**
```bash
git checkout advanced
git merge experiment/<name>
# Resolve conflicts if multiple kept experiments touch same files
```

### 5. Start next experiment from baseline

```bash
git checkout baseline
git checkout -b experiment/<next-name>
```

---

## Advanced Branch Merge Order

If multiple experiments are kept and they touch the same files, merge in dependency order:

```bash
git checkout baseline
git checkout -b advanced

git merge experiment/h2-config-tuning      # config changes only
git merge experiment/h3-read-cache         # adds cache layer
git merge experiment/h5-stack-rewrite      # full rewrite — must be LAST
```

A full rewrite merge will overwrite previous tweaks. That's correct if the rewrite subsumes them.

---

## Visual History

```
master ──┬── baseline ──┬── experiment/h1 (FALSIFIED)
         │              ├── experiment/h2 (KEPT) ───┐
         │              ├── experiment/h3 (REJECTED)  │
         │              └── experiment/h4 (KEPT) ─────┤
         │                                            │
         └────────────────────────────────────────────┴── advanced
```

Every experiment is a direct child of `baseline`. `advanced` is the merge of all kept children.

---

## Common Mistakes

| Mistake | Why it breaks the process |
|---------|--------------------------|
| Branch experiment from another experiment | Can't isolate which change caused the improvement |
| Commit multiple hypotheses in one branch | Can't attribute wins to specific changes |
| Merge rejected experiment to `advanced` | Pollutes the final solution with useless code |
| Don't commit on experiment branch | Judge can't checkout and reproduce |
| Forget to tag baseline | Can't return to clean control state |

---

## Pre-Event Checklist

- [ ] `git branch` shows `master`, `baseline`
- [ ] `git tag` shows `baseline-v1.0`
- [ ] `git checkout baseline` compiles and passes tests
- [ ] `git checkout baseline && git checkout -b experiment/test` works
