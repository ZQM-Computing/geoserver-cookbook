#!/usr/bin/env python3
"""Disposable GeoServer/PostGIS end-to-end smoke test for CI.

Creates a synthetic table in a disposable PostGIS database, runs the cookbook
publisher, then confirms GeoServer can query and return the seeded feature.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import psycopg


def wait_for_geoserver(base_url: str, username: str, password: str) -> None:
    url = base_url.rstrip("/") + "/rest/about/version.xml"
    token = (username + ":" + password).encode()
    import base64

    headers = {"Authorization": "Basic " + base64.b64encode(token).decode()}
    deadline = time.monotonic() + 240
    last_error = "no response"
    while time.monotonic() < deadline:
        try:
            request = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(request, timeout=5) as response:
                if response.status == 200:
                    return
                last_error = f"HTTP {response.status}"
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error = str(exc)
        time.sleep(5)
    raise RuntimeError(f"GeoServer did not become ready within 240 seconds: {last_error}")


def main() -> int:
    base_url = os.environ["GEOSERVER_URL"].rstrip("/")
    username = os.environ["GEOSERVER_USER"]
    password = os.environ["GEOSERVER_PASSWORD"]
    pg_conninfo = {
        "host": os.environ["POSTGIS_HOST_FOR_TEST"],
        "port": int(os.environ.get("POSTGIS_PORT", "5432")),
        "dbname": os.environ["POSTGIS_DATABASE"],
        "user": os.environ["POSTGIS_USER"],
        "password": os.environ["POSTGIS_PASSWORD"],
    }

    wait_for_geoserver(base_url, username, password)
    with psycopg.connect(**pg_conninfo) as conn:
        with conn.cursor() as cur:
            cur.execute("CREATE EXTENSION IF NOT EXISTS postgis")
            cur.execute("CREATE TABLE IF NOT EXISTS public.places (id integer PRIMARY KEY, name text NOT NULL, geom geometry(Point, 4326) NOT NULL)")
            cur.execute("TRUNCATE TABLE public.places")
            cur.execute(
                "INSERT INTO public.places (id, name, geom) VALUES (1, %s, ST_SetSRID(ST_MakePoint(-80.9, 29.0), 4326))",
                ("geoserver-ci-fixture",),
            )

    env = os.environ.copy()
    env.update(
        {
            "GEOSERVER_WORKSPACE": "ci",
            "GEOSERVER_STORE": "postgis_ci",
            "POSTGIS_TABLE": "places",
            "POSTGIS_HOST": "postgres",
            "POSTGIS_PORT": "5432",
            "POSTGIS_SCHEMA": "public",
            "POSTGIS_NATIVE_CRS": "EPSG:4326",
        }
    )
    subprocess.run(
        [sys.executable, "examples/01-publish-postgis/publish.py"],
        check=True,
        env=env,
        timeout=180,
    )

    query = urllib.parse.urlencode(
        {
            "service": "WFS",
            "version": "2.0.0",
            "request": "GetFeature",
            "typeNames": "ci:places",
            "outputFormat": "application/json",
        }
    )
    request = urllib.request.Request(
        base_url + "/ows?" + query,
        headers={"Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=45) as response:
        if response.status != 200:
            raise RuntimeError(f"WFS GetFeature returned HTTP {response.status}")
        payload = json.loads(response.read().decode("utf-8"))
    features = payload.get("features", [])
    if len(features) != 1:
        raise AssertionError(f"Expected one published feature, received {len(features)}")
    properties = features[0].get("properties", {})
    if properties.get("name") != "geoserver-ci-fixture":
        raise AssertionError("Published feature properties do not match the seeded fixture")
    print("GeoServer/PostGIS integration passed: workspace, datastore, layer, and WFS feature verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
