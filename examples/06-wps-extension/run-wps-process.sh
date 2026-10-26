#!/usr/bin/env bash
# 06-wps-extension — run a first WPS process (JTS buffer).
# Design-only draft: not run, not runtime-validated.
# Usage: set GEOSERVER_URL, GEOSERVER_ADMIN_USER, GEOSERVER_ADMIN_PASSWORD,
# then: bash run-wps-process.sh
# NEVER hardcode real credentials in this file; pass them via environment.
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"

AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== 1. WPS GetCapabilities lists a buffer process? =="
CAPS="$(curl -sf -u "$AUTH" "${GEOSERVER_URL%/}/wps?service=WPS&request=GetCapabilities" || true)"
if [ -z "$CAPS" ]; then
  echo "FAIL: WPS NOT INSTALLED — ${GEOSERVER_URL%/}/wps did not answer."
  echo "Install the WPS extension matching your GeoServer version and restart."
  exit 1
fi
if printf '%s' "$CAPS" | grep -qi 'buffer'; then
  echo "OK buffer process listed in WPS capabilities"
else
  echo "FAIL: WPS answered but no buffer process listed. Record the"
  echo "capabilities document and the extension version before proceeding."
  exit 1
fi

echo "== 2. Execute JTS:buffer (0.01 degrees around synthetic point) =="
RESPONSE="$(curl -sf -u "$AUTH" -X POST -H 'Content-Type: text/xml' \
  --data-binary "@${SCRIPT_DIR}/inputs/buffer-request.xml" \
  "${GEOSERVER_URL%/}/wps")"
printf '%s\n' "$RESPONSE"
if printf '%s' "$RESPONSE" | grep -qi 'Exception'; then
  echo "FAIL: WPS returned an exception (see above)."
  exit 1
fi
echo "OK WPS Execute returned without an exception document"
echo "DONE — confirm the response carries a polygon enclosing (-80.0, 29.0)."
