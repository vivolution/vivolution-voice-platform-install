#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc11' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null
printf '%s\n' "$status" | grep -F 'standalone Controller Plane and Edge Appliance' >/dev/null

grep -F "SOURCE_COMMIT='ad481774a054e99b1430cde24e6ed0facdf81c0b'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='dea6cc9d60c233fc3e6e3a6e1b6554936389c256f60f559c8370922ccf207396'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='260274'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
grep -F '"roles": ["controller", "edge"]' "$BOOTSTRAP" >/dev/null

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc11' ]
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'v0.1.0-rc11 ad481774a054e99b1430cde24e6ed0facdf81c0b' ]

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads(
    (root / "release-input" / "vivolution-voice-platform-0.1.0-rc11-amd64.manifest.json").read_text(
        encoding="utf-8"
    )
)
summary = json.loads((root / "release-input" / "build-summary.json").read_text(encoding="utf-8"))
preview = json.loads((root / "channels" / "preview.json").read_text(encoding="utf-8"))

assert manifest["release"] == "0.1.0-rc11"
assert manifest["source_commit"] == "ad481774a054e99b1430cde24e6ed0facdf81c0b"
assert manifest["roles"] == ["controller", "edge"]
assert manifest["artifact"]["bytes"] == 260274
assert manifest["artifact"]["sha256"] == "dea6cc9d60c233fc3e6e3a6e1b6554936389c256f60f559c8370922ccf207396"
assert summary["roles"] == ["controller", "edge"]
assert summary["artifact_sha256"] == manifest["artifact"]["sha256"]
assert preview["available"] is True
assert preview["tag"] == "v0.1.0-rc11"
assert preview["artifact_sha256"] == manifest["artifact"]["sha256"]
PY
