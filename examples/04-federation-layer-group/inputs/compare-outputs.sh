#!/usr/bin/env bash
# 04 byte comparison: virtual-service path vs layer-group path.
# Design-only draft: not run. Both requests MUST use identical
# parameters (bbox, size, CRS, format) or the comparison is meaningless.
# Usage: set GEOSERVER_URL and REMOTE_LAYER, then: bash compare-outputs.sh
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${REMOTE_LAYER:?Set REMOTE_LAYER, e.g. <REMOTE_LAYER>}"
: "${BBOX:=-80.05,28.98,-79.97,29.05}"

COMMON="service=WMS&version=1.1.1&request=GetMap&bbox=${BBOX}&width=600&height=400&srs=EPSG:4326&format=image/png"

curl -sf "${GEOSERVER_URL%/}/federated/wms?${COMMON}&layers=federated:${REMOTE_LAYER}" \
  -o /tmp/federation-virtual.png
curl -sf "${GEOSERVER_URL%/}/federated/wms?${COMMON}&layers=federated:federated_group" \
  -o /tmp/federation-group.png

for f in /tmp/federation-virtual.png /tmp/federation-group.png; do
  if ! file "$f" | grep -qi 'PNG image'; then
    echo "FAIL: $f is not a PNG — likely a service exception. Inspect it:"
    head -c 500 "$f"; echo
    exit 1
  fi
  echo "$f: $(wc -c < "$f") bytes"
done

# Blank-image guard: a match between two blank maps proves nothing.
# PNG sizes here are only a tripwire — confirm the box holds data
# (pattern 03 verification) before treating MATCH as meaningful.
if [ "$(wc -c < /tmp/federation-virtual.png)" -lt 1000 ]; then
  echo "WARNING: virtual-service image under 1000 bytes — bounding box may hold no data."
fi

HASH_V="$(sha256sum /tmp/federation-virtual.png | awk '{print $1}')"
HASH_G="$(sha256sum /tmp/federation-group.png | awk '{print $1}')"
echo "virtual-service path: ${HASH_V}"
echo "layer-group path:     ${HASH_G}"
if [ "$HASH_V" = "$HASH_G" ]; then
  echo "VERDICT: MATCH — byte-identical for this request."
else
  echo "VERDICT: DIFFER — record both hashes and both request URLs."
  echo "Check, in order: default style on group vs layer, layer order,"
  echo "transparent flag, and image format. Do not tweak one side's"
  echo "parameters to force a match."
  exit 2
fi
