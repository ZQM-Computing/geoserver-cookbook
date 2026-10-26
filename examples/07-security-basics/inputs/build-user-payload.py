#!/usr/bin/env python3
"""Write a least-privilege temporary GeoServer user-update JSON payload."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: build-user-payload.py OUTPUT_PATH", file=sys.stderr)
        return 2
    username = os.environ.get("GEOSERVER_ADMIN_USER")
    password = os.environ.get("NEW_ADMIN_PASSWORD")
    if not username or not password:
        print("GEOSERVER_ADMIN_USER and NEW_ADMIN_PASSWORD must be set", file=sys.stderr)
        return 2

    output = Path(sys.argv[1])
    payload = {
        "user": {
            "userName": username,
            "password": password,
            "enabled": True,
        }
    }
    # The caller supplies a path inside a mktemp -d directory. Enforce
    # restrictive permissions as defense in depth; never print the payload.
    output.write_text(json.dumps(payload, ensure_ascii=False) + "\n", encoding="utf-8")
    try:
        output.chmod(0o600)
    except OSError as exc:
        print(f"cannot restrict payload permissions: {exc}", file=sys.stderr)
        output.unlink(missing_ok=True)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
