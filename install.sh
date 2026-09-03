#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'
RELEASE_VERSION='0.1.0-rc2'
SOURCE_COMMIT='13f04ab66bba2dc5f8442d410be0c96919b56710'
ARCHIVE_NAME='vivolution-voice-platform-0.1.0-rc2-controller-amd64.tar.gz'
ARCHIVE_ROOT='vivolution-voice-platform-0.1.0-rc2'
ARCHIVE_SHA256='5bd38574fb1f5244a571a91fdeb82c326d50795fe8c0475c1065277687db7b25'
ARCHIVE_BYTES='167052'
ARCHIVE_URL="https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v${RELEASE_VERSION}/${ARCHIVE_NAME}"
MAX_ARCHIVE_BYTES='268435456'
MAX_ARCHIVE_ENTRIES='4096'
MODE='install'
TMP_ROOT=''

fail() {
    printf '%s bootstrap: %s\n' "$PRODUCT" "$*" >&2
    exit 1
}

cleanup() {
    if [ -n "$TMP_ROOT" ] && [ -d "$TMP_ROOT" ]; then
        rm -rf -- "$TMP_ROOT"
    fi
}

trap cleanup 0
trap 'exit 130' 1 2 15

case "${1:-}" in
    --status)
        printf '%s\n' \
            "$PRODUCT" \
            "Release candidate: v${RELEASE_VERSION}" \
            'Enabled role: Create a new standalone Controller Plane' \
            'Qualified host: Debian GNU/Linux 13 AMD64/x86_64' \
            "Source commit: ${SOURCE_COMMIT}" \
            "Artifact SHA-256: ${ARCHIVE_SHA256}"
        exit 0
        ;;
    --verify-only)
        MODE='verify-only'
        shift
        [ "$#" -eq 0 ] || fail '--verify-only does not accept installer arguments'
        ;;
esac

[ "$(id -u)" -eq 0 ] || fail 'run through sudo as documented'

for required_command in awk curl find id mkdir mktemp python3 readlink rm sha256sum tar tr uname wc; do
    command -v "$required_command" >/dev/null 2>&1 || fail "required command not found: $required_command"
done

[ "$(uname -m)" = 'x86_64' ] || fail 'this release candidate requires AMD64/x86_64'

os_release='/etc/os-release'
[ -e "$os_release" ] || fail '/etc/os-release is missing'
if [ -L "$os_release" ]; then
    target=$(readlink "$os_release") || fail 'could not read /etc/os-release symlink'
    case "$target" in
        ../usr/lib/os-release|/usr/lib/os-release) ;;
        *) fail '/etc/os-release has an unsupported symlink target' ;;
    esac
fi
os_id=$(awk -F= '$1 == "ID" { value=$2; gsub(/^"|"$/, "", value); print value }' "$os_release")
os_version=$(awk -F= '$1 == "VERSION_ID" { value=$2; gsub(/^"|"$/, "", value); print value }' "$os_release")
[ "$os_id" = 'debian' ] && [ "$os_version" = '13' ] || fail 'this release candidate requires Debian GNU/Linux 13'

python3 -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 13) else 1)' ||
    fail 'this release candidate requires Debian 13 system Python 3.13'

umask 077
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vivolution-bootstrap.XXXXXXXXXX") ||
    fail 'could not create a private temporary directory'
archive="$TMP_ROOT/$ARCHIVE_NAME"
listing="$TMP_ROOT/archive.list"
metadata="$TMP_ROOT/archive.metadata"
extract="$TMP_ROOT/source"

printf '%s\n' \
    "$PRODUCT v${RELEASE_VERSION}" \
    'A product of Vivolution Technologies LLC' \
    'Release scope: standalone Controller Plane release-candidate testing.' \
    "Downloading exact artifact from source commit ${SOURCE_COMMIT}..."

curl \
    --fail \
    --show-error \
    --silent \
    --location \
    --proto '=https' \
    --proto-redir '=https' \
    --tlsv1.2 \
    --retry 3 \
    --retry-all-errors \
    --connect-timeout 10 \
    --max-time 600 \
    --output "$archive" \
    "$ARCHIVE_URL" || fail 'release artifact download failed'

bytes=$(wc -c < "$archive" | tr -d '[:space:]')
case "$bytes" in
    ''|*[!0-9]*) fail 'downloaded artifact size is invalid' ;;
esac
[ "$bytes" -gt 0 ] && [ "$bytes" -le "$MAX_ARCHIVE_BYTES" ] ||
    fail "downloaded artifact size is outside the approved limit: ${bytes} bytes"
[ "$bytes" -eq "$ARCHIVE_BYTES" ] ||
    fail "downloaded artifact size does not match the release record: ${bytes} bytes"

printf '%s  %s\n' "$ARCHIVE_SHA256" "$archive" |
    sha256sum --check --strict >/dev/null 2>&1 ||
    fail 'release artifact SHA-256 verification failed'

if ! tar -tzf "$archive" > "$listing"; then
    fail 'verified artifact is not a readable gzip-compressed tar archive'
fi
if ! awk -v prefix="${ARCHIVE_ROOT}/" -v maximum="$MAX_ARCHIVE_ENTRIES" '
    BEGIN { found=0; count=0 }
    index($0, prefix) != 1 { exit 1 }
    {
        relative=substr($0, length(prefix) + 1)
        if (relative ~ /(^|\/)\.\.($|\/)/) exit 1
        if (relative ~ /(^|\/)\.($|\/)/) exit 1
        if (seen[$0]++) exit 1
        count++
        if (count > maximum) exit 1
        found=1
    }
    END { if (!found) exit 1 }
' "$listing"; then
    fail 'verified artifact has an unsafe or unexpected path layout'
fi
if ! LC_ALL=C tar -tvzf "$archive" > "$metadata"; then
    fail 'verified artifact metadata could not be read'
fi
if ! awk '
    substr($0, 1, 1) != "-" && substr($0, 1, 1) != "d" { exit 1 }
    END { if (NR == 0) exit 1 }
' "$metadata"; then
    fail 'verified artifact contains a link or special file'
fi

mkdir "$extract"
tar -xzf "$archive" \
    --directory "$extract" \
    --no-same-owner \
    --no-same-permissions || fail 'verified artifact extraction failed'

source_root="$extract/$ARCHIVE_ROOT"
installer="$source_root/installer/install.sh"
[ -d "$source_root" ] && [ ! -L "$source_root" ] ||
    fail 'verified artifact did not create the expected release directory'
[ -z "$(find "$source_root" -type l -print -quit)" ] ||
    fail 'verified artifact contains a symbolic link after extraction'
[ -f "$installer" ] && [ ! -L "$installer" ] && [ -x "$installer" ] ||
    fail 'verified artifact is missing its executable installer entry point'

for required_path in \
    RELEASE-MANIFEST.json \
    VERSION \
    config/platform-support.json \
    controller/manage.py \
    controller/requirements.txt \
    installer/turnkey.py \
    packaging/caddy/Caddyfile.template \
    packaging/systemd/vivolution-controller.service
do
    candidate="$source_root/$required_path"
    [ -f "$candidate" ] && [ ! -L "$candidate" ] ||
        fail "verified artifact is incomplete: $required_path"
done

python3 - "$source_root/RELEASE-MANIFEST.json" "$source_root/VERSION" \
    "$RELEASE_VERSION" "$SOURCE_COMMIT" <<'PY'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
version_path = pathlib.Path(sys.argv[2])
release = sys.argv[3]
source_commit = sys.argv[4]
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
expected = {
    "release": release,
    "source_commit": source_commit,
    "role": "controller",
    "os": "debian-13",
    "architecture": "amd64",
    "entrypoint": "installer/install.sh",
}
for key, value in expected.items():
    if manifest.get(key) != value:
        raise SystemExit(f"release manifest mismatch for {key}")
if version_path.read_text(encoding="utf-8").strip() != release:
    raise SystemExit("release VERSION mismatch")
PY

printf 'Verified v%s artifact SHA-256 %s.\n' "$RELEASE_VERSION" "$ARCHIVE_SHA256"

if [ "$MODE" = 'verify-only' ]; then
    printf '%s\n' 'Verification passed. Nothing was installed or changed on the host.'
    exit 0
fi

printf '%s\n' \
    'Starting the verified interactive installer.' \
    'Select: Create a new Controller Plane.'
if [ -c /dev/tty ] && (: </dev/tty) 2>/dev/null; then
    "$installer" "$@" </dev/tty
else
    fail 'no controlling terminal is available; run from an interactive SSH session'
fi
