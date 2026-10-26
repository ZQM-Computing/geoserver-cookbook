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
    # Create exclusively with restrictive permissions from the first byte.
    # O_EXCL also refuses to follow a pre-existing file or symlink, avoiding
    # accidental overwrite and a window where credentials could be readable.
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    try:
        descriptor = os.open(output, flags, 0o600)
    except FileExistsError:
        print("output path already exists; refusing to overwrite", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"cannot create protected payload: {exc}", file=sys.stderr)
        return 1

    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            json.dump(payload, stream, ensure_ascii=False)
            stream.write("\n")
    except OSError as exc:
        try:
            os.close(descriptor)
        except OSError:
            pass
        output.unlink(missing_ok=True)
        print(f"cannot write protected payload: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
