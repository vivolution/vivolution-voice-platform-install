#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"
README="$ROOT/README.md"

sh -n "$BOOTSTRAP"

status_output=$($BOOTSTRAP --status)
printf '%s\n' "$status_output" | grep -F 'no approved release' >/dev/null
printf '%s\n' "$status_output" | grep -F 'Nothing was downloaded or installed.' >/dev/null

set +e
normal_output=$($BOOTSTRAP 2>&1)
normal_rc=$?
set -e
[ "$normal_rc" -ne 0 ]
printf '%s\n' "$normal_output" | grep -F 'intentionally fail-closed' >/dev/null
printf '%s\n' "$normal_output" | grep -F 'nothing was downloaded' >/dev/null

set +e
invalid_output=$($BOOTSTRAP --unknown 2>&1)
invalid_rc=$?
set -e
[ "$invalid_rc" -ne 0 ]
printf '%s\n' "$invalid_output" | grep -F 'supported option: --status' >/dev/null

if grep -E 'curl[[:space:]]|wget[[:space:]]|eval[[:space:]]|sh[[:space:]]+-c' "$BOOTSTRAP" >/dev/null; then
    echo 'Inactive bootstrap unexpectedly contains a downloader or dynamic execution path.' >&2
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
for channel in ('stable', 'preview'):
    value = json.loads((root / 'channels' / f'{channel}.json').read_text())
    assert value == {
        'schema_version': 1,
        'channel': channel,
        'available': False,
        'reason': f"No approved {channel} release has been promoted.",
    }

schema = json.loads((root / 'schemas' / 'release-manifest.schema.json').read_text())
assert schema['additionalProperties'] is False
assert 'sbom' in schema['required']
assert schema['properties']['artifact']['additionalProperties'] is False
assert schema['properties']['sbom']['additionalProperties'] is False
assert schema['properties']['artifact']['properties']['os']['const'] == 'debian-13'
assert schema['properties']['artifact']['properties']['architecture']['const'] == 'amd64'

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
