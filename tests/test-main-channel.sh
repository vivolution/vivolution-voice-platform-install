#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

# The unpromoted main channel must always fail closed and must not contain a downloader.
sh -n "$BOOTSTRAP"
"$BOOTSTRAP" --status | grep -F 'no approved release' >/dev/null

set +e
output=$("$BOOTSTRAP" 2>&1)
status=$?
set -e
[ "$status" -ne 0 ]
printf '%s\n' "$output" | grep -F 'intentionally fail-closed' >/dev/null

if grep -E '(^|[[:space:]])(curl|wget|eval)([[:space:]]|$)|sh[[:space:]]+-c' "$BOOTSTRAP" >/dev/null; then
    echo 'Unpromoted main channel unexpectedly contains download or dynamic execution logic.' >&2
    exit 1
fi
