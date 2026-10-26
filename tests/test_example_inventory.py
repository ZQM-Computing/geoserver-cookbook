import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
EXAMPLES = ROOT / "examples"
EXPECTED = {
    "01-publish-postgis",
    "02-sld-styling",
    "03-federation-virtual-service",
    "04-federation-layer-group",
    "05-importer-extension",
    "06-wps-extension",
    "07-security-basics",
}


class ExampleInventoryTests(unittest.TestCase):
    def test_all_seven_patterns_are_present(self):
        actual = {path.name for path in EXAMPLES.iterdir() if path.is_dir()}
        self.assertEqual(actual, EXPECTED)

    def test_each_pattern_has_readme_and_executable_example(self):
        for name in sorted(EXPECTED):
            with self.subTest(pattern=name):
                directory = EXAMPLES / name
                self.assertTrue((directory / "README.md").is_file())
                entrypoints = list(directory.glob("*.sh")) + list(directory.glob("*.py"))
                self.assertTrue(entrypoints, f"{name} has no shell or Python entrypoint")

    def test_http_responses_are_not_truncated_through_curl_pipelines(self):
        for relative in (
            "examples/03-federation-virtual-service/configure-virtual-service.sh",
            "examples/04-federation-layer-group/create-layer-group.sh",
            "examples/07-security-basics/apply-access-rules.sh",
        ):
            with self.subTest(script=relative):
                text = (ROOT / relative).read_text(encoding="utf-8")
                self.assertNotIn("| grep -q", text)
                self.assertNotIn("| head -c", text)
                self.assertIn("mktemp -d", text)

    def test_security_password_payload_escapes_credentials(self):
        import json
        import os
        import subprocess
        import tempfile

        helper = EXAMPLES / "07-security-basics" / "inputs" / "build-user-payload.py"
        password = 'quotes-" backslash-\\ unicode-ñ'
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "payload.json"
            env = os.environ.copy()
            env["GEOSERVER_ADMIN_USER"] = 'admin-"operator'
            env["NEW_ADMIN_PASSWORD"] = password
            subprocess.run(
                ["python3", str(helper), str(output)],
                env=env,
                check=True,
                capture_output=True,
                text=True,
            )
            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(payload["user"]["userName"], 'admin-"operator')
            self.assertEqual(payload["user"]["password"], password)
            self.assertIs(payload["user"]["enabled"], True)
            if os.name == "posix":
                self.assertEqual(output.stat().st_mode & 0o777, 0o600)

    def test_security_script_uses_serialized_payload_not_interpolated_password(self):
        script = (EXAMPLES / "07-security-basics" / "apply-access-rules.sh").read_text(encoding="utf-8")
        self.assertIn('build-user-payload.py', script)
        self.assertIn('--data-binary "@${TMP_DIR}/user-update.json"', script)
        self.assertNotIn('password\\":\\"${NEW_ADMIN_PASSWORD}', script)

    def test_security_pattern_includes_audit_checks(self):
        security = EXAMPLES / "07-security-basics"
        self.assertTrue((security / "apply-access-rules.sh").is_file())
        self.assertTrue((security / "inputs" / "audit-checks.sh").is_file())
        self.assertTrue((security / "inputs" / "security-checklist.md").is_file())


if __name__ == "__main__":
    unittest.main()
