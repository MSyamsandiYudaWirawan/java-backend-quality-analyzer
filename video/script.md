# 5-Minute Walkthrough Script

> Template. Replace [brackets] with real content during finalize.
> Practice once before recording. Do not improvise.

---

## 0. Hook (15 sec)

"The problem is [X]. [User] needs [capability], but [bottleneck] makes it impossible at scale."

## 1. Baseline (45 sec)

"My baseline is [tech stack]. It does [scope].
Measured: [RPS] req/s, p95 [X]ms, [Y]% errors.
It's intentionally naive — passes tests, zero optimization."

## 2. One Rejected Experiment (60 sec)

"First I tried [hypothesis]. Evidence looked like [JFR signal].
I implemented [change]. Result: [numbers].
That was [rejected / falsified] because [reason with numbers]."

## 3. One Kept Experiment (60 sec)

"The experiment that actually mattered was [hypothesis].
I changed [what].
Result: [before numbers] → [after numbers]. Delta: [+X% RPS, -Y% p95].
I kept it because [reason]."

## 4. Advanced Solution (60 sec)

"The advanced solution merges [kept experiments].
Final stack: [tech stack].
Measured: [RPS] req/s, p95 [X]ms.
Key trade-off: [what we gained] vs [what we gave up].
The full changelog is in `IMPROVEMENTS.md` — [experiment X] contributed most, and I removed [experiment Y] because [reason with numbers]."

## 5. Key Failure Mode (30 sec)

"The trickiest bug was [description]. Root cause: [why]. Fix: [how]."

## 6. Hot Take (30 sec)

"If I had to do it again, I'd [opinion]. [X] mattered most. [Y] mattered least."

## 7. Close (15 sec)

"Repo, reproduction guide, and evidence are all in the submission. Thank you."

---

## Recording Tips

- Use a terminal with a dark theme and large font (14pt+)
- Run `./run-experiment.sh advanced` live if it finishes in <2 min, or show pre-generated artifacts
- Have `evidence/baseline/` and `evidence/advanced/` folders open side-by-side
- Do not read from script verbatim — bullet-point memory cards are fine
