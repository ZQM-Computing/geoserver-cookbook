# 05 — GeoServer Importer extension workflows for bulk ingest

> Status: **design-only draft — not run, not runtime-validated.**
> Nothing in this pattern claims a run, a validation, or an end-to-end
> deployment. The Importer extension is a separate install from core
> GeoServer; its presence is a prerequisite to confirm, not an
> assumption.

## What it demonstrates

Bulk ingest through the GeoServer Importer extension's REST API:
create an import context from a GeoJSON file, inspect the task the
Importer proposes (target workspace, datastore, layer), run it, and
poll until it finishes. The input is a small synthetic GeoJSON file
so the workflow — not any particular dataset — is what gets tested.

## Prerequisites + versions

- GeoServer 3.0.2 on Node-1 (per seed); Node-4 migrated to 3.0.2
  (2026-10-25). Node-3's current version: **to confirm at validation**.
- Java 21 runtime for GeoServer 3.x.
- GeoServer Importer extension installed on the GeoServer used.
  Extension version: **to confirm at validation** (it must match
  the GeoServer version; a mismatched extension is the first thing
  to check if the `/rest/imports` endpoint 404s).
- PostGIS-backed Postgres as the import target. PostGIS version:
  **to confirm at validation**. Default GeoServer port 8080.
- `curl`, `python3` (only for pretty-printing JSON status; the
  workflow itself is `curl`). Credentials only as placeholders:
  `<GEOSERVER_URL>`, `<ADMIN_USER>`, `<ADMIN_PASSWORD>`,
  `<PG_HOST>`, `<PG_PORT>`, `<PG_DB>`, `<PG_USER>`, `<PG_PASSWORD>`.

## Steps

1. Confirm the Importer endpoint answers:
   `curl -u <ADMIN_USER>:<ADMIN_PASSWORD> <GEOSERVER_URL>/rest/imports`
   — a JSON response (even an empty list) means the extension is
   present; HTTP 404 means it is not installed.
2. Run the import:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   export PG_HOST='<PG_HOST>' PG_PORT='<PG_PORT>' PG_DB='<PG_DB>'
   export PG_USER='<PG_USER>' PG_PASSWORD='<PG_PASSWORD>'
   bash bulk-import.sh
   ```
   The script uploads `inputs/sample-features.geojson` as a file
   import, retargets the task to workspace `synthetic` and the
   PostGIS datastore from pattern 01, runs the import, and polls
   its status.
3. Verify the new layer the same way as pattern 01: WFS
   `GetFeature` on the imported layer returns the synthetic rows.

## Expected output

- The import context create returns HTTP 201 with an import id;
  the script prints the id.
- The task's initial state is `READY` (or equivalent); after the
  run call, polling shows the task moving to `COMPLETE`.
- The imported layer appears in workspace `synthetic` and its
  `GetFeature` response contains the 5 synthetic features from
  `inputs/sample-features.geojson` (names prefixed `Synthetic-`).
- The script prints `IMPORT COMPLETE` and the final task JSON.

## Failure behavior

- **Invalid input:** a malformed GeoJSON file, a file with no
  geometry, or a geometry type the target cannot store makes the
  task state `BAD_FORMAT` / `ERROR` (exact state name is version-
  dependent — record what the version used actually returns).
  The script stops and prints the task's error message; nothing is
  published from a failed task. Fix the file and start a new
  import context — do not re-run a failed task and expect a clean
  retry.
- **No-result case:** a valid but empty GeoJSON feature collection
  imports "successfully" with zero rows. That is not a usable
  layer: the script checks the row count via `GetFeature` and
  reports `EMPTY IMPORT` if it is zero.
- **Missing extension:** HTTP 404 on `/rest/imports` stops the
  script immediately with `IMPORTER NOT INSTALLED`. Installing
  the extension (matching version, restart) is a validator step,
  not something this pattern papers over.

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed. No node, tool run, or output is
cited as evidence, because none exists yet.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run of
`bulk-import.sh` against a named node, GeoServer version, and
Importer extension version (all three recorded), with: the script's
full output, the import id and task JSON, the `GetFeature` response
showing the 5 synthetic rows, and the failure checks above
(malformed file, empty collection, extension absent) each showing
the stated outcome. Until that run record exists, this pattern
stays design-only.
