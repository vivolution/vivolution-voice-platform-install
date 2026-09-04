#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc10' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null
printf '%s\n' "$status" | grep -F 'standalone Controller Plane and Edge Appliance' >/dev/null

grep -F "SOURCE_COMMIT='8623a344785a2fe68d139afeb3fd8ec217359e88'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='4cb0941221e24f3a1436a4c6b56b5035f5f1e646af2a17aea2aae15746d60911'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='255255'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
grep -F '"roles": ["controller", "edge"]' "$BOOTSTRAP" >/dev/null

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc10' ]
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'v0.1.0-rc10 8623a344785a2fe68d139afeb3fd8ec217359e88' ]

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads(
    (root / "release-input" / "vivolution-voice-platform-0.1.0-rc10-amd64.manifest.json").read_text(
        encoding="utf-8"
    )
)
summary = json.loads((root / "release-input" / "build-summary.json").read_text(encoding="utf-8"))
preview = json.loads((root / "channels" / "preview.json").read_text(encoding="utf-8"))

assert manifest["release"] == "0.1.0-rc10"
assert manifest["source_commit"] == "8623a344785a2fe68d139afeb3fd8ec217359e88"
assert manifest["roles"] == ["controller", "edge"]
assert manifest["artifact"]["bytes"] == 255255
assert manifest["artifact"]["sha256"] == "4cb0941221e24f3a1436a4c6b56b5035f5f1e646af2a17aea2aae15746d60911"
assert summary["roles"] == ["controller", "edge"]
assert summary["artifact_sha256"] == manifest["artifact"]["sha256"]
assert preview["available"] is True
assert preview["tag"] == "v0.1.0-rc10"
assert preview["artifact_sha256"] == manifest["artifact"]["sha256"]
PY
