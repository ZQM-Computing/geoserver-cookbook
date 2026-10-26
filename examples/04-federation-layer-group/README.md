# 04 — Federation via layer group: byte-identical against the virtual-service path

> Status: **design-only draft — not run, not runtime-validated.**
> Honesty note: like pattern 03, this draft claims no federation
> result from any node pair. The "byte-identical" bar below is a
> **test to run**, not a result achieved. If the comparison fails,
> the pattern records the difference — it does not claim identity.

## What it demonstrates

The second federation path: instead of exposing a cascaded layer
directly (pattern 03's virtual-service path), the serving node wraps
the cascaded layer(s) in a **layer group** and serves the group as a
single named layer. Clients then request the group name, not the
cascaded layer name. The pattern's real content is the comparison
procedure: the same bounding box, image size, CRS, format, and style
requested through (a) the virtual-service path and (b) the layer-
group path, with SHA-256 hashes compared. Identical bytes would show
the two paths render the same picture; any difference must be
investigated (style defaults, layer order, transparency, and
server-side rendering settings are the usual suspects).

## Prerequisites + versions

- Pattern 03 completed first on the same serving node (workspace
  `federated`, cascaded layer from the remote node exists).
- Both nodes' versions: **to confirm at validation** for the pair
  actually used. Known version facts only: GeoServer 3.0.2 on Node-1
  (per seed); Node-4 migrated to 3.0.2 (2026-10-25); Node-3's
  current version: **to confirm at validation**. Java 21 runtime
  for GeoServer 3.x. Default GeoServer port 8080.
- `curl`, `sha256sum`. Credentials only as placeholders:
  `<GEOSERVER_URL>`, `<ADMIN_USER>`, `<ADMIN_PASSWORD>`,
  `<REMOTE_LAYER>`.

## Steps

1. Create the layer group on the serving node:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   export REMOTE_LAYER='<REMOTE_LAYER>'
   bash create-layer-group.sh
   ```
   This creates group `federated_group` in workspace `federated`
   containing the cascaded layer, using `inputs/layer-group.json`
   as the template.
2. Run the byte comparison:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export REMOTE_LAYER='<REMOTE_LAYER>'
   bash inputs/compare-outputs.sh
   ```
   It fetches the same map through both paths and prints both
   SHA-256 hashes and a MATCH / DIFFER verdict.
3. If the verdict is DIFFER, work the checklist in the script's
   output notes (default style on the group vs the layer, layer
   order, `transparent` flag, image format) and re-run. Record the
   cause and the fix; do not adjust one side's parameters until
   the hashes match and then call it a comparison — both sides
   must use the identical request parameters listed in the script.

## Expected output

- The layer-group create returns HTTP 201 and the script prints `OK`.
- The serving node's `GetCapabilities` lists `federated:federated_group`.
- The comparison script prints two SHA-256 hashes. **Target:**
  identical hashes (MATCH). That target is a hypothesis to test,
  not a claimed outcome of this draft.
- Both responses are PNG images (HTTP 200, `image/png`), not
  service-exception XML — the script checks the file type and
  fails loudly if either side returned an exception.

## Failure behavior

- **Invalid input:** a layer group naming a layer that does not
  exist returns HTTP 400/404 and the script stops; no group is
  advertised. A group with zero layers is rejected the same way —
  GeoServer will not publish an empty group as a useful layer.
- **No-result case:** if the cascaded layer has no features in the
  requested bounding box, both paths return blank images. Blank
  images hash identically, which proves nothing about federation
  content — the comparison is only meaningful for a bounding box
  known to contain data. The script warns when either image is
  suspiciously small; re-run with a data-bearing box.
- **Byte difference:** DIFFER is a finding, not a failure of the
  script. Report it with both hashes, both request URLs, and the
  style/layer settings of each side. Do not silently re-render one
  side with different parameters to force a match.

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed, and no byte-identity result from
any node pair is cited as evidence for this draft.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run naming both
nodes and both GeoServer versions, with: the script's full output;
the layer-group definition retrieved back from the server; the two
SHA-256 hashes from `compare-outputs.sh` for a data-bearing bounding
box, with the MATCH/DIFFER verdict; and, if DIFFER, the diagnosed
cause and the corrected re-run. Until that run record exists, this
pattern stays design-only.
