# 02 — SLD styles for points, lines, and polygons, with scale-dependent rules

> Status: **design-only draft — not run, not runtime-validated.**
> Nothing in this pattern claims a run, a validation, or an end-to-end
> deployment.

## What it demonstrates

Three SLD styles in one file (`inputs/styles.sld`): a point style, a
line style, and a polygon style, each with scale-dependent rules so
symbols change (or disappear) as the map zooms. The script uploads
the styles through the GeoServer REST API and assigns each to a layer
of the matching geometry type. A scale rule is demonstrated, not just
asserted: the point style draws small markers at small scales and
larger labelled markers at large scales.

## Prerequisites + versions

- GeoServer 3.0.2 on Node-1 (per seed); Node-4 migrated to 3.0.2
  (2026-10-25). Node-3's current version: **to confirm at validation**.
- Java 21 runtime for GeoServer 3.x.
- PostGIS-backed Postgres. PostGIS version: **to confirm at validation**.
- Default GeoServer port 8080.
- Pattern 01 completed first (workspace `synthetic` exists), or an
  equivalent workspace with one point, one line, and one polygon
  layer. Layer names are placeholders the validator sets:
  `<POINT_LAYER>`, `<LINE_LAYER>`, `<POLYGON_LAYER>`.
- `curl`. Credentials only as placeholders:
  `<GEOSERVER_URL>`, `<ADMIN_USER>`, `<ADMIN_PASSWORD>`.

## Steps

1. (Optional) Create synthetic point/line/polygon tables:
   `psql -h <PG_HOST> -d <PG_DB> -U <PG_USER> -f inputs/sample-features.sql`,
   then publish them as in pattern 01.
2. Upload and assign the styles:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   export POINT_LAYER='<POINT_LAYER>' LINE_LAYER='<LINE_LAYER>' POLYGON_LAYER='<POLYGON_LAYER>'
   bash upload-style.sh
   ```
   The script creates styles `synthetic_points`, `synthetic_lines`,
   `synthetic_polygons` in workspace `synthetic` and sets each as its
   layer's default style.
3. Render a check map at two scales: one WMS `GetMap` with a wide
   bounding box (small scale) and one zoomed in (large scale), using
   the URLs the script prints.

## Expected output

- Each style upload returns HTTP 201 (or 200 on re-upload) and the
  script prints `OK` per style and per layer assignment.
- `GET <GEOSERVER_URL>/rest/workspaces/synthetic/styles/<name>.sld`
  returns the uploaded SLD for each of the three styles.
- The small-scale `GetMap` shows small point markers and no point
  labels; the large-scale `GetMap` shows larger markers with labels.
  Line widths and polygon fills render as defined in the SLD.
- Scale denominators used: points switch at 1:50,000; lines thicken
  below 1:25,000; polygons drop their outline above 1:100,000.
  (Exact numbers are in `inputs/styles.sld`; a validator records any
  version-driven rendering difference instead of silently adjusting.)

## Failure behavior

- **Invalid input:** an SLD with malformed XML, or a rule naming a
  property the layer does not carry, is rejected by GeoServer
  (HTTP 400, with a validation message) and the script stops; no
  half-applied style is left as the layer default, because assignment
  happens only after a successful upload. Fix the SLD and re-run.
- **No-result case:** assigning a point style to a polygon layer (or
  any geometry mismatch) does not error at upload time but renders
  nothing for that layer's features. If a `GetMap` comes back blank
  for a layer that has data, check the style/geometry pairing first.
- **Missing layer:** assigning to a layer name that does not exist
  returns HTTP 404 and the script stops at that step.

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed. No node, tool run, or output is
cited as evidence, because none exists yet.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run of
`upload-style.sh` against a named node and GeoServer version
(GeoServer 3.0.2 on Node-1 first; Node-3's version to confirm at
validation), with: the script's full output, the three uploaded SLDs
retrieved back from the server, and two `GetMap` images (small-scale
and large-scale) showing the scale-rule switch — plus the malformed-
SLD rejection and the geometry-mismatch blank-map checks above.
Until that run record exists, this pattern stays design-only.
