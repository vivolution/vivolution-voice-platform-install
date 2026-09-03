#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

[ "$(cat "$ROOT/VERSION")" = '0.1.0-rc1' ]
sh -n "$BOOTSTRAP"
"$BOOTSTRAP" --status | grep -F 'Role: standalone Controller Plane' >/dev/null

# The release bootstrap may download only the exact immutable GitHub Release asset.
grep -F "ARCHIVE_URL='https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v0.1.0-rc1/vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'" "$BOOTSTRAP" >/dev/null
grep -F "ARCHIVE_SHA256='56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed'" "$BOOTSTRAP" >/dev/null
grep -F "SOURCE_COMMIT='a0c2f9465fe50ec01b72d14c5be936a10218ac92'" "$BOOTSTRAP" >/dev/null
if grep -E 'eval[[:space:]]|sh[[:space:]]+-c|curl[^\n]*http://' "$BOOTSTRAP" >/dev/null; then
    echo 'Unsafe dynamic execution or insecure transport found.' >&2
    exit 1
fi
