#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"
RELEASE_DIR="$ROOT/publication/v0.1.0-rc1"
ARTIFACT_NAME='vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'
MANIFEST="$RELEASE_DIR/vivolution-voice-platform-0.1.0-rc1-controller-amd64.manifest.json"
SBOM_NAME='vivolution-voice-platform-0.1.0-rc1-controller-amd64.spdx.json'
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vvp-public-test.XXXXXXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

sh -n "$BOOTSTRAP"

status_output=$("$BOOTSTRAP" --status)
printf '%s\n' "$status_output" | grep -F 'Release: 0.1.0-rc1' >/dev/null
printf '%s\n' "$status_output" | grep -F 'Source commit: a0c2f9465fe50ec01b72d14c5be936a10218ac92' >/dev/null
printf '%s\n' "$status_output" | grep -F 'Platform: Debian 13 AMD64' >/dev/null
printf '%s\n' "$status_output" | grep -F 'Artifact SHA-256: 56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed' >/dev/null

candidate=''
if [ -f "$RELEASE_DIR/$ARTIFACT_NAME" ]; then
    candidate="$RELEASE_DIR/$ARTIFACT_NAME"
else
    set -- "$RELEASE_DIR"/artifact.b64.part*
    if [ -e "$1" ]; then
        cat "$@" | base64 --decode > "$TEMP_ROOT/$ARTIFACT_NAME"
        candidate="$TEMP_ROOT/$ARTIFACT_NAME"
    fi
fi

if [ -n "$candidate" ]; then
    verify_output=$("$BOOTSTRAP" --verify-archive "$candidate")
    printf '%s\n' "$verify_output" | grep -F 'Controller archive verification passed; nothing was installed.' >/dev/null

    cp "$candidate" "$TEMP_ROOT/tampered.tar.gz"
    printf X | dd of="$TEMP_ROOT/tampered.tar.gz" bs=1 seek=100 conv=notrunc status=none
    set +e
    tampered_output=$("$BOOTSTRAP" --verify-archive "$TEMP_ROOT/tampered.tar.gz" 2>&1)
    tampered_status=$?
    set -e
    [ "$tampered_status" -ne 0 ]
    printf '%s\n' "$tampered_output" | grep -F 'SHA-256 verification failed' >/dev/null

    ln -s "$candidate" "$TEMP_ROOT/linked.tar.gz"
    set +e
    linked_output=$("$BOOTSTRAP" --verify-archive "$TEMP_ROOT/linked.tar.gz" 2>&1)
    linked_status=$?
    set -e
    [ "$linked_status" -ne 0 ]
    printf '%s\n' "$linked_output" | grep -F 'symbolic link' >/dev/null
fi

set +e
extra_output=$("$BOOTSTRAP" --verify-only unexpected 2>&1)
extra_status=$?
set -e
[ "$extra_status" -ne 0 ]
printf '%s\n' "$extra_output" | grep -F 'does not accept additional arguments' >/dev/null

# Documentation must download the full bootstrap before sudo executes it.
# shellcheck disable=SC2016
expected_fragment='--output "$tmp"'
grep -F -- "$expected_fragment" "$ROOT/README.md" >/dev/null
if grep -F '| sudo sh' "$ROOT/README.md" >/dev/null; then
    echo 'README contains a partial-download execution pipeline.' >&2
    exit 1
fi

sbom_candidate=''
if [ -f "$RELEASE_DIR/$SBOM_NAME" ]; then
    sbom_candidate="$RELEASE_DIR/$SBOM_NAME"
else
    set -- "$RELEASE_DIR"/sbom.b64.part*
    if [ -e "$1" ]; then
        cat "$@" | base64 --decode > "$TEMP_ROOT/$SBOM_NAME"
        sbom_candidate="$TEMP_ROOT/$SBOM_NAME"
    fi
fi

python3 - "$ROOT" "$MANIFEST" "$sbom_candidate" <<'PY'
import hashlib
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])
sbom_path = pathlib.Path(sys.argv[3]) if sys.argv[3] else None


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
assert manifest['schema_version'] == 1
assert manifest['product'] == 'Vivolution Voice Platform'
assert manifest['release'] == '0.1.0-rc1'
assert manifest['source_commit'] == 'a0c2f9465fe50ec01b72d14c5be936a10218ac92'
assert manifest['artifact']['name'] == 'vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'
assert manifest['artifact']['bytes'] == 111001
assert manifest['artifact']['sha256'] == '56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed'
assert manifest['artifact']['os'] == 'debian-13'
assert manifest['artifact']['architecture'] == 'amd64'
assert manifest['artifact']['entrypoint'] == 'installer/install.sh'
assert manifest['sbom']['name'] == 'vivolution-voice-platform-0.1.0-rc1-controller-amd64.spdx.json'
assert manifest['sbom']['sha256'] == '0b1c1edb6edc40ae9c31e4164a521fa070821a43a31ba42909f5461ddfba0755'
if sbom_path is not None:
    assert sha256(sbom_path) == manifest['sbom']['sha256']
    sbom = json.loads(sbom_path.read_text(encoding='utf-8'))
    assert sbom['spdxVersion'] == 'SPDX-2.3'
    assert sbom['dataLicense'] == 'CC0-1.0'
    assert sbom['documentNamespace'].endswith('/a0c2f9465fe50ec01b72d14c5be936a10218ac92')

expected_sums = {
    manifest_path.name: sha256(manifest_path),
    'vivolution-voice-platform-0.1.0-rc1-controller-amd64.spdx.json': '0b1c1edb6edc40ae9c31e4164a521fa070821a43a31ba42909f5461ddfba0755',
    'vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz': '56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed',
}
actual_sums = {}
for line in (manifest_path.parent / 'SHA256SUMS').read_text(encoding='utf-8').splitlines():
    digest, name = line.split('  ', 1)
    actual_sums[name] = digest
assert actual_sums == expected_sums

preview = json.loads((root / 'channels/preview.json').read_text(encoding='utf-8'))
assert preview == {
    'schema_version': 1,
    'channel': 'preview',
    'available': True,
    'release': '0.1.0-rc1',
    'role': 'controller',
    'platform': 'debian-13-amd64',
    'source_commit': 'a0c2f9465fe50ec01b72d14c5be936a10218ac92',
    'bootstrap_url': 'https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc1/install.sh',
    'manifest_url': 'https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v0.1.0-rc1/vivolution-voice-platform-0.1.0-rc1-controller-amd64.manifest.json',
    'artifact_sha256': '56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed',
}
stable = json.loads((root / 'channels/stable.json').read_text(encoding='utf-8'))
assert stable['available'] is False and stable['channel'] == 'stable'

schema = json.loads((root / 'schemas/release-manifest.schema.json').read_text(encoding='utf-8'))
assert schema['additionalProperties'] is False
assert set(schema['required']) == {'schema_version', 'product', 'release', 'source_commit', 'artifact', 'sbom', 'published_at'}
assert re.fullmatch(schema['properties']['release']['pattern'], manifest['release'])
for section in ('artifact', 'sbom'):
    rule = schema['properties'][section]['properties']['url']
    assert re.fullmatch(rule['pattern'], manifest[section]['url'])
PY
