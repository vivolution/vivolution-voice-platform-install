#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$("$BOOTSTRAP" --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc13' >/dev/null
printf '%s\n' "$status" | grep -F 'Source commit: 42a5c8be98b35211afdde3294f337b1c8258e2c9' >/dev/null
printf '%s\n' "$status" | grep -F 'Artifact SHA-256: fa574052befbdc6bb656636ca4493f8285551e47f1256b834c36bcde337fc283' >/dev/null
printf '%s\n' "$status" | grep -F 'Detached signature SHA-256: 96206484a3ae997e8f998ed2bd3f7d0aa0f5d38ac20b97e22c7fcd4f37f1bd79' >/dev/null

grep -F "SOURCE_COMMIT='42a5c8be98b35211afdde3294f337b1c8258e2c9'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='fa574052befbdc6bb656636ca4493f8285551e47f1256b834c36bcde337fc283'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='30735281'" "$BOOTSTRAP" >/dev/null
grep -F "SIGNATURE_SHA256='96206484a3ae997e8f998ed2bd3f7d0aa0f5d38ac20b97e22c7fcd4f37f1bd79'" "$BOOTSTRAP" >/dev/null
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

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc13' ]
[ "$(cat "$ROOT/PUBLISH_APPROVED")" = 'v0.1.0-rc13 42a5c8be98b35211afdde3294f337b1c8258e2c9' ]

python3 - "$ROOT" <<'PY'
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = json.loads(
    (root / "release-input" / "vivolution-voice-platform-0.1.0-rc13-amd64.manifest.json").read_text(
        encoding="utf-8"
    )
)
summary = json.loads((root / "release-input" / "build-summary.json").read_text(encoding="utf-8"))
preview = json.loads((root / "channels" / "preview.json").read_text(encoding="utf-8"))
signature_path = root / "release-input" / "vivolution-voice-platform-0.1.0-rc13-amd64.tar.gz.sig"
sbom_path = root / "release-input" / "vivolution-voice-platform-0.1.0-rc13-amd64.spdx.json"
checksums = (root / "release-input" / "SHA256SUMS").read_text(encoding="utf-8")

assert manifest["release"] == "0.1.0-rc13"
assert manifest["source_commit"] == "42a5c8be98b35211afdde3294f337b1c8258e2c9"
assert manifest["roles"] == ["controller", "edge"]
assert manifest["artifact"]["bytes"] == 30735281
assert manifest["artifact"]["sha256"] == "fa574052befbdc6bb656636ca4493f8285551e47f1256b834c36bcde337fc283"
assert summary["roles"] == ["controller", "edge"]
assert summary["artifact_sha256"] == manifest["artifact"]["sha256"]
assert hashlib.sha256(sbom_path.read_bytes()).hexdigest() == manifest["sbom"]["sha256"]
assert signature_path.stat().st_size == 334
signature_sha256 = hashlib.sha256(signature_path.read_bytes()).hexdigest()
assert signature_sha256 == "96206484a3ae997e8f998ed2bd3f7d0aa0f5d38ac20b97e22c7fcd4f37f1bd79"
assert f"{signature_sha256}  {signature_path.name}" in checksums
assert preview["available"] is True
assert preview["tag"] == "v0.1.0-rc13"
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
