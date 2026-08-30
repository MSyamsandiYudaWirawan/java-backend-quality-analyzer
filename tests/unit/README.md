# Unit tests

Bash + Python sanity suite for the analyzer scripts, with canned repos and
evidence under `fixtures/` (bare-repo, good-repo, no-tests-repo, h1-evidence,
k6-report).

- `test-baseline.sh` — `service/baseline/analyze.sh`
- `test-collect.sh`, `test-analyze-h1.sh` — h1 collector + wrapper
- `test_spearman.py` — `service/eval/evaluate.py` ranking math
- `test_gen_k6.py` — `service/advanced/gen-k6.py` slot rendering
- `test-k6-report.sh`, `test-run-experiment.sh` — k6 report + pipeline flags

Run the full suite (same block as prompts/README.md §3):

```bash
tests/unit/test-baseline.sh && tests/unit/test-collect.sh \
  && tests/unit/test-analyze-h1.sh && python tests/unit/test_spearman.py \
  && python tests/unit/test_gen_k6.py \
  && tests/unit/test-k6-report.sh && tests/unit/test-run-experiment.sh
```
