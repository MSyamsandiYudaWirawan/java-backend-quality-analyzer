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


if __name__ == "__main__":
    unittest.main(verbosity=2)
