import importlib.util
import os
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).parents[1] / "examples" / "01-publish-postgis" / "publish.py"
SPEC = importlib.util.spec_from_file_location("geoserver_publish", MODULE_PATH)
publish = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(publish)


class PublishPatternTests(unittest.TestCase):
    def test_workspace_xml_escapes_special_characters(self):
        payload = publish.xml_bytes("workspace", {"name": "parks & trails"})
        self.assertIn(b"parks &amp; trails", payload)
        self.assertNotIn(b"parks & trails", payload)

    def test_datastore_xml_contains_postgis_connection_keys(self):
        config = {
            "store": "reference",
            "pg_host": "db.example.test",
            "pg_port": "5432",
            "pg_database": "gis",
            "pg_schema": "public",
            "pg_user": "readonly",
            "pg_password": "a<&>secret",
        }
        payload = publish.datastore_xml(config)
        self.assertIn(b'key="dbtype">postgis', payload)
        self.assertIn(b"db.example.test", payload)
        self.assertIn(b"a&lt;&amp;&gt;secret", payload)

    def test_feature_type_uses_explicit_native_crs(self):
        payload = publish.feature_type_xml({"table": "roads", "native_crs": "EPSG:26917"})
        self.assertIn(b"<name>roads</name>", payload)
        self.assertIn(b"<nativeName>roads</nativeName>", payload)
        self.assertIn(b"<srs>EPSG:26917</srs>", payload)

    def test_missing_required_environment_variable_fails_closed(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(ValueError, "GEOSERVER_URL"):
                publish.load_config()


if __name__ == "__main__":
    unittest.main()
