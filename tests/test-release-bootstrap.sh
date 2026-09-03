#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$($BOOTSTRAP --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc4' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null

grep -F "SOURCE_COMMIT='6a1cfa4d58e7af14fdf170dbe6c12e70a9e8f46e'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='2add9f0ca0511861e3b49ed4976b58807966ef1290dd09c3ab38404205e82dc7'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='179091'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
