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

    def test_security_pattern_includes_audit_checks(self):
        security = EXAMPLES / "07-security-basics"
        self.assertTrue((security / "apply-access-rules.sh").is_file())
        self.assertTrue((security / "inputs" / "audit-checks.sh").is_file())
        self.assertTrue((security / "inputs" / "security-checklist.md").is_file())


if __name__ == "__main__":
    unittest.main()
