#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

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

python3 - "$ROOT" <<'PY'
import json
import pathlib
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
json.loads((root / 'schemas' / 'release-manifest.schema.json').read_text())
PY
