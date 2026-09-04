#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"
README="$ROOT/README.md"

sh -n "$BOOTSTRAP"

status_output=$("$BOOTSTRAP" --status)
printf '%s\n' "$status_output" | grep -F 'Release candidate: v0.1.0-rc12' >/dev/null
printf '%s\n' "$status_output" | grep -F 'Publisher identity: vivolution-pilot-release' >/dev/null

grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F 'ssh-keygen -Y verify' "$BOOTSTRAP" >/dev/null
if grep -E 'eval[[:space:]]|sh[[:space:]]+-c' "$BOOTSTRAP" >/dev/null; then
    echo 'Bootstrap unexpectedly contains dynamic shell execution.' >&2
    exit 1
fi

# The documented one-liner must download the complete bootstrap before executing it.
# shellcheck disable=SC2016  # The README must contain the literal shell variable $tmp.
expected_output_fragment='--output "$tmp"'
grep -F -- "$expected_output_fragment" "$README" >/dev/null
if grep -F '| sudo sh' "$README" >/dev/null; then
    echo 'README contains a pipeline that can hide curl failure or execute partial input.' >&2
    exit 1
fi

python3 - "$ROOT" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
stable = json.loads((root / 'channels' / 'stable.json').read_text())
assert stable == {
    'schema_version': 1,
    'channel': 'stable',
    'available': False,
    'reason': 'No approved stable release has been promoted.',
}
preview = json.loads((root / 'channels' / 'preview.json').read_text())
assert preview['schema_version'] == 1
assert preview['channel'] == 'preview'
assert preview['available'] is True
assert preview['tag'] == 'v0.1.0-rc12'
assert preview['source_commit'] == '4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04'
assert preview['artifact_sha256'] == '546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a'

schema = json.loads((root / 'schemas' / 'release-manifest.schema.json').read_text())
assert schema['additionalProperties'] is False
assert 'sbom' in schema['required']
assert 'roles' in schema['required']
assert schema['properties']['artifact']['additionalProperties'] is False
assert schema['properties']['sbom']['additionalProperties'] is False
assert schema['properties']['artifact']['properties']['os']['const'] == 'debian-13'
assert schema['properties']['artifact']['properties']['architecture']['const'] == 'amd64'
assert schema['properties']['roles']['items']['enum'] == ['controller', 'edge']

release_pattern = re.compile(schema['properties']['release']['pattern'])
assert release_pattern.fullmatch('0.1.0')
assert release_pattern.fullmatch('0.1.0-rc1')
assert not release_pattern.fullmatch('0.1.0-rc0')
assert not release_pattern.fullmatch('v0.1.0')

safe_url = 'https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v0.1.0-rc1/vivolution-voice-platform-0.1.0-rc1-amd64.tar.gz'
for section in ('artifact', 'sbom'):
    url_rule = schema['properties'][section]['properties']['url']
    assert url_rule.get('format') == 'uri'
    pattern = re.compile(url_rule['pattern'])
    assert pattern.fullmatch(safe_url)
    assert not pattern.fullmatch('https://')
    assert not pattern.fullmatch('http://github.com/file')
    assert not pattern.fullmatch('https://user:pass@github.com/file')
    assert not pattern.fullmatch('https://example.com/release.tar.gz')
    assert not pattern.fullmatch('https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v0.1.0-rc0/file')

name_pattern = re.compile(schema['properties']['artifact']['properties']['name']['pattern'])
assert name_pattern.fullmatch('vivolution-voice-platform-0.1.0-rc1-amd64.tar.gz')
assert not name_pattern.fullmatch('../release.tar.gz')
assert not name_pattern.fullmatch('path/release.tar.gz')
PY
