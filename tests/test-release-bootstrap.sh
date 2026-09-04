#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc12' >/dev/null
printf '%s\n' "$status" | grep -F 'Source commit: 4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04' >/dev/null
printf '%s\n' "$status" | grep -F 'Artifact SHA-256: 546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a' >/dev/null
printf '%s\n' "$status" | grep -F 'Detached signature SHA-256: bdbe44b605b009c957e4bcc2ed5b2725d3d2ed32b7e78f146b31443dbc89d127' >/dev/null

grep -F "SOURCE_COMMIT='4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='30724599'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_SHA256='bdbe44b605b009c957e4bcc2ed5b2725d3d2ed32b7e78f146b31443dbc89d127'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_BYTES='334'" "$BOOTSTRAP" >/dev/null
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
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'v0.1.0-rc12 4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04' ]

python3 - "$ROOT" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads(
    (root / "release-input" / "vivolution-voice-platform-0.1.0-rc12-amd64.manifest.json").read_text(
        encoding="utf-8"
    )
)
summary = json.loads((root / "release-input" / "build-summary.json").read_text(encoding="utf-8"))
preview = json.loads((root / "channels" / "preview.json").read_text(encoding="utf-8"))
signature_path = root / "release-input" / "vivolution-voice-platform-0.1.0-rc12-amd64.tar.gz.sig"
sbom_path = root / "release-input" / "vivolution-voice-platform-0.1.0-rc12-amd64.spdx.json"
checksums = (root / "release-input" / "SHA256SUMS").read_text(encoding="utf-8")

assert manifest["release"] == "0.1.0-rc12"
assert manifest["source_commit"] == "4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04"
assert manifest["roles"] == ["controller", "edge"]
assert manifest["artifact"]["bytes"] == 30724599
assert manifest["artifact"]["sha256"] == "546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a"
assert summary["roles"] == ["controller", "edge"]
assert summary["artifact_sha256"] == manifest["artifact"]["sha256"]
assert hashlib.sha256(sbom_path.read_bytes()).hexdigest() == manifest["sbom"]["sha256"]
assert signature_path.stat().st_size == 334
signature_sha256 = hashlib.sha256(signature_path.read_bytes()).hexdigest()
assert signature_sha256 == "bdbe44b605b009c957e4bcc2ed5b2725d3d2ed32b7e78f146b31443dbc89d127"
assert f"{signature_sha256}  {signature_path.name}" in checksums
assert preview["available"] is True
assert preview["tag"] == "v0.1.0-rc12"
assert preview["source_commit"] == manifest["source_commit"]
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
