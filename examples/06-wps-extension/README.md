# 06 — GeoServer WPS extension setup and a first process

> Status: **design-only draft — not run, not runtime-validated.**
> Nothing in this pattern claims a run, a validation, or an end-to-end
> deployment. The WPS extension is a separate install from core
> GeoServer; its presence is a prerequisite to confirm, not an
> assumption.

## What it demonstrates

Setting up the GeoServer WPS extension and running a first process:
a buffer around a synthetic point, executed through a WPS `Execute`
request. The pattern checks the WPS `GetCapabilities` document first
(so a missing extension fails fast with a clear message), then
posts `inputs/buffer-request.xml` and prints the result geometry.

## Prerequisites + versions

- GeoServer 3.0.2 on Node-1 (per seed); Node-4 migrated to 3.0.2
  (2026-10-25). Node-3's current version: **to confirm at validation**.
- Java 21 runtime for GeoServer 3.x.
- GeoServer WPS extension installed on the GeoServer used.
  Extension version: **to confirm at validation** (it must match
  the GeoServer version; a mismatched extension is the first thing
  to check if the WPS endpoint 404s or the process list is empty).
- Default GeoServer port 8080.
- `curl`. Credentials only as placeholders:
  `<GEOSERVER_URL>`, `<ADMIN_USER>`, `<ADMIN_PASSWORD>`.
  Note: WPS `Execute` may be open to anonymous users depending on
  the server's security settings — see pattern 07 before leaving
  it that way; this pattern authenticates its requests either way.

## Steps

1. Confirm the WPS endpoint answers:
   `curl <GEOSERVER_URL>/wps?service=WPS&request=GetCapabilities`
   — the document must list a buffer process (commonly
   `JTS:buffer`). If it 404s, the extension is not installed.
2. Run the first process:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   bash run-wps-process.sh
   ```
   The script posts `inputs/buffer-request.xml` (buffer distance
   0.01 degrees around synthetic point (-80.0, 29.0)) and prints
   the response.
3. Confirm the response is a polygon geometry enclosing the input
   point, not an exception document.

## Expected output

- The `GetCapabilities` check prints `OK` and names the buffer
  process found.
- The `Execute` response returns HTTP 200 with a WPS
  `ExecuteResponse` containing a polygon result (GML), and the
  script prints `OK` plus the response.
- The result polygon contains the input point (-80.0, 29.0) and
  extends roughly 0.01 degrees from it in every direction.
  (Degrees are not metres — this is a geometry demonstration, not
  a measurement workflow; reproject first for real distances.)

## Failure behavior

- **Invalid input:** a negative buffer distance, a non-numeric
  distance, or malformed XML makes the process return a WPS
  exception (`InvalidParameterValue` or a parse exception) and
  the script stops, printing the exception text. No partial
  geometry is returned as if it were a result.
- **No-result case:** WPS processes either return a result or an
  exception — there is no "empty success" for buffer. If the
  response contains no geometry and no exception, treat it as a
  version-behavior difference: record the raw response verbatim
  and the GeoServer/WPS versions, and do not claim the process ran.
- **Missing extension:** HTTP 404 on the WPS endpoint, or a
  capabilities document with no processes, stops the script with
  `WPS NOT INSTALLED`. Installing the extension (matching
  version, restart) is a validator step, not something this
  pattern papers over.

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed. No node, tool run, or output is
cited as evidence, because none exists yet.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run of
`run-wps-process.sh` against a named node, GeoServer version, and
WPS extension version (all three recorded), with: the script's
full output, the `GetCapabilities` process list excerpt showing
the buffer process, and the `ExecuteResponse` polygon — plus the
failure checks above (negative distance, malformed XML, extension
absent) each showing the stated outcome. Until that run record
exists, this pattern stays design-only.
