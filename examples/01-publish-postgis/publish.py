#!/usr/bin/env python3
"""Publish a PostGIS table to GeoServer through the REST API.

This example only creates missing resources. It never deletes or overwrites
existing workspaces, stores, or feature types.
"""
from __future__ import annotations

import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise ValueError(f"Required environment variable is missing: {name}")
    return value


def xml_bytes(root_name: str, values: dict[str, str]) -> bytes:
    """Build escaped GeoServer REST XML; ElementTree escapes XML metacharacters."""
    root = ET.Element(root_name)
    for key, value in values.items():
        child = ET.SubElement(root, key)
        child.text = value
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def datastore_xml(config: dict[str, str]) -> bytes:
    root = ET.Element("dataStore")
    ET.SubElement(root, "name").text = config["store"]
    params = ET.SubElement(root, "connectionParameters")
    values = {
        "dbtype": "postgis",
        "host": config["pg_host"],
        "port": config["pg_port"],
        "database": config["pg_database"],
        "schema": config["pg_schema"],
        "user": config["pg_user"],
        "passwd": config["pg_password"],
        "validate connections": "true",
    }
    for key, value in values.items():
        entry = ET.SubElement(params, "entry", {"key": key})
        entry.text = value
    ET.SubElement(root, "enabled").text = "true"
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def feature_type_xml(config: dict[str, str]) -> bytes:
    root = ET.Element("featureType")
    ET.SubElement(root, "name").text = config["table"]
    ET.SubElement(root, "nativeName").text = config["table"]
    ET.SubElement(root, "srs").text = config["native_crs"]
    ET.SubElement(root, "enabled").text = "true"
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


class GeoServer:
    def __init__(self, base_url: str, username: str, password: str) -> None:
        self.base_url = base_url.rstrip("/") + "/rest"
        token = (username + ":" + password).encode("utf-8")
        import base64

        self.authorization = "Basic " + base64.b64encode(token).decode("ascii")

    def request(self, method: str, path: str, body: bytes | None = None) -> int:
        request = urllib.request.Request(
            self.base_url + path,
            data=body,
            method=method,
            headers={
                "Authorization": self.authorization,
                "Accept": "application/xml",
                "Content-Type": "application/xml",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.status
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return 404
            # Do not print server response bodies: they may contain connection details.
            raise RuntimeError(
                f"GeoServer REST request {method} {path} failed with HTTP {exc.code}"
            ) from None
        except urllib.error.URLError as exc:
            raise RuntimeError(
                f"GeoServer REST request {method} {path} could not connect: {exc.reason}"
            ) from None

    def create_if_missing(self, resource_path: str, collection_path: str, payload: bytes) -> str:
        status = self.request("GET", resource_path)
        if status == 200:
            return "already exists"
        if status != 404:
            raise RuntimeError(f"Unexpected HTTP status {status} while checking {resource_path}")
        status = self.request("POST", collection_path, payload)
        if status not in (200, 201):
            raise RuntimeError(f"Unexpected HTTP status {status} while creating {resource_path}")
        return "created"


def load_config() -> dict[str, str]:
    config = {
        "base_url": required_env("GEOSERVER_URL"),
        "username": required_env("GEOSERVER_USER"),
        "password": required_env("GEOSERVER_PASSWORD"),
        "workspace": required_env("GEOSERVER_WORKSPACE"),
        "store": required_env("GEOSERVER_STORE"),
        "table": required_env("POSTGIS_TABLE"),
        "pg_host": required_env("POSTGIS_HOST"),
        "pg_port": os.environ.get("POSTGIS_PORT", "5432").strip(),
        "pg_database": required_env("POSTGIS_DATABASE"),
        "pg_schema": os.environ.get("POSTGIS_SCHEMA", "public").strip(),
        "pg_user": required_env("POSTGIS_USER"),
        "pg_password": required_env("POSTGIS_PASSWORD"),
        "native_crs": os.environ.get("POSTGIS_NATIVE_CRS", "EPSG:4326").strip(),
    }
    for key in ("workspace", "store", "table", "pg_schema"):
        if not config[key] or "/" in config[key]:
            raise ValueError(f"Invalid identifier in configuration: {key}")
    parsed = urllib.parse.urlparse(config["base_url"])
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError("GEOSERVER_URL must be an absolute http:// or https:// URL")
    if not config["pg_port"].isdigit():
        raise ValueError("POSTGIS_PORT must be a numeric TCP port")
    return config


def main() -> int:
    try:
        config = load_config()
        client = GeoServer(
            config["base_url"], config["username"], config["password"]
        )
        workspace = urllib.parse.quote(config["workspace"], safe="")
        store = urllib.parse.quote(config["store"], safe="")
        table = urllib.parse.quote(config["table"], safe="")

        steps = [
            (
                "workspace",
                f"/workspaces/{workspace}.xml",
                "/workspaces",
                xml_bytes("workspace", {"name": config["workspace"]}),
            ),
            (
                "PostGIS datastore",
                f"/workspaces/{workspace}/datastores/{store}.xml",
                f"/workspaces/{workspace}/datastores",
                datastore_xml(config),
            ),
            (
                "feature type",
                f"/workspaces/{workspace}/datastores/{store}/featuretypes/{table}.xml",
                f"/workspaces/{workspace}/datastores/{store}/featuretypes",
                feature_type_xml(config),
            ),
        ]
        for label, resource_path, collection_path, payload in steps:
            result = client.create_if_missing(resource_path, collection_path, payload)
            print(f"{label}: {result}")
        print("Publication request complete. Verify layer access, CRS, permissions, and data exposure before use.")
        return 0
    except (ValueError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
