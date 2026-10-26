#!/usr/bin/env bash
# 03 verification: serving-node GetMap vs remote-node GetMap.
# Design-only draft: not run. Set the same placeholders as
# configure-virtual-service.sh, then: bash verify-federation.sh
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${REMOTE_GEOSERVER_URL:?Set REMOTE_GEOSERVER_URL, e.g. <REMOTE_GEOSERVER_URL>}"
: "${REMOTE_WORKSPACE:?Set REMOTE_WORKSPACE, e.g. <REMOTE_WORKSPACE>}"
: "${REMOTE_LAYER:?Set REMOTE_LAYER, e.g. <REMOTE_LAYER>}"
: "${BBOX:=-80.05,28.98,-79.97,29.05}"

echo "== Serving-node GetMap (through federation) =="
curl -sf "${GEOSERVER_URL%/}/federated/wms?service=WMS&version=1.1.1&request=GetMap&layers=federated:${REMOTE_LAYER}&bbox=${BBOX}&width=600&height=400&srs=EPSG:4326&format=image/png" \
  -o /tmp/federated-serving.png
echo "OK serving-node map saved: /tmp/federated-serving.png ($(wc -c < /tmp/federated-serving.png) bytes)"

echo "== Remote-node GetMap (direct, for comparison) =="
curl -sf "${REMOTE_GEOSERVER_URL%/}/${REMOTE_WORKSPACE}/wms?service=WMS&version=1.1.1&request=GetMap&layers=${REMOTE_WORKSPACE}:${REMOTE_LAYER}&bbox=${BBOX}&width=600&height=400&srs=EPSG:4326&format=image/png" \
  -o /tmp/federated-remote.png
echo "OK remote-node map saved: /tmp/federated-remote.png ($(wc -c < /tmp/federated-remote.png) bytes)"

echo "Compare the two images visually and record whether they show the"
echo "same content. Pixel-level equality is NOT claimed here — that test"
echo "belongs to pattern 04. A service exception (XML) in either file"
echo "means federation failed for that side; inspect the file, do not"
echo "treat a non-empty file as success."
file /tmp/federated-serving.png /tmp/federated-remote.png
