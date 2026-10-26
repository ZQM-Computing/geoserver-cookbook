#!/usr/bin/env bash
# 02-sld-styling — upload SLD styles and assign them to layers.
# Design-only draft: not run, not runtime-validated.
# Usage: set GEOSERVER_URL, GEOSERVER_ADMIN_USER, GEOSERVER_ADMIN_PASSWORD,
# POINT_LAYER, LINE_LAYER, POLYGON_LAYER, then: bash upload-style.sh
# NEVER hardcode real credentials in this file; pass them via environment.
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"
: "${POINT_LAYER:?Set POINT_LAYER, e.g. <POINT_LAYER>}"
: "${LINE_LAYER:?Set LINE_LAYER, e.g. <LINE_LAYER>}"
: "${POLYGON_LAYER:?Set POLYGON_LAYER, e.g. <POLYGON_LAYER>}"

BASE="${GEOSERVER_URL%/}/rest"
AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
WS="synthetic"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

upload_style() {
  local name="$1" file="$2"
  # Upload the SLD body for one named style, then register it.
  # GeoServer accepts a raw SLD POST to /styles with Content-Type
  # application/vnd.ogc.sld+xml; the name is taken from the SLD.
  curl -sf -u "$AUTH" -X POST -H 'Content-Type: application/vnd.ogc.sld+xml' \
    --data-binary "@${file}" "${BASE}/workspaces/${WS}/styles" > /dev/null
  echo "OK style ${name} uploaded"
}

assign_style() {
  local layer="$1" style="$2"
  curl -sf -u "$AUTH" -X PUT -H 'Content-Type: application/json' \
    -d "{\"layer\":{\"defaultStyle\":{\"name\":\"${style}\"}}}" \
    "${BASE}/layers/${WS}:${layer}" > /dev/null
  echo "OK layer ${layer} default style set to ${style}"
}

# The SLD file carries three NamedLayers; GeoServer registers each
# NamedLayer as its own style on upload.
upload_style "synthetic_points"   "${SCRIPT_DIR}/inputs/styles.sld"
assign_style "$POINT_LAYER"   "synthetic_points"
assign_style "$LINE_LAYER"    "synthetic_lines"
assign_style "$POLYGON_LAYER" "synthetic_polygons"

echo
echo "Check maps (replace BBOX as needed):"
echo "  ${GEOSERVER_URL%/}/${WS}/wms?service=WMS&version=1.1.1&request=GetMap&layers=${WS}:${POINT_LAYER}&bbox=-80.05,28.98,-79.97,29.05&width=600&height=400&srs=EPSG:4326&format=image/png"
echo "DONE"
