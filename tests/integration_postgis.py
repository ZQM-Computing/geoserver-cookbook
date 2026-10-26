#!/usr/bin/env python3
"""Disposable GeoServer/PostGIS end-to-end smoke test for CI.

Creates a synthetic table in a disposable PostGIS database, runs the cookbook
publisher, then confirms GeoServer can query and return the seeded feature.
"""
from __future__ import annotations

import base64
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
            cur.execute(
                "CREATE TABLE public.places "
                "(id integer PRIMARY KEY, name text NOT NULL, "
                "geom geometry(Point, 4326) NOT NULL)"
            )
            cur.execute(
                "INSERT INTO public.places (id, name, geom) VALUES "
                "(1, %s, ST_SetSRID(ST_MakePoint(-80.9, 29.0), 4326))",
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
    # Inspect the REST representation as well as the WFS payload: a feature
    # being queryable does not prove GeoServer retained the intended CRS/extent.
    feature_type_url = (
        base_url
        + "/rest/workspaces/ci/datastores/postgis_ci/featuretypes/places.json"
    )
    auth_token = base64.b64encode((username + ":" + password).encode()).decode()
    feature_type_request = urllib.request.Request(
        feature_type_url,
        headers={"Authorization": "Basic " + auth_token, "Accept": "application/json"},
    )
    with urllib.request.urlopen(feature_type_request, timeout=30) as response:
        if response.status != 200:
            raise RuntimeError(f"GeoServer feature-type inspection returned HTTP {response.status}")
        feature_type_payload = json.loads(response.read().decode("utf-8"))
    feature_type = feature_type_payload.get("featureType", feature_type_payload)
    native_bbox = feature_type.get("nativeBoundingBox")
    if not isinstance(native_bbox, dict):
        raise AssertionError("GeoServer feature type has no nativeBoundingBox")
    try:
        bounds = {key: float(native_bbox[key]) for key in ("minx", "maxx", "miny", "maxy")}
    except (KeyError, TypeError, ValueError) as exc:
        raise AssertionError(f"GeoServer nativeBoundingBox has invalid coordinates: {native_bbox}") from exc
    # GeoServer expands zero-area point extents by a small display margin. Require
    # the known point to be contained and the resulting envelope to stay narrow.
    if not (bounds["minx"] <= -80.9 <= bounds["maxx"] and bounds["miny"] <= 29.0 <= bounds["maxy"]):
        raise AssertionError(f"GeoServer nativeBoundingBox does not contain the seeded point: {bounds}")
    if bounds["maxx"] - bounds["minx"] > 0.01 or bounds["maxy"] - bounds["miny"] > 0.01:
        raise AssertionError(f"GeoServer nativeBoundingBox is unexpectedly broad for one point: {bounds}")
    native_crs = str(native_bbox.get("crs", ""))
    if "4326" not in native_crs:
        raise AssertionError(f"Expected EPSG:4326 native extent, got CRS {native_crs!r}")

    geometry = features[0].get("geometry") or {}
    coordinates = geometry.get("coordinates")
    if geometry.get("type") != "Point" or not isinstance(coordinates, list) or len(coordinates) < 2:
        raise AssertionError(f"Expected Point geometry with coordinates, got {geometry}")
    if abs(float(coordinates[0]) - (-80.9)) > 1e-6 or abs(float(coordinates[1]) - 29.0) > 1e-6:
        raise AssertionError(f"Published geometry coordinates do not match the seeded fixture: {coordinates}")
    print(
        "GeoServer/PostGIS integration passed: workspace, datastore, layer, WFS feature, "
        "native CRS, and native extent verified."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
