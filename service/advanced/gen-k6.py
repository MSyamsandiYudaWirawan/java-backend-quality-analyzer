#!/usr/bin/env python3
"""h2 k6 generator — renders template.js + a committed slots JSON into a
self-contained load-test.js (exp/h2-k6-generation).

Generation is template + slots, never free-form (prompts/README.md §5):
the agent inspects a repo's API surface (OpenAPI/springdoc if present,
controllers otherwise) and fills a slots JSON; this script validates the
slots against a fixed schema and renders them into the fixed template.
The rendered script is committed per repo as evidence; re-runs use the
committed script, never regeneration.

Scenarios: "json" (default) posts a JSON body and reads the new id from
the response body; "form" posts application/x-www-form-urlencoded and
reads the new id from the redirect Location header (server-rendered apps).

Stdlib only. Usage:
  gen-k6.py --slots FILE --out FILE [--template FILE]

Exit codes: 0 ok, 1 validation error, 2 usage/io error.
"""

import argparse
import json
import re
import sys
from pathlib import Path

TEMPLATE_DEFAULT = Path(__file__).resolve().parent / "k6" / "template.js"
TEMPLATE_FORM_DEFAULT = Path(__file__).resolve().parent / "k6" / "template-form.js"
SLOTS_MARKER = "/*__SLOTS__*/"

# The whole schema lives here: required keys, optional keys with defaults.
# Anything outside this table is rejected — slots are data, not code.
REQUIRED = {
    "repoName": str,
    "baseUrl": str,
    "createPath": str,
    "createPayload": str,
    "readPath": str,
}
DEFAULTS = {
    "scenario": "json",
    "idField": "id",
    "createStatus": 201,
    "readStatus": 200,
    "entityCount": 50,
    "writeRatio": 0.1,
    "vus": 200,
    "duration": "60s",
    "ramp": "10s",
    "p95ThresholdMs": 500,
    "errorRateThreshold": 0.01,
    "checkRateThreshold": 0.95,
    "headers": {"Content-Type": "application/json"},
    # Benchmark environment (read by run-experiment.sh, not by the k6
    # script): which infra profiles the target's architecture needs, env
    # overrides for the target container, env for the infra containers.
    "infra": [],
    "bootEnv": {},
    "infraEnv": {},
}

KNOWN_INFRA = {"postgres", "mysql", "redis"}

# Optional in both scenarios, never defaulted: pins the boot jar as
# */target/<jarGlob> in run-experiment.sh for multi-module repos where the
# largest-jar heuristic picks the wrong module.
OPTIONAL_KEYS = {"jarGlob"}

# Scenario-specific keys: each set is valid only in its own scenario and
# rejected in the other. "createPayload"/"idField" already live in
# REQUIRED/DEFAULTS; "formFields"/"idRegex" exist only in form mode.
SCENARIOS = ("json", "form")
SCENARIO_KEYS = {
    "json": {"createPayload", "idField"},
    "form": {"formFields", "idRegex"},
}

DURATION_RE = re.compile(r"^\d+[smh]$")
URL_RE = re.compile(r"^https?://[^\s/]+(?::\d+)?$")


class SlotsError(ValueError):
    """Raised for any slots validation failure."""


def fail(msg):
    raise SlotsError(msg)


def validate_slots(raw):
    if not isinstance(raw, dict):
        fail("slots file must contain a single JSON object")

    scenario = raw.get("scenario", "json")
    if not isinstance(scenario, str) or scenario not in SCENARIOS:
        fail(f"unknown scenario: {scenario!r} (allowed: {', '.join(SCENARIOS)})")

    known = set(REQUIRED) | set(DEFAULTS) | SCENARIO_KEYS["form"] | OPTIONAL_KEYS
    unknown = sorted(set(raw) - known)
    if unknown:
        fail(f"unknown slot key(s): {', '.join(unknown)} "
             f"(allowed: {', '.join(sorted(known))})")

    wrong = sorted(set(raw) & SCENARIO_KEYS["form" if scenario == "json" else "json"])
    if wrong:
        fail(f"slot key(s) not valid for scenario '{scenario}': {', '.join(wrong)}")

    required = set(REQUIRED)
    if scenario == "form":
        required = (required - {"createPayload"}) | {"formFields", "idRegex"}
    missing = sorted(k for k in required if k not in raw)
    if missing:
        fail(f"missing required slot(s) for scenario '{scenario}': {', '.join(missing)}")

    slots = {**DEFAULTS, **raw}
    if scenario == "form":
        # idField is a JSON-scenario concept; keep it out of form SLOTS.
        del slots["idField"]

    for key, typ in REQUIRED.items():
        if key in slots and not isinstance(slots[key], typ):
            fail(f"{key} must be a {typ.__name__}")

    if not URL_RE.match(slots["baseUrl"]):
        fail(f"baseUrl must be http(s)://host[:port] with no path or trailing "
             f"slash, got: {slots['baseUrl']!r}")

    if "jarGlob" in slots and (
        not isinstance(slots["jarGlob"], str) or not slots["jarGlob"]
    ):
        fail("jarGlob must be a non-empty string")

    for key in ("createPath", "readPath"):
        if not slots[key].startswith("/"):
            fail(f"{key} must start with '/', got: {slots[key]!r}")
    if "{id}" not in slots["readPath"]:
        fail(f"readPath must contain a '{{id}}' placeholder, got: {slots['readPath']!r}")

    if scenario == "json":
        try:
            payload = json.loads(slots["createPayload"])
        except json.JSONDecodeError as e:
            fail(f"createPayload is not valid JSON: {e}")
        if not isinstance(payload, dict):
            fail("createPayload must be a JSON object (serialized as a string)")

        if not isinstance(slots["idField"], str) or not slots["idField"]:
            fail("idField must be a non-empty string")
    else:
        ff = slots["formFields"]
        if not isinstance(ff, dict) or not ff or not all(
            isinstance(k, str) and k and isinstance(v, str) for k, v in ff.items()
        ):
            fail("formFields must be an object of non-empty string -> string")

        rx = slots["idRegex"]
        if not isinstance(rx, str) or not rx:
            fail("idRegex must be a non-empty string")
        try:
            compiled = re.compile(rx)
        except re.error as e:
            fail(f"idRegex does not compile as a regex: {e}")
        if compiled.groups != 1:
            fail(f"idRegex must have exactly one capture group (the id), "
                 f"got {compiled.groups}")

    for key in ("createStatus", "readStatus"):
        v = slots[key]
        if not isinstance(v, int) or isinstance(v, bool) or not 100 <= v <= 599:
            fail(f"{key} must be an int in [100, 599], got: {v!r}")

    for key in ("entityCount", "vus"):
        v = slots[key]
        if not isinstance(v, int) or isinstance(v, bool) or v < 1:
            fail(f"{key} must be an int >= 1, got: {v!r}")

    for key in ("writeRatio", "errorRateThreshold", "checkRateThreshold"):
        v = slots[key]
        if not isinstance(v, (int, float)) or isinstance(v, bool) or not 0 < v < 1:
            fail(f"{key} must be a number in (0, 1), got: {v!r}")

    v = slots["p95ThresholdMs"]
    if not isinstance(v, (int, float)) or isinstance(v, bool) or v <= 0:
        fail(f"p95ThresholdMs must be a number > 0, got: {v!r}")

    for key in ("duration", "ramp"):
        if not DURATION_RE.match(str(slots[key])):
            fail(f"{key} must look like '30s'/'5m'/'1h', got: {slots[key]!r}")

    if not isinstance(slots["headers"], dict) or not all(
        isinstance(k, str) and isinstance(v, str) for k, v in slots["headers"].items()
    ):
        fail("headers must be an object of string -> string")

    if not isinstance(slots["infra"], list) or not all(
        isinstance(i, str) for i in slots["infra"]
    ):
        fail(f"infra must be a list of {sorted(KNOWN_INFRA)}")
    bad_infra = sorted(set(slots["infra"]) - KNOWN_INFRA)
    if bad_infra:
        fail(f"unknown infra entr{'ies' if len(bad_infra) > 1 else 'y'}: "
             f"{', '.join(bad_infra)} (known: {', '.join(sorted(KNOWN_INFRA))})")

    for key in ("bootEnv", "infraEnv"):
        if not isinstance(slots[key], dict) or not all(
            isinstance(k, str) and isinstance(v, str) for k, v in slots[key].items()
        ):
            fail(f"{key} must be an object of string -> string")

    return slots


def render(template_text, slots):
    if SLOTS_MARKER not in template_text:
        fail(f"template is missing the {SLOTS_MARKER} marker")
    slots_js = "const SLOTS = " + json.dumps(slots, indent=2, sort_keys=True) + ";"
    rendered = template_text.replace(SLOTS_MARKER, slots_js, 1)
    if "__SLOTS__" in rendered:
        fail("render failed: leftover __SLOTS__ marker in output")
    return rendered


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--slots", required=True, help="slots JSON file")
    parser.add_argument("--out", required=True, help="rendered load-test.js path")
    parser.add_argument("--template", default=None,
                        help="template path (default: k6/template.js for scenario "
                             "'json', k6/template-form.js for scenario 'form', "
                             "next to this script)")
    args = parser.parse_args(argv)

    try:
        raw = json.loads(Path(args.slots).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR: cannot read slots file {args.slots}: {e}", file=sys.stderr)
        return 2

    try:
        slots = validate_slots(raw)
    except SlotsError as e:
        print(f"ERROR: invalid slots: {e}", file=sys.stderr)
        return 1

    template_path = args.template
    if template_path is None:
        template_path = str(TEMPLATE_FORM_DEFAULT if slots["scenario"] == "form"
                            else TEMPLATE_DEFAULT)
    try:
        template_text = Path(template_path).read_text(encoding="utf-8")
    except OSError as e:
        print(f"ERROR: cannot read template {template_path}: {e}", file=sys.stderr)
        return 2

    try:
        rendered = render(template_text, slots)
    except SlotsError as e:
        print(f"ERROR: invalid slots: {e}", file=sys.stderr)
        return 1

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # LF always: .gitattributes pins shell/JS evidence to LF.
    out_path.write_text(rendered, encoding="utf-8", newline="\n")
    print(f">> rendered {out_path} (repo={slots['repoName']}, "
          f"create={slots['createPath']} read={slots['readPath']}, "
          f"profile={slots['vus']} VUs {slots['ramp']}+{slots['duration']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
