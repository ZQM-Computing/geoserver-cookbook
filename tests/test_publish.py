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

    def test_remote_http_geoserver_url_fails_closed(self):
        with patch.dict(os.environ, {
            "GEOSERVER_URL": "http://geoserver.example.test/geoserver",
            "GEOSERVER_USER": "admin",
            "GEOSERVER_PASSWORD": "secret",
            "GEOSERVER_WORKSPACE": "ci",
            "GEOSERVER_STORE": "postgis",
            "POSTGIS_TABLE": "places",
            "POSTGIS_HOST": "db.example.test",
            "POSTGIS_DATABASE": "gis",
            "POSTGIS_USER": "readonly",
            "POSTGIS_PASSWORD": "secret",
        }, clear=True):
            with self.assertRaisesRegex(ValueError, "must use HTTPS"):
                publish.load_config()

    def test_local_http_geoserver_is_allowed_for_development(self):
        with patch.dict(os.environ, {
            "GEOSERVER_URL": "http://127.0.0.1:8080/geoserver",
            "GEOSERVER_USER": "admin",
            "GEOSERVER_PASSWORD": "secret",
            "GEOSERVER_WORKSPACE": "ci",
            "GEOSERVER_STORE": "postgis",
            "POSTGIS_TABLE": "places",
            "POSTGIS_HOST": "127.0.0.1",
            "POSTGIS_DATABASE": "gis",
            "POSTGIS_USER": "readonly",
            "POSTGIS_PASSWORD": "secret",
        }, clear=True):
            self.assertEqual(publish.load_config()["base_url"], "http://127.0.0.1:8080/geoserver")

    def test_url_credentials_and_query_are_rejected(self):
        for url, message in (
            ("https://admin:secret@geoserver.example.test/geoserver", "must not embed credentials"),
            ("https://geoserver.example.test/geoserver?token=secret", "must not include a query string"),
            ("https://geoserver.example.test/geoserver#fragment", "must not include a query string"),
        ):
            with self.subTest(url=url), patch.dict(os.environ, {
                "GEOSERVER_URL": url,
                "GEOSERVER_USER": "admin",
                "GEOSERVER_PASSWORD": "secret",
                "GEOSERVER_WORKSPACE": "ci",
                "GEOSERVER_STORE": "postgis",
                "POSTGIS_TABLE": "places",
                "POSTGIS_HOST": "db.example.test",
                "POSTGIS_DATABASE": "gis",
                "POSTGIS_USER": "readonly",
                "POSTGIS_PASSWORD": "secret",
            }, clear=True):
                with self.assertRaisesRegex(ValueError, message):
                    publish.load_config()


if __name__ == "__main__":
    unittest.main()
