#!/usr/bin/env bash
# 04-federation-layer-group — wrap cascaded layer(s) in a layer group.
# Design-only draft: not run, not runtime-validated.
# Prerequisite: pattern 03 completed on the same serving node.
# Usage: set the variables below (placeholders shown), then:
#   bash create-layer-group.sh
# NEVER hardcode real credentials in this file.
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"
: "${REMOTE_LAYER:?Set REMOTE_LAYER, e.g. <REMOTE_LAYER>}"

BASE="${GEOSERVER_URL%/}/rest"
AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
WS="federated"
GROUP="federated_group"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

GROUP_JSON="$(sed -e "s|<REMOTE_LAYER>|${REMOTE_LAYER}|g" \
                   "${SCRIPT_DIR}/inputs/layer-group.json")"

if curl -sf -u "$AUTH" "${BASE}/workspaces/${WS}/layergroups/${GROUP}.json" > /dev/null; then
  echo "OK layer group ${GROUP} already exists"
else
  printf '%s' "$GROUP_JSON" | curl -sf -u "$AUTH" -X POST \
    -H 'Content-Type: application/json' --data-binary @- \
    "${BASE}/workspaces/${WS}/layergroups" > /dev/null
  echo "OK layer group ${GROUP} created"
fi

curl -sf -u "$AUTH" --output "$TMP_DIR/capabilities.xml" \
  "${GEOSERVER_URL%/}/${WS}/wms?service=WMS&request=GetCapabilities"
if grep -qF -- "$GROUP" "$TMP_DIR/capabilities.xml"; then
  echo "OK serving node lists layer group ${GROUP}"
else
  echo "FAIL: serving node capabilities do not list ${GROUP}" >&2
  exit 1
fi
echo "DONE — now run: bash inputs/compare-outputs.sh"
