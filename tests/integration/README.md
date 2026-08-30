# Integration tests

Placeholder — no dedicated integration suite exists. End-to-end coverage is
the measured pipeline itself: `run-experiment.sh <target> --docker [--jfr]`
boots a real target, runs the committed k6 script, and (with `--jfr`) the JFR
diagnosis; `service/eval/evaluate.py` then scores full eval-set runs. Their
outputs are the committed evidence under `evidence/`.

See `REPRODUCTION.md` for the exact end-to-end commands.
