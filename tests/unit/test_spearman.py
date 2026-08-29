#!/usr/bin/env python3
"""Fast offline unit tests for the statistics in service/eval/evaluate.py.

Run from the repo root:  python tests/unit/test_spearman.py
"""

import importlib.util
import os
import sys
import unittest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MODULE_PATH = os.path.join(REPO_ROOT, "service", "eval", "evaluate.py")

spec = importlib.util.spec_from_file_location("evaluate", MODULE_PATH)
evaluate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evaluate)


class TestRanks(unittest.TestCase):
    def test_distinct_values(self):
        # Largest value gets rank 1.
        self.assertEqual(evaluate.ranks([30, 10, 20]), [1.0, 3.0, 2.0])

    def test_ties_share_average_rank(self):
        self.assertEqual(evaluate.ranks([5, 5, 1]), [1.5, 1.5, 3.0])

    def test_all_equal(self):
        self.assertEqual(evaluate.ranks([7, 7, 7]), [2.0, 2.0, 2.0])


class TestSpearman(unittest.TestCase):
    def test_perfect_agreement(self):
        self.assertAlmostEqual(
            evaluate.spearman([50, 40, 30, 20, 10], [5, 4, 3, 2, 1]), 1.0)

    def test_perfect_disagreement(self):
        self.assertAlmostEqual(
            evaluate.spearman([10, 20, 30, 40, 50], [5, 4, 3, 2, 1]), -1.0)

    def test_known_intermediate_value(self):
        # Hand-computed: xs deviations [-2,-1,0,1,2], ys deviations [-1,-2,0,2,1],
        # products sum to 8, variances 10 and 10 -> rho = 8/10 = 0.8.
        self.assertAlmostEqual(
            evaluate.spearman([1, 2, 3, 4, 5], [2, 1, 3, 5, 4]), 0.8)

    def test_zero_variance_is_none(self):
        # Baseline saturating (all scores 100) makes rho undefined, not an
        # exception — the harness must report "not computed".
        self.assertIsNone(evaluate.spearman([100, 100, 100], [3, 2, 1]))

    def test_length_mismatch_raises(self):
        with self.assertRaises(ValueError):
            evaluate.spearman([1, 2, 3], [1, 2])


class TestTieBounds(unittest.TestCase):
    def test_no_ties_bounds_equal_rho(self):
        rho, best, worst = evaluate.spearman_tie_bounds([3, 2, 1], [3, 2, 1])
        self.assertAlmostEqual(rho, 1.0)
        self.assertAlmostEqual(best, 1.0)
        self.assertAlmostEqual(worst, 1.0)

    def test_known_tied_case(self):
        # xs=[2,1,1], ys=[3,2,1]: the tied pair can be ordered with the
        # expert (best: perfect ranks -> 1.0) or against (worst: one
        # adjacent swap -> 0.5). Average-rank rho: ranks [1,2.5,2.5] vs
        # [1,2,3] -> cov 1.5, variances 1.5 and 2 -> 1.5/sqrt(3) ~ 0.866.
        rho, best, worst = evaluate.spearman_tie_bounds([2, 1, 1], [3, 2, 1])
        self.assertAlmostEqual(rho, 1.5 / 3 ** 0.5)
        self.assertAlmostEqual(best, 1.0)
        self.assertAlmostEqual(worst, 0.5)

    def test_bounds_bracket_average_rank_rho(self):
        # Baseline-like profile: two tie groups (2x100, 5x90) over 10 repos.
        scores = [100, 100, 90, 90, 90, 90, 90, 65, 55, 40]
        expert = [10, 8, 4, 6, 7, 9, 3, 5, 2, 1]
        rho, best, worst = evaluate.spearman_tie_bounds(scores, expert)
        self.assertLessEqual(worst, rho)
        self.assertLessEqual(rho, best)

    def test_tie_groups_only_reports_real_ties(self):
        groups = evaluate.tie_groups([5, 5, 1, 1, 1, 9])
        self.assertEqual(sorted(len(g) for g in groups), [2, 3])


class TestPairCounts(unittest.TestCase):
    def test_all_concordant(self):
        self.assertEqual(evaluate.pair_counts([3, 2, 1], [3, 2, 1]), (3, 0, 0))

    def test_all_discordant(self):
        self.assertEqual(evaluate.pair_counts([1, 2, 3], [3, 2, 1]), (0, 3, 0))

    def test_analyzer_ties_are_unjudged_pairs(self):
        # 5 repos, 3 tied by the analyzer: pairs = C(5,2) = 10;
        # tied pairs = C(3,2) = 3; the rest concordant.
        self.assertEqual(
            evaluate.pair_counts([100, 90, 90, 90, 40], [5, 4, 3, 2, 1]),
            (7, 0, 3))

    def test_saturated_analyzer_judges_nothing(self):
        self.assertEqual(evaluate.pair_counts([100, 100, 100], [3, 2, 1]),
                         (0, 0, 3))


class TestHelpers(unittest.TestCase):
    def test_repo_name_from_url(self):
        self.assertEqual(
            evaluate.repo_name("https://github.com/spring-projects/spring-petclinic"),
            "spring-petclinic")

    def test_repo_name_strips_dot_git(self):
        self.assertEqual(evaluate.repo_name("https://x.test/a/b.git"), "b")

    def test_repo_name_from_local_path(self):
        self.assertEqual(evaluate.repo_name("tests/targets/petclinic-degraded"),
                         "petclinic-degraded")

    def test_parse_list_file_skips_comments(self):
        path = os.path.join(REPO_ROOT, "service", "targets.txt")
        entries = evaluate.parse_list_file(path)
        self.assertIn("https://github.com/spring-projects/spring-petclinic", entries)
        for entry in entries:
            self.assertFalse(entry.startswith("#"))

    def test_bash_path_passes_urls_through(self):
        # URLs are not filesystem paths: abspath/relpath would mangle
        # "https://host/..." into "https:/host/...", which git parses as scp
        # syntax (host "https") — regression test for the Day-2 eval failure.
        url = "https://github.com/spring-projects/spring-petclinic"
        self.assertEqual(evaluate.bash_path(url), url)
        self.assertEqual(evaluate.bash_path("git@github.com:a/b.git"),
                         "git@github.com:a/b.git")

    def test_bash_path_normalizes_local_path(self):
        converted = evaluate.bash_path(os.path.join("targets", "practice-mvc"))
        self.assertNotIn("\\", converted)
        self.assertIn("targets/practice-mvc", converted)


if __name__ == "__main__":
    unittest.main(verbosity=2)
