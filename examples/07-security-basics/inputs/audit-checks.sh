#!/usr/bin/env bash
# 07 audit checks: probe, WITHOUT credentials, the endpoints that
# should be closed. Reports LOCKED or OPEN per endpoint.
# Design-only draft: not run. Usage:
#   GEOSERVER_URL='<GEOSERVER_URL>' bash audit-checks.sh
set -uo pipefail

: "${GEOSERVER_URL:?Set GEOSERVER_URL, e.g. <GEOSERVER_URL>}"
BASE="${GEOSERVER_URL%/}"

check() {
  local label="$1" url="$2"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' "$url" || echo "000")"
  case "$code" in
    401|403) echo "LOCKED  ${label} (HTTP ${code})" ;;
    200)     echo "OPEN    ${label} (HTTP ${code}) — intended-public, or a failed run" ;;
    404)     echo "ABSENT  ${label} (HTTP ${code}) — endpoint not present on this server" ;;
    *)       echo "UNKNOWN ${label} (HTTP ${code}) — investigate" ;;
  esac
}

check "REST API, no credentials"      "${BASE}/rest/workspaces.json"
check "Admin user resource, no creds" "${BASE}/rest/security/usergroup/users/admin"
check "WPS GetCapabilities, no creds" "${BASE}/wps?service=WPS&request=GetCapabilities"
echo
echo "NOTE: WPS GetCapabilities is commonly public; judge WPS by whether"
echo "an unauthenticated Execute succeeds, not by whether capabilities"
echo "are readable. Test Execute auth separately before calling WPS locked."
