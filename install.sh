#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'
COMPANY='Vivolution Technologies LLC'
RELEASE_VERSION='0.1.0-rc1'
SOURCE_COMMIT='a0c2f9465fe50ec01b72d14c5be936a10218ac92'
ARCHIVE_NAME='vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'
ARCHIVE_ROOT='vivolution-voice-platform-0.1.0-rc1'
ARCHIVE_SHA256='56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed'
ARCHIVE_BYTES='111001'
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
            "A product of $COMPANY" \
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
        if [ "$#" -ne 0 ]; then
            fail '--verify-only does not accept installer arguments'
        fi
        ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    fail 'run through sudo as documented'
fi

for required_command in awk curl find id mkdir mktemp python3 readlink rm sha256sum tar tr uname wc; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        fail "required command not found: $required_command"
    fi
done

if [ "$(uname -m)" != 'x86_64' ]; then
    fail 'this release candidate requires AMD64/x86_64'
fi

os_release='/etc/os-release'
if [ ! -e "$os_release" ]; then
    fail '/etc/os-release is missing'
fi
if [ -L "$os_release" ]; then
    target=$(readlink "$os_release") || fail 'could not read /etc/os-release symlink'
    case "$target" in
        ../usr/lib/os-release|/usr/lib/os-release) ;;
        *) fail '/etc/os-release has an unsupported symlink target' ;;
    esac
fi
os_id=$(awk -F= '$1 == "ID" { value=$2; gsub(/^"|"$/, "", value); print value }' "$os_release")
os_version=$(awk -F= '$1 == "VERSION_ID" { value=$2; gsub(/^"|"$/, "", value); print value }' "$os_release")
if [ "$os_id" != 'debian' ] || [ "$os_version" != '13' ]; then
    fail 'this release candidate requires Debian GNU/Linux 13'
fi

if ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 13) else 1)'; then
    fail 'this release candidate requires Debian 13 system Python 3.13'
fi

umask 077
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vivolution-bootstrap.XXXXXXXXXX") ||
    fail 'could not create a private temporary directory'
archive="$TMP_ROOT/$ARCHIVE_NAME"
listing="$TMP_ROOT/archive.list"
metadata="$TMP_ROOT/archive.metadata"
extract="$TMP_ROOT/source"

printf '%s\n' \
    "$PRODUCT v${RELEASE_VERSION}" \
    "A product of $COMPANY" \
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
if [ "$bytes" -le 0 ] || [ "$bytes" -gt "$MAX_ARCHIVE_BYTES" ]; then
    fail "downloaded artifact size is outside the approved limit: ${bytes} bytes"
fi
if [ "$bytes" -ne "$ARCHIVE_BYTES" ]; then
    fail "downloaded artifact size does not match the release record: ${bytes} bytes"
fi

if ! printf '%s  %s\n' "$ARCHIVE_SHA256" "$archive" |
    sha256sum --check --strict >/dev/null 2>&1
then
    fail 'release artifact SHA-256 verification failed'
fi

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
if ! tar -xzf "$archive" \
    --directory "$extract" \
    --no-same-owner \
    --no-same-permissions
then
    fail 'verified artifact extraction failed'
fi

source_root="$extract/$ARCHIVE_ROOT"
installer="$source_root/installer/install.sh"
if [ ! -d "$source_root" ] || [ -L "$source_root" ]; then
    fail 'verified artifact did not create the expected release directory'
fi
if [ -n "$(find "$source_root" -type l -print -quit)" ]; then
    fail 'verified artifact contains a symbolic link after extraction'
fi
if [ ! -f "$installer" ] || [ -L "$installer" ] || [ ! -x "$installer" ]; then
    fail 'verified artifact is missing its executable installer entry point'
fi

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
    if [ ! -f "$candidate" ] || [ -L "$candidate" ]; then
        fail "verified artifact is incomplete: $required_path"
    fi
done

python3 - "$source_root" "$RELEASE_VERSION" "$SOURCE_COMMIT" <<'PY'
import hashlib
import json
import pathlib
import stat
import sys

root = pathlib.Path(sys.argv[1])
release = sys.argv[2]
source_commit = sys.argv[3]
manifest_path = root / "RELEASE-MANIFEST.json"
version_path = root / "VERSION"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
expected = {
    "schema_version": 1,
    "product": "Vivolution Voice Platform",
    "company": "Vivolution Technologies LLC",
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
records = manifest.get("files")
if not isinstance(records, list) or not records:
    raise SystemExit("release file manifest is missing")
listed = set()
for record in records:
    relative = record.get("path")
    if not isinstance(relative, str):
        raise SystemExit("release file path is invalid")
    pure = pathlib.PurePosixPath(relative)
    if pure.is_absolute() or any(part in {"", ".", ".."} for part in pure.parts):
        raise SystemExit(f"unsafe release file path: {relative}")
    if relative in listed:
        raise SystemExit(f"duplicate release file path: {relative}")
    listed.add(relative)
    path = root / pure
    metadata = path.lstat()
    if not stat.S_ISREG(metadata.st_mode) or path.is_symlink():
        raise SystemExit(f"release file is missing or unsafe: {relative}")
    if metadata.st_size != record.get("bytes"):
        raise SystemExit(f"release file size mismatch: {relative}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != record.get("sha256"):
        raise SystemExit(f"release file digest mismatch: {relative}")
    expected_mode = int(str(record.get("mode")), 8)
    if stat.S_IMODE(metadata.st_mode) != expected_mode:
        raise SystemExit(f"release file mode mismatch: {relative}")
actual = {
    path.relative_to(root).as_posix()
    for path in root.rglob("*")
    if path.is_file() and path.name != "RELEASE-MANIFEST.json"
}
if actual != listed:
    raise SystemExit("release file allowlist mismatch")
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
