# 03 — Federation via virtual service: one node serving another node's layers

> Status: **design-only draft — not run, not runtime-validated.**
> Honesty note: the cookbook seed notes a verified Node-1 ← Node-3
> federation path. **This draft does not reproduce, re-claim, or cite
> results from that path.** It provides only a configuration template
> plus the verification steps that would prove federation works.
> No node result is claimed here.

## What it demonstrates

Virtual-service federation: a "serving" GeoServer exposes layers that
live on a second ("remote") GeoServer, by cascading the remote WMS
through a WMS store. Clients query the serving node only; the serving
node forwards the request to the remote node. The pattern's template
uses placeholders for both nodes throughout, so no node address,
credential, or layer name from any real fleet setup is baked in.

In GeoServer terms: the serving node gets a WMS store pointing at
the remote node's `GetCapabilities` URL, cascaded layers are
published from that store, and the serving node's own WMS endpoint
serves them. A "virtual service" here means the serving node's
workspace-scoped WMS endpoint for that workspace — clients do not
need the remote node's URL.

## Prerequisites + versions

- Two GeoServer instances that can reach each other over the
  network in use (localhost or tailnet-only binding preferred; see
  pattern 07 for the lockdown notes). Both nodes' versions:
  **to confirm at validation** for the pair actually used.
  Known version facts only: GeoServer 3.0.2 on Node-1 (per seed);
  Node-4 migrated to 3.0.2 (2026-10-25); Node-3's current version:
  **to confirm at validation**. Java 21 runtime for GeoServer 3.x.
- Default GeoServer port 8080 unless the placeholders say otherwise.
- A published layer on the remote node (pattern 01's
  `synthetic_places`, or any equivalent).
- `curl`. Credentials only as placeholders:
  `<GEOSERVER_URL>` (serving node), `<REMOTE_GEOSERVER_URL>`,
  `<ADMIN_USER>`, `<ADMIN_PASSWORD>`, `<REMOTE_LAYER>`.

## Steps

1. Confirm the remote layer is directly reachable:
   `<REMOTE_GEOSERVER_URL>/<REMOTE_WORKSPACE>/wms?service=WMS&request=GetCapabilities`
   and that it lists `<REMOTE_LAYER>`.
2. On the serving node, create the cascaded WMS store from
   `inputs/wms-store.json` (fill in `<REMOTE_GEOSERVER_URL>` and
   `<REMOTE_WORKSPACE>` first), then publish the cascaded layer:
   ```sh
   export GEOSERVER_URL='<GEOSERVER_URL>'
   export GEOSERVER_ADMIN_USER='<ADMIN_USER>'
   export GEOSERVER_ADMIN_PASSWORD='<ADMIN_PASSWORD>'
   export REMOTE_GEOSERVER_URL='<REMOTE_GEOSERVER_URL>'
   export REMOTE_WORKSPACE='<REMOTE_WORKSPACE>'
   export REMOTE_LAYER='<REMOTE_LAYER>'
   bash configure-virtual-service.sh
   ```
3. Run the verification script against the *serving* node only:
   `bash inputs/verify-federation.sh` (same placeholders exported).
   It checks the serving node's `GetCapabilities`, fetches a
   `GetMap` through the serving node, and fetches the same map
   directly from the remote node for comparison.

## Expected output

- The WMS store create returns HTTP 201 and the cascaded layer
  publish returns HTTP 201; the script prints `OK` per step.
- The serving node's `GetCapabilities` lists the cascaded layer.
- A `GetMap` through the serving node returns HTTP 200 with an
  image, not a service exception.
- The serving-node map and the remote-node map cover the same
  bounding box and layer content (pixel-level equality is NOT
  promised — see pattern 04 for the byte-comparison test; here,
  visual/content equivalence plus matching feature counts are the
  bar, and any difference is recorded, not smoothed over).

## Failure behavior

- **Invalid input:** a wrong remote `GetCapabilities` URL, or a
  remote layer name that does not exist, makes the store create or
  the layer publish fail (HTTP 400/404/500) and the script stops.
  The serving node must not be left advertising a broken cascaded
  layer: on failure, delete the partially created store before
  retrying.
- **No-result case:** if the remote layer exists but has no features
  in the requested bounding box, both the serving-node and the
  remote-node `GetMap` return blank images. Blank-on-both-sides is
  consistent federation, not proof of failure — re-request a box
  known to contain data before concluding anything.
- **Remote unreachable:** connection errors or HTTP 401/403 from the
  remote node surface as a GeoServer service exception on the
  serving-node `GetMap`. That is a connectivity/credential problem
  between nodes, not a client problem; fix the inter-node path
  (and see pattern 07 before opening anything beyond tailnet).

## Evidence

**design-only, gate 1 target.**

No run of this pattern is claimed, and no federation result from any
node pair is cited as evidence for this draft.

## Gate-3 proof

Gate 3 (runtime-validated) would require a recorded run naming both
nodes and both GeoServer versions, with: the script's full output;
the serving node's `GetCapabilities` excerpt listing the cascaded
layer; a serving-node `GetMap` and a remote-node `GetMap` for the
same bounding box; and the failure checks above (wrong remote URL,
empty bounding box, remote stopped) each showing the stated outcome.
Until that run record exists, this pattern stays design-only.
