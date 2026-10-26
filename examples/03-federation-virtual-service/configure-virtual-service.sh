#!/usr/bin/env bash
# 03-federation-virtual-service — cascade a remote node's WMS layer
# through the serving node (virtual-service federation).
# Design-only draft: not run, not runtime-validated.
# Usage: set the variables below (placeholders shown), then:
#   bash configure-virtual-service.sh
# NEVER hardcode real credentials or node addresses in this file.
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"
: "${REMOTE_GEOSERVER_URL:?Set REMOTE_GEOSERVER_URL, e.g. <REMOTE_GEOSERVER_URL>}"
: "${REMOTE_WORKSPACE:?Set REMOTE_WORKSPACE, e.g. <REMOTE_WORKSPACE>}"
: "${REMOTE_LAYER:?Set REMOTE_LAYER, e.g. <REMOTE_LAYER>}"

BASE="${GEOSERVER_URL%/}/rest"
AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
WS="federated"
STORE="remote_wms"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "== 1. Workspace ${WS} (create if missing) =="
if curl -sf -u "$AUTH" "${BASE}/workspaces/${WS}.json" > /dev/null; then
  echo "OK workspace ${WS} already exists"
else
  curl -sf -u "$AUTH" -X POST -H 'Content-Type: application/json' \
    -d "{\"workspace\":{\"name\":\"${WS}\"}}" "${BASE}/workspaces" > /dev/null
  echo "OK workspace ${WS} created"
fi

echo "== 2. Remote WMS store ${STORE} (create if missing) =="
# inputs/wms-store.json is a template: substitute the remote placeholders.
STORE_JSON="$(sed -e "s|<REMOTE_GEOSERVER_URL>|${REMOTE_GEOSERVER_URL}|g" \
                   -e "s|<REMOTE_WORKSPACE>|${REMOTE_WORKSPACE}|g" \
                   "${SCRIPT_DIR}/inputs/wms-store.json")"
if curl -sf -u "$AUTH" "${BASE}/workspaces/${WS}/wmsstores/${STORE}.json" > /dev/null; then
  echo "OK store ${STORE} already exists"
else
  printf '%s' "$STORE_JSON" | curl -sf -u "$AUTH" -X POST \
    -H 'Content-Type: application/json' --data-binary @- \
    "${BASE}/workspaces/${WS}/wmsstores" > /dev/null
  echo "OK store ${STORE} created"
fi

echo "== 3. Cascaded layer from remote layer ${REMOTE_LAYER} =="
# The cascaded layer is published under the remote layer's name inside
# workspace ${WS}; adjust the native name if the remote layer is namespaced.
if curl -sf -u "$AUTH" "${BASE}/workspaces/${WS}/wmsstores/${STORE}/wmslayers/${REMOTE_LAYER}.json" > /dev/null; then
  echo "OK cascaded layer ${REMOTE_LAYER} already exists"
else
  curl -sf -u "$AUTH" -X POST -H 'Content-Type: application/json' \
    -d "{\"wmsLayer\":{\"name\":\"${REMOTE_LAYER}\",\"nativeName\":\"${REMOTE_LAYER}\",\"srs\":\"EPSG:4326\",\"enabled\":true}}" \
    "${BASE}/workspaces/${WS}/wmsstores/${STORE}/wmslayers" > /dev/null
  echo "OK cascaded layer ${REMOTE_LAYER} created"
fi

echo "== 4. Verify via serving node only =="
curl -sf -u "$AUTH" --output "$TMP_DIR/capabilities.xml" \
  "${GEOSERVER_URL%/}/${WS}/wms?service=WMS&request=GetCapabilities"
if grep -qF -- "$REMOTE_LAYER" "$TMP_DIR/capabilities.xml"; then
  echo "OK serving node lists cascaded layer ${REMOTE_LAYER}"
else
  echo "FAIL: serving node capabilities do not list ${REMOTE_LAYER}" >&2
  exit 1
fi
echo "DONE — now run: bash inputs/verify-federation.sh"
