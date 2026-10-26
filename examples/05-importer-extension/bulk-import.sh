#!/usr/bin/env bash
# 05-importer-extension — bulk ingest via the Importer REST API.
# Design-only draft: not run, not runtime-validated.
# Usage: set the variables below (placeholders shown), then:
#   bash bulk-import.sh
# NEVER hardcode real credentials in this file; pass them via environment.
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"
: "${PG_HOST:?Set PG_HOST, e.g. <PG_HOST>}"
: "${PG_PORT:?Set PG_PORT, e.g. <PG_PORT>}"
: "${PG_DB:?Set PG_DB, e.g. <PG_DB>}"
: "${PG_USER:?Set PG_USER, e.g. <PG_USER>}"
: "${PG_PASSWORD:?Set PG_PASSWORD, e.g. <PG_PASSWORD>}"

BASE="${GEOSERVER_URL%/}/rest"
AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== 0. Importer extension present? =="
if ! curl -sf -u "$AUTH" "${BASE}/imports" > /dev/null; then
  echo "FAIL: IMPORTER NOT INSTALLED — ${BASE}/imports did not answer."
  echo "Install the Importer extension matching your GeoServer version and restart."
  exit 1
fi
echo "OK /rest/imports answers"

echo "== 1. Create import context from synthetic GeoJSON =="
# File upload form: the Importer accepts a multipart file part.
IMPORT_JSON="$(curl -sf -u "$AUTH" -X POST \
  -F "file=@${SCRIPT_DIR}/inputs/sample-features.geojson" \
  "${BASE}/imports")"
IMPORT_ID="$(printf '%s' "$IMPORT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["import"]["id"])')"
TASK_ID="$(printf '%s' "$IMPORT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["import"]["tasks"][0]["id"])')"
echo "OK import ${IMPORT_ID}, task ${TASK_ID}"

echo "== 2. Retarget task to workspace synthetic / PostGIS datastore =="
# Target store payload shape follows the Importer REST docs; the
# datastore must already exist (pattern 01). Record any version-driven
# field difference at validation instead of editing silently.
curl -sf -u "$AUTH" -X PUT -H 'Content-Type: application/json' \
  -d "{\"task\":{\"target\":{\"dataStore\":{\"name\":\"synthetic_pg\",\"workspace\":{\"name\":\"synthetic\"}},\"name\":\"synthetic_imported\"}}}" \
  "${BASE}/imports/${IMPORT_ID}/tasks/${TASK_ID}" > /dev/null
echo "OK task retargeted to synthetic:synthetic_imported"

echo "== 3. Run import and poll =="
curl -sf -u "$AUTH" -X POST "${BASE}/imports/${IMPORT_ID}" > /dev/null
for i in $(seq 1 30); do
  sleep 2
  STATUS_JSON="$(curl -sf -u "$AUTH" "${BASE}/imports/${IMPORT_ID}")"
  STATE="$(printf '%s' "$STATUS_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["import"]["state"])')"
  echo "poll ${i}: state=${STATE}"
  case "$STATE" in
    COMPLETE) echo "IMPORT COMPLETE"; printf '%s\n' "$STATUS_JSON"; break ;;
    ERROR|BAD_FORMAT) echo "FAIL: import ended in ${STATE}"; printf '%s\n' "$STATUS_JSON"; exit 1 ;;
  esac
  if [ "$i" = "30" ]; then echo "FAIL: import did not complete in 60s"; exit 1; fi
done

echo "== 4. Verify rows via WFS =="
curl -sf -u "$AUTH" \
  "${GEOSERVER_URL%/}/synthetic/wfs?service=WFS&version=2.0.0&request=GetFeature&typeName=synthetic:synthetic_imported"
echo
echo "DONE"
