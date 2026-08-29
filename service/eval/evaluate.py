#!/usr/bin/env python3
"""Eval harness: run an analyzer over the eval set and compare its ranking
against the expert ranking.

This is the "k6" of this project: every experiment reports through it.
Stdlib only (TigerStyle: no dependency for 100 lines of statistics).

Usage:
  python service/eval/evaluate.py \
      --label baseline \
      --analyzer "bash service/baseline/analyze.sh {target} --out {out}" \
      --targets service/targets.txt \
      --ranking service/eval/expert-ranking.txt \
      --out evidence/eval/baseline

Inputs:
  --targets   File with one repo URL or local path per line (# = comment).
  --analyzer  Command template; {target} and {out} are substituted per repo.
              The command must write a *-score.json with a "score" field
              into {out}.
  --ranking   Optional. Expert ranking, repo names best-first (# = comment).
              If omitted, scores are collected but no correlation is computed.
  --label     Name for this run (baseline / h1-rubric / advanced / ...).
  --out       Directory for per-repo analyzer output + the eval report.
  --timeout   Per-repo analyzer timeout in seconds (default 1800).
  --resume    Skip repos whose out dir already holds a *-score.json from a
              previous (partial) run; reuse that score instead of re-running
              the analyzer. Makes a crashed multi-hour eval re-runnable
              without redoing finished repos.

Output:
  <out>/eval-report.md    Per-repo score/rank table + Spearman rho
  <out>/eval-results.json Machine-readable results
"""

import argparse
import glob
import json
import os
import shlex
import shutil
import subprocess
import sys
import time


def parse_list_file(path):
    """Read a targets/ranking file: strip comments and blank lines, return
    the first whitespace-separated token of each remaining line."""
    entries = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            entries.append(line.split()[0])
    return entries


def repo_name(target):
    """Stable short name for a URL or local path: its last path segment,
    without a trailing .git."""
    name = target.rstrip("/").rsplit("/", 1)[-1]
    if name.endswith(".git"):
        name = name[:-4]
    return name


def bash_path(path):
    """Convert a Python path to a form the shell in the command template
    reliably understands. Repo-relative paths are used verbatim (mount-scheme
    independent); absolute drive-letter paths go through cygpath when present,
    else fall back to the /x/... MSYS form. Backslashes are always normalized:
    in bash they are escape characters. Git URLs (https://, git@, ...) are
    passed through unchanged — they are not filesystem paths and must never
    go through abspath/relpath, which would mangle 'https://host/...' into
    'https:/host/...' (git then parses it as scp syntax and tries ssh to a
    host named 'https')."""
    if "://" in path or path.startswith("git@"):
        return path
    absolute = os.path.abspath(path)
    try:
        relative = os.path.relpath(absolute, os.getcwd())
    except ValueError:
        relative = None
    if relative is not None and not relative.startswith(".."):
        return relative.replace("\\", "/")
    cygpath = shutil.which("cygpath")
    if cygpath:
        converted = subprocess.run([cygpath, "-u", absolute],
                                   capture_output=True, text=True)
        if converted.returncode == 0:
            return converted.stdout.strip()
    drive, rest = os.path.splitdrive(absolute)
    if drive:
        return "/" + drive[0].lower() + rest.replace("\\", "/")
    return absolute.replace("\\", "/")


def run_analyzer(command_template, target, out_dir, timeout_seconds):
    """Run the analyzer for one repo. Returns (score, error).
    score is None when the analyzer failed or produced no score file."""
    os.makedirs(out_dir, exist_ok=True)
    command = (command_template
               .replace("{target}", bash_path(target))
               .replace("{out}", bash_path(out_dir)))
    started = time.time()
    try:
        proc = subprocess.run(
            shlex.split(command),
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired:
        return None, "timeout after %ds" % timeout_seconds
    elapsed = time.time() - started
    with open(os.path.join(out_dir, "analyzer-stdout.log"), "w", encoding="utf-8") as f:
        f.write(proc.stdout or "")
        f.write(proc.stderr or "")
    if proc.returncode != 0:
        return None, "analyzer exit code %d" % proc.returncode
    score_files = glob.glob(os.path.join(out_dir, "*-score.json"))
    if not score_files:
        return None, "no *-score.json produced"
    with open(score_files[0], encoding="utf-8") as f:
        score = json.load(f)["score"]
    return score, "ok in %.0fs" % elapsed


def ranks(values):
    """Average ranks for ties; rank 1 = largest value."""
    order = sorted(range(len(values)), key=lambda i: -values[i])
    result = [0.0] * len(values)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        average = (i + j) / 2.0 + 1.0
        for k in range(i, j + 1):
            result[order[k]] = average
        i = j + 1
    return result


def pearson(xs, ys):
    """Pearson correlation. Returns None when undefined (zero variance)."""
    n = len(xs)
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n
    cov = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    var_x = sum((x - mean_x) ** 2 for x in xs)
    var_y = sum((y - mean_y) ** 2 for y in ys)
    if var_x == 0 or var_y == 0:
        return None
    return cov / (var_x * var_y) ** 0.5


def spearman(xs, ys):
    """Spearman rank correlation between two value lists (larger = better)."""
    if len(xs) != len(ys):
        raise ValueError("spearman: list lengths differ (%d vs %d)" % (len(xs), len(ys)))
    if len(xs) < 2:
        raise ValueError("spearman: need at least 2 data points")
    return pearson(ranks(xs), ranks(ys))


def tie_groups(values):
    """Groups of indices sharing the same value (only groups of size >= 2)."""
    by_value = {}
    for i, v in enumerate(values):
        by_value.setdefault(v, []).append(i)
    return [members for members in by_value.values() if len(members) >= 2]


def spearman_tie_bounds(xs, ys):
    """(rho, rho_best, rho_worst): Spearman rho plus the range rho could
    take if every tie in xs were broken luckily or unluckily.

    Tied values share an average rank, which flatters an analyzer that
    cannot order the tied items: the average sits mid-pack either way.
    The bounds break each tie by redistributing the group's own rank
    positions, aligned with ys (best) or anti-aligned (worst). Ranks
    outside tie groups are unaffected, so this is an exact sensitivity
    range, not a simulation.
    """
    rx = ranks(xs)
    ry = ranks(ys)
    best = list(rx)
    worst = list(rx)
    for members in tie_groups(xs):
        lo = int(min(rx[i] for i in members))
        positions = list(range(lo, lo + len(members)))
        aligned = sorted(members, key=lambda i: -ys[i])
        for position, i in zip(positions, aligned):
            best[i] = position
        for position, i in zip(positions, reversed(aligned)):
            worst[i] = position
    return pearson(rx, ry), pearson(best, ry), pearson(worst, ry)


def pair_counts(xs, ys):
    """(concordant, discordant, tied) over all i<j pairs.

    tied = pairs where xs (or ys) ties, i.e. the analyzer expressed no
    ordering opinion. An analyzer that saturates has a high tied count —
    that absence of judgment is itself reported here, not hidden inside
    a correlation coefficient.
    """
    concordant = discordant = tied = 0
    for i in range(len(xs)):
        for j in range(i + 1, len(xs)):
            dx = (xs[i] > xs[j]) - (xs[i] < xs[j])
            dy = (ys[i] > ys[j]) - (ys[i] < ys[j])
            if dx == 0 or dy == 0:
                tied += 1
            elif dx == dy:
                concordant += 1
            else:
                discordant += 1
    return concordant, discordant, tied


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--label", required=True)
    parser.add_argument("--analyzer", required=True)
    parser.add_argument("--targets", required=True)
    parser.add_argument("--ranking")
    parser.add_argument("--out", required=True)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()

    for path in (args.targets, args.ranking):
        if path and not os.path.isfile(path):
            print("ERROR: file not found: %s" % path, file=sys.stderr)
            sys.exit(2)

    targets = parse_list_file(args.targets)
    if not targets:
        print("ERROR: no targets in %s" % args.targets, file=sys.stderr)
        sys.exit(2)

    os.makedirs(args.out, exist_ok=True)

    results = []
    for target in targets:
        name = repo_name(target)
        repo_out = os.path.join(args.out, name)
        print(">> [%s] %s" % (args.label, target))
        prior_scores = glob.glob(os.path.join(repo_out, "*-score.json"))
        if args.resume and prior_scores:
            with open(prior_scores[0], encoding="utf-8") as f:
                score = json.load(f)["score"]
            note = "reused from previous run (--resume)"
        else:
            score, note = run_analyzer(args.analyzer, target, repo_out, args.timeout)
        print("   score=%s (%s)" % (score, note))
        results.append({"target": target, "name": name, "score": score, "note": note})

    # Expert comparison: expert file lists repos best-first; convert positions
    # to descending quality values so spearman() treats larger as better.
    expert_rank_of = {}
    unranked_note = ""
    if args.ranking:
        expert_order = parse_list_file(args.ranking)
        n_expert = len(expert_order)
        expert_rank_of = {name: position + 1 for position, name in enumerate(expert_order)}
        for entry in results:
            entry["expertRank"] = expert_rank_of.get(entry["name"])
        missing = [e["name"] for e in results if e["expertRank"] is None]
        if missing:
            unranked_note = ("WARNING: %d repo(s) missing from expert ranking, "
                             "excluded from rho: %s" % (len(missing), ", ".join(missing))
                             .replace("rho", "rho"))
            print(">> " + unranked_note, file=sys.stderr)
    else:
        for entry in results:
            entry["expertRank"] = None
        unranked_note = "No expert ranking given; rho not computed."

    comparable = [e for e in results
                  if e["score"] is not None and e["expertRank"] is not None]
    rho = rho_best = rho_worst = None
    tie_stats = None
    pair_stats = None
    if len(comparable) >= 2:
        scores = [e["score"] for e in comparable]
        expert_quality = [len(expert_rank_of) - e["expertRank"] + 1 for e in comparable]
        rho, rho_best, rho_worst = spearman_tie_bounds(scores, expert_quality)
        groups = tie_groups(scores)
        tie_stats = {"groups": len(groups),
                     "tiedRepos": sum(len(g) for g in groups)}
        concordant, discordant, tied = pair_counts(scores, expert_quality)
        pair_stats = {"concordant": concordant, "discordant": discordant,
                      "tied": tied}
    elif args.ranking:
        print("WARNING: fewer than 2 comparable repos; rho not computed.", file=sys.stderr)

    # Analyzer rank per repo (ties share the better rank for display purposes;
    # the rho computation above uses proper average ranks).
    scored = [e for e in results if e["score"] is not None]
    analyzer_ranks = ranks([e["score"] for e in scored])
    for entry, rank in zip(scored, analyzer_ranks):
        entry["analyzerRank"] = rank
    for entry in results:
        entry.setdefault("analyzerRank", None)

    report_lines = [
        "# Eval Report: %s" % args.label,
        "",
        "- Targets: %s" % args.targets,
        "- Expert ranking: %s" % (args.ranking or "(none)"),
        "- Comparable repos: %d of %d" % (len(comparable), len(results)),
        "",
        "| Repo | Score | Analyzer rank | Expert rank | Note |",
        "|------|-------|---------------|-------------|------|",
    ]
    for e in sorted(results, key=lambda e: (e["analyzerRank"] is None, e["analyzerRank"] or 0)):
        report_lines.append("| %s | %s | %s | %s | %s |" % (
            e["name"],
            e["score"] if e["score"] is not None else "FAIL",
            e["analyzerRank"] if e["analyzerRank"] is not None else "-",
            e["expertRank"] if e["expertRank"] is not None else "-",
            e["note"],
        ))
    report_lines.append("")
    if rho is not None:
        total_pairs = (pair_stats["concordant"] + pair_stats["discordant"]
                       + pair_stats["tied"])
        unjudged_pct = round(100 * pair_stats["tied"] / total_pairs)
        headline = "**Spearman rho vs expert ranking: %.3f** (n=%d)" % (
            rho, len(comparable))
        if unjudged_pct > 20:
            headline += (" — NOT ROBUST: tie-sensitive, range [%.3f, %.3f], "
                         "%d%% of pairs unjudged"
                         % (rho_worst, rho_best, unjudged_pct))
        report_lines.append(headline)
        if tie_stats["tiedRepos"]:
            report_lines.append("")
            report_lines.append(
                "Tie check: %d of %d scored repos sit in %d tie group(s); "
                "within a tie the analyzer carries no ordering information. "
                "If every tie broke luckily/unluckily, rho would be in "
                "[%.3f, %.3f]." % (tie_stats["tiedRepos"], len(comparable),
                                   tie_stats["groups"], rho_worst, rho_best))
        report_lines.append("")
        report_lines.append(
            "Pair check: of %d repo pairs, %d concordant, %d discordant, "
            "%d tied by the analyzer (no ordering opinion)."
            % (total_pairs, pair_stats["concordant"],
               pair_stats["discordant"], pair_stats["tied"]))
    else:
        report_lines.append("**Spearman rho: not computed.** %s" % unranked_note)
    if unranked_note:
        report_lines.append("")
        report_lines.append("> %s" % unranked_note)

    report_path = os.path.join(args.out, "eval-report.md")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines) + "\n")

    results_path = os.path.join(args.out, "eval-results.json")
    with open(results_path, "w", encoding="utf-8") as f:
        json.dump({"label": args.label, "rho": rho,
                   "rhoBest": rho_best, "rhoWorst": rho_worst,
                   "ties": tie_stats, "pairs": pair_stats,
                   "results": results}, f, indent=2)

    print()
    print("\n".join(report_lines))
    print()
    print(">> Wrote %s" % report_path)
    print(">> Wrote %s" % results_path)


if __name__ == "__main__":
    main()
