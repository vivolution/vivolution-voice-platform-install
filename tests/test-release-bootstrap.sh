#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc6' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null
printf '%s\n' "$status" | grep -F 'standalone Controller Plane and Edge Appliance' >/dev/null

grep -F "SOURCE_COMMIT='f37febffd8d64392dddfb58c66b466a18848e0ea'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='94c450488a785c47225d3f506fc316b4a1449cd44f388279ff7af03d96f723b7'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='237599'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
grep -F '"roles": ["controller", "edge"]' "$BOOTSTRAP" >/dev/null

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc6' ]
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'v0.1.0-rc6 f37febffd8d64392dddfb58c66b466a18848e0ea' ]

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads(
    (root / "release-input" / "vivolution-voice-platform-0.1.0-rc6-amd64.manifest.json").read_text(
        encoding="utf-8"
    )
)
summary = json.loads((root / "release-input" / "build-summary.json").read_text(encoding="utf-8"))
preview = json.loads((root / "channels" / "preview.json").read_text(encoding="utf-8"))

assert manifest["release"] == "0.1.0-rc6"
assert manifest["source_commit"] == "f37febffd8d64392dddfb58c66b466a18848e0ea"
assert manifest["roles"] == ["controller", "edge"]
assert manifest["artifact"]["bytes"] == 237599
assert manifest["artifact"]["sha256"] == "94c450488a785c47225d3f506fc316b4a1449cd44f388279ff7af03d96f723b7"
assert summary["roles"] == ["controller", "edge"]
assert summary["artifact_sha256"] == manifest["artifact"]["sha256"]
assert preview["available"] is True
assert preview["tag"] == "v0.1.0-rc6"
assert preview["artifact_sha256"] == manifest["artifact"]["sha256"]
PY
