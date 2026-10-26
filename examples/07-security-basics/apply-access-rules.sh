#!/usr/bin/env bash
# 07-security-basics — change admin password, apply data access rules.
# Design-only draft: not run, not runtime-validated.
# SECURITY NOTES:
#  - Passwords come ONLY from the environment. Never edit this file to
#    contain a real password, and never paste the new password into a
#    shared file, ticket, or chat log.
#  - Rules are applied BEFORE the password change, so a rules failure
#    never leaves you locked out with a changed password and no rules.
#  - After this runs, update your credential store and discard this
#    shell session (or at least unset NEW_ADMIN_PASSWORD).
# Usage: set the variables below (placeholders shown), then:
#   bash apply-access-rules.sh
set -euo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
: "${GEOSERVER_ADMIN_USER:?Set GEOSERVER_ADMIN_USER, e.g. <ADMIN_USER>}"
: "${GEOSERVER_ADMIN_PASSWORD:?Set GEOSERVER_ADMIN_PASSWORD, e.g. <ADMIN_PASSWORD>}"
: "${NEW_ADMIN_PASSWORD:?Set NEW_ADMIN_PASSWORD, e.g. <NEW_ADMIN_PASSWORD>}"

BASE="${GEOSERVER_URL%/}/rest"
AUTH="${GEOSERVER_ADMIN_USER}:${GEOSERVER_ADMIN_PASSWORD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "== 1. Apply data access rules (before any password change) =="
# The data access rules endpoint accepts a properties-style body.
# Validate the file exists and is non-empty first; a rules failure
# must stop the script here, before step 2.
if [ ! -s "${SCRIPT_DIR}/inputs/access-rules.properties" ]; then
  echo "FAIL: inputs/access-rules.properties is missing or empty."
  exit 1
fi
curl -sf -u "$AUTH" -X PUT -H 'Content-Type: text/plain' \
  --data-binary "@${SCRIPT_DIR}/inputs/access-rules.properties" \
  "${BASE}/security/acl/layers" > /dev/null
echo "OK data access rules applied"
curl -sf -u "$AUTH" --output "$TMP_DIR/layer-rules.txt" "${BASE}/security/acl/layers"
head -c 2000 "$TMP_DIR/layer-rules.txt"
echo

echo "== 2. Change admin password =="
# GeoServer user update: PUT the user resource with the new password.
# Field names follow the REST user resource; record any version-driven
# difference at validation. The new password is never echoed.
# Serialize credentials as JSON without interpolating user-controlled values
# into JSON text or exposing the new password in curl's process arguments.
python3 "${SCRIPT_DIR}/inputs/build-user-payload.py" "${TMP_DIR}/user-update.json"
curl -sf -u "$AUTH" -X PUT -H 'Content-Type: application/json' \
  --data-binary "@${TMP_DIR}/user-update.json" \
  "${BASE}/security/usergroup/users/${GEOSERVER_ADMIN_USER}" > /dev/null
echo "OK password change accepted (new password NOT printed)"

echo "== 3. Confirm: new password works, old password fails =="
if curl -sf -u "${GEOSERVER_ADMIN_USER}:${NEW_ADMIN_PASSWORD}" \
    "${BASE}/workspaces.json" > /dev/null; then
  echo "OK new password authenticates"
else
  echo "FAIL: new password did not authenticate — confirm which password"
  echo "is current before retrying. Do not retry blindly."
  exit 1
fi
if curl -sf -u "$AUTH" "${BASE}/workspaces.json" > /dev/null; then
  echo "FAIL: old password still authenticates — password change did not take effect."
  exit 1
else
  echo "OK old password rejected (HTTP 401 as expected)"
fi

echo "DONE — update your credential store with the new password now,"
echo "then run: unset NEW_ADMIN_PASSWORD; bash inputs/audit-checks.sh"
