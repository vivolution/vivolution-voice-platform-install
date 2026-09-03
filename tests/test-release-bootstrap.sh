#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$($BOOTSTRAP --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc3' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null

grep -F "SOURCE_COMMIT='ecff3fe017ed30611ffbc7e45a3f24c5aa1de6b9'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='e91184e3974336e0b606829c61d93f9d9e45f04671c5187251b1d0b660a322b2'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='169279'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
