#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

sh -n "$BOOTSTRAP"
status=$($BOOTSTRAP --status)
printf '%s\n' "$status" | grep -F 'Release candidate: v0.1.0-rc2' >/dev/null
printf '%s\n' "$status" | grep -F 'Debian GNU/Linux 13 AMD64/x86_64' >/dev/null

grep -F "SOURCE_COMMIT='13f04ab66bba2dc5f8442d410be0c96919b56710'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='5bd38574fb1f5244a571a91fdeb82c326d50795fe8c0475c1065277687db7b25'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_BYTES='167052'" "$BOOTSTRAP" >/dev/null
grep -F -- "--proto '=https'" "$BOOTSTRAP" >/dev/null
grep -F -- '--proto-redir' "$BOOTSTRAP" >/dev/null
grep -F -- '--tlsv1.2' "$BOOTSTRAP" >/dev/null
grep -F 'sha256sum --check --strict' "$BOOTSTRAP" >/dev/null
