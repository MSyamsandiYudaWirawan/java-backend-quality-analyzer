#!/usr/bin/env python3
"""Unit tests for service/advanced/gen-k6.py (h2 k6 generator).

Fast and offline: no k6, no docker. Run from the repo root:
  python tests/unit/test_gen_k6.py
"""

import importlib.util
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "gen_k6", REPO_ROOT / "service" / "advanced" / "gen-k6.py")
gen_k6 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen_k6)

VALID_SLOTS = {
    "repoName": "demo-repo",
    "baseUrl": "http://target:8080",
    "createPath": "/api/items",
    "createPayload": '{"name": "Item-__UNIQ__"}',
    "readPath": "/api/items/{id}",
    "infra": ["postgres"],
    "bootEnv": {"SPRING_DATASOURCE_URL": "jdbc:postgresql://postgres:5432/mydb"},
}

VALID_FORM_SLOTS = {
    "repoName": "demo-form",
    "baseUrl": "http://target:8080",
    "scenario": "form",
    "createPath": "/owners/new",
    "createStatus": 302,
    "formFields": {"firstName": "k6-__UNIQ__", "lastName": "loadtest"},
    "idRegex": "/owners/(\\d+)",
    "readPath": "/owners/{id}",
}


def render(slots):
    template = (REPO_ROOT / "service" / "advanced" / "k6" / "template.js").read_text(
        encoding="utf-8")
    return gen_k6.render(template, gen_k6.validate_slots(slots))


def render_form(slots):
    template = (REPO_ROOT / "service" / "advanced" / "k6" / "template-form.js").read_text(
        encoding="utf-8")
    return gen_k6.render(template, gen_k6.validate_slots(slots))


class TestValidation(unittest.TestCase):
    def test_valid_slots_pass_with_defaults_applied(self):
        slots = gen_k6.validate_slots(dict(VALID_SLOTS))
        self.assertEqual(slots["idField"], "id")
        self.assertEqual(slots["createStatus"], 201)
        self.assertEqual(slots["vus"], 200)
        self.assertEqual(slots["infra"], ["postgres"])

    def test_missing_required_key_rejected(self):
        for key in gen_k6.REQUIRED:
            bad = {k: v for k, v in VALID_SLOTS.items() if k != key}
            with self.assertRaises(gen_k6.SlotsError, msg=key):
                gen_k6.validate_slots(bad)

    def test_unknown_key_rejected(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "sneaky": "value"})

    def test_read_path_must_have_id_placeholder(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "readPath": "/api/items"})

    def test_create_payload_must_be_json_object(self):
        for bad in ("not json", '["array"]', '"string"', "123"):
            with self.assertRaises(gen_k6.SlotsError, msg=bad):
                gen_k6.validate_slots({**VALID_SLOTS, "createPayload": bad})

    def test_base_url_must_be_origin_only(self):
        for bad in ("target:8080", "http://target:8080/", "http://target:8080/api"):
            with self.assertRaises(gen_k6.SlotsError, msg=bad):
                gen_k6.validate_slots({**VALID_SLOTS, "baseUrl": bad})

    def test_status_out_of_range_rejected(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "createStatus": 99})

    def test_duration_format_enforced(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "duration": "fast"})

    def test_unknown_infra_rejected(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "infra": ["kafka"]})

    def test_boot_env_values_must_be_strings(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "bootEnv": {"PORT": 8080}})

    def test_jar_glob_accepted_in_both_scenarios(self):
        slots = gen_k6.validate_slots({**VALID_SLOTS, "jarGlob": "app-*.jar"})
        self.assertEqual(slots["jarGlob"], "app-*.jar")
        slots = gen_k6.validate_slots({**VALID_FORM_SLOTS, "jarGlob": "app-*.jar"})
        self.assertEqual(slots["jarGlob"], "app-*.jar")

    def test_jar_glob_must_be_non_empty_string(self):
        for bad in ("", 42):
            with self.assertRaises(gen_k6.SlotsError, msg=repr(bad)):
                gen_k6.validate_slots({**VALID_SLOTS, "jarGlob": bad})

    def test_jar_glob_absent_means_unset(self):
        self.assertNotIn("jarGlob", gen_k6.validate_slots(dict(VALID_SLOTS)))


class TestFormValidation(unittest.TestCase):
    def test_valid_form_slots_pass_with_defaults_applied(self):
        slots = gen_k6.validate_slots(dict(VALID_FORM_SLOTS))
        self.assertEqual(slots["scenario"], "form")
        self.assertEqual(slots["createStatus"], 302)
        self.assertEqual(slots["readStatus"], 200)
        self.assertNotIn("idField", slots)
        self.assertNotIn("createPayload", slots)

    def test_form_missing_required_key_rejected(self):
        for key in ("repoName", "baseUrl", "createPath", "readPath",
                    "formFields", "idRegex"):
            bad = {k: v for k, v in VALID_FORM_SLOTS.items() if k != key}
            with self.assertRaises(gen_k6.SlotsError, msg=key):
                gen_k6.validate_slots(bad)

    def test_id_regex_needs_exactly_one_capture_group(self):
        for bad in (r"/owners/\d+", r"/(owners)/(\d+)", "/owners/("):
            with self.assertRaises(gen_k6.SlotsError, msg=bad):
                gen_k6.validate_slots({**VALID_FORM_SLOTS, "idRegex": bad})

    def test_form_fields_values_must_be_strings(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots(
                {**VALID_FORM_SLOTS, "formFields": {"firstName": 42}})

    def test_bad_scenario_rejected(self):
        for bad in ("graphql", "", 1):
            with self.assertRaises(gen_k6.SlotsError, msg=repr(bad)):
                gen_k6.validate_slots({**VALID_FORM_SLOTS, "scenario": bad})

    def test_json_keys_rejected_in_form_mode(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots(
                {**VALID_FORM_SLOTS, "createPayload": '{"name": "x"}'})
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_FORM_SLOTS, "idField": "id"})

    def test_form_keys_rejected_in_json_mode(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots(
                {**VALID_SLOTS, "formFields": {"a": "b"}})
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.validate_slots({**VALID_SLOTS, "idRegex": "/x/(\\d+)"})


class TestFormRender(unittest.TestCase):
    def test_output_has_slots_and_no_marker(self):
        out = render_form(VALID_FORM_SLOTS)
        self.assertIn("const SLOTS = ", out)
        self.assertNotIn("__SLOTS__", out)

    def test_slots_contain_form_fields_and_id_regex(self):
        out = render_form(VALID_FORM_SLOTS)
        m = re.search(r"const SLOTS = (\{.*?\});", out, re.DOTALL)
        self.assertIsNotNone(m)
        slots = json.loads(m.group(1))
        self.assertEqual(slots["formFields"], VALID_FORM_SLOTS["formFields"])
        self.assertEqual(slots["idRegex"], VALID_FORM_SLOTS["idRegex"])

    def test_form_script_has_redirect_and_location_extraction(self):
        out = render_form(VALID_FORM_SLOTS)
        self.assertIn("redirects: 0", out)
        self.assertIn("res.headers['Location']", out)
        self.assertIn("application/x-www-form-urlencoded", out)
        self.assertNotIn("createPayload", out)


class TestRender(unittest.TestCase):
    def test_output_has_slots_and_no_marker(self):
        out = render(VALID_SLOTS)
        self.assertIn("const SLOTS = ", out)
        self.assertNotIn("__SLOTS__", out)

    def test_deterministic(self):
        self.assertEqual(render(VALID_SLOTS), render(VALID_SLOTS))

    def test_slots_round_trip(self):
        out = render(VALID_SLOTS)
        m = re.search(r"const SLOTS = (\{.*?\});", out, re.DOTALL)
        self.assertIsNotNone(m)
        self.assertEqual(json.loads(m.group(1)), gen_k6.validate_slots(dict(VALID_SLOTS)))

    def test_template_without_marker_fails(self):
        with self.assertRaises(gen_k6.SlotsError):
            gen_k6.render("no marker here", gen_k6.validate_slots(dict(VALID_SLOTS)))


class TestCli(unittest.TestCase):
    def test_missing_slots_file_exits_2(self):
        self.assertEqual(
            gen_k6.main(["--slots", "no-such-file.json", "--out", "x.js"]), 2)

    def test_invalid_slots_exits_1(self):
        with tempfile.TemporaryDirectory() as d:
            slots = Path(d) / "slots.json"
            slots.write_text(json.dumps({"repoName": "x"}), encoding="utf-8")
            self.assertEqual(
                gen_k6.main(["--slots", str(slots), "--out", str(Path(d) / "out.js")]), 1)

    def test_valid_cli_writes_rendered_file(self):
        with tempfile.TemporaryDirectory() as d:
            slots = Path(d) / "slots.json"
            out = Path(d) / "load-test.js"
            slots.write_text(json.dumps(VALID_SLOTS), encoding="utf-8")
            self.assertEqual(
                gen_k6.main(["--slots", str(slots), "--out", str(out)]), 0)
            text = out.read_text(encoding="utf-8")
            self.assertIn("const SLOTS = ", text)
            self.assertNotIn("__SLOTS__", text)

    def test_form_scenario_selects_form_template_by_default(self):
        with tempfile.TemporaryDirectory() as d:
            slots = Path(d) / "slots.json"
            out = Path(d) / "load-test.js"
            slots.write_text(json.dumps(VALID_FORM_SLOTS), encoding="utf-8")
            self.assertEqual(
                gen_k6.main(["--slots", str(slots), "--out", str(out)]), 0)
            text = out.read_text(encoding="utf-8")
            self.assertIn("redirects: 0", text)
            self.assertNotIn("__SLOTS__", text)


if __name__ == "__main__":
    unittest.main()
