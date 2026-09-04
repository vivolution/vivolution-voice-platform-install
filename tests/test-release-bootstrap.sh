#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc12' >/dev/null
printf '%s\n' "$status" | grep -F 'Release metadata: incomplete' >/dev/null
printf '%s\n' "$status" | grep -F 'Nothing was downloaded or installed.' >/dev/null

set +e
pending_output=$("$BOOTSTRAP" --verify-only 2>&1)
pending_rc=$?
set -e
[ "$pending_rc" -ne 0 ]
printf '%s\n' "$pending_output" | grep -F 'release metadata is incomplete' >/dev/null
printf '%s\n' "$pending_output" | grep -F 'nothing was downloaded or installed' >/dev/null

grep -F "SOURCE_COMMIT='__RC12_SOURCE_COMMIT__'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='__RC12_ARCHIVE_SHA256__'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='__RC12_ARCHIVE_BYTES__'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_SHA256='__RC12_SIGNATURE_SHA256__'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_BYTES='__RC12_SIGNATURE_BYTES__'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_NAME=\"\${ARCHIVE_NAME}.sig\"" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_URL=\"\${ARCHIVE_URL}.sig\"" "$BOOTSTRAP" >/dev/null
grep -F "RELEASE_SIGNING_NAMESPACE='vivolution-voice-platform-release'" "$BOOTSTRAP" >/dev/null
grep -F "RELEASE_SIGNER_IDENTITY='vivolution-pilot-release'" "$BOOTSTRAP" >/dev/null
grep -F "RELEASE_SIGNING_PUBLIC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXDQQsKYGszOebD6Ik4+MxhqOXP72R114hI98N+kCt3'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum -c -' "$BOOTSTRAP" >/dev/null
grep -F 'ssh-keygen -Y verify' "$BOOTSTRAP" >/dev/null
grep -F '"roles": ["controller", "edge"]' "$BOOTSTRAP" >/dev/null

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc12' ]
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'NOT_APPROVED v0.1.0-rc12 awaiting-final-signed-artifact' ]

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

bootstrap = (root / "install.sh").read_text(encoding="utf-8")
signature_download = bootstrap.index('"$SIGNATURE_URL" || fail')
signature_hash = bootstrap.index('"$signature" \'publisher signature\'')
signature_verify = bootstrap.index('verify_detached_signature "$archive"')
archive_read = bootstrap.index('tar -tzf "$archive"')
assert signature_download < signature_hash
assert signature_hash < signature_verify
assert signature_verify < archive_read
PY

sh "$ROOT/tests/test-detached-signature.sh"
