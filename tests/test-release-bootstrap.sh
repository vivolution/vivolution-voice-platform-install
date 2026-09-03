#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$($BOOTSTRAP --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc1' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null

grep -F "SOURCE_COMMIT='a0c2f9465fe50ec01b72d14c5be936a10218ac92'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='111001'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
