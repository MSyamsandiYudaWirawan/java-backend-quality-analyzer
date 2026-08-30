# Agent Trajectory Capture Guide

micro1 requires **trajectory submission** for every agent used. This folder stores those logs.

**Tool used:** Kimi API Console (platform.moonshot.cn) only.

---

## Kimi API Console — How to Save Conversation Threads as Markdown

Since you are using the Kimi API Console (platform.moonshot.cn) instead of a local CLI agent, you must manually export each conversation thread after your session ends.

### Step-by-Step Export

1. **Finish your API Console session** (send all prompts, review all responses).
2. **Copy the entire conversation thread** from the API Console UI:
    - Select all message blocks (prompts + responses) in the conversation panel.
    - Copy to clipboard (`Ctrl+C`).
3. **Paste into a new markdown file**:
   ```
   trajectories/kimi-api/YYYY-MM-DD_HH-MM_{topic}.md
   ```
   Example: `trajectories/kimi-api/2026-08-28_09-00-scaffold-baseline.md`
4. **Add the metadata header at the top** of the file:
   ```markdown
   # Session: {brief topic}
   - Date: 2026-08-28
   - Tool: Kimi API Console (platform.moonshot.cn)
   - Model: kimi-k3 (or whatever model you selected)
   - Human Checkpoint: yes/no
   ```
5. **Append the Key Decisions section** at the bottom of the file (see template below).

---

## Required Metadata for Every Trajectory

Judges need to follow your thought process. Every trajectory file must include:

```markdown
## Prompt Given
{exact prompt you sent to the agent}

## Key Decisions Made
- Decision 1: why X not Y
- Decision 2: why Y not Z

## Agent Output Summary
- File created/modified: ...
- Tests added: ...
- Bugs found: ...

## Human Checkpoint
- Did you review before accepting? yes/no
- What did you change manually after agent output?

## Retries / Corrections
- Retry 1: prompt X failed because Y, corrected by Z
```

---

## Folder Naming Convention

```
trajectories/
├── kimi-api/
│   ├── 2026-08-28_09-00-scaffold-baseline.md
│   ├── 2026-08-28_14-30-implement-saga.md
│   ├── 2026-08-29_10-00-chaos-test.md
│   └── raw-exports/           # optional: raw copy-paste backups
├── README.md                  # this file
└── index.md                   # master index of all sessions
```

---

## What to Capture vs. Summarize

Not all AI interactions carry equal weight. Use this filter: **did this exchange shape what you built next?** If yes, copy raw. If no, summarize briefly.

### Copy Raw (high purposeful AI use)

These directly shaped the next engineering decision. Judges need the full exchange to verify your reasoning wasn't post-hoc.

| Interaction | Why raw matters |
|---|---|
| JFR/k6 report → AI hypothesis | Core baseline→measure→hypothesize loop. Shows AI interpreted evidence, not just generated code |
| Keep/reject decision | Before/after numbers fed to AI, AI gives reasoned verdict. Connects evidence to changelog entry |
| Blind spot check | Final review of IMPROVEMENTS.md — shows AI as reviewer, not generator |

For raw copies: trim only pleasantries and reformatting requests. **Keep all retries and corrections** — if AI was wrong first and you pushed back, that's the human checkpoint judges are looking for.

### Brief Summary (low purposeful AI use)

Micro prompts on specific stuck points. One paragraph is enough:
- What you were stuck on
- What AI said
- What you did

Example: *"Asked AI about `GenericJacksonJsonRedisSerializer` no-arg constructor missing in Spring Data Redis 4.1.1. AI pointed to `Jackson2JsonRedisSerializer` as the typed alternative. Used that instead."*

---

## Quick Checklist Before Submitting

- [ ] Every major coding session has a trajectory file in `kimi-api/`
- [ ] Each file has the metadata header (date, tool, model)
- [ ] Each file shows the **original prompt**, not just the result
- [ ] Failed attempts and retries are included (not only successes)
- [ ] High purposeful interactions (JFR→hypothesis, keep/reject, blind spot) are copied raw
- [ ] Low purposeful interactions (micro stuck-on-specific) are summarized in one paragraph
- [ ] `index.md` lists all trajectory files with one-line descriptions
