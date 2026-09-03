#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'
COMPANY='Vivolution Technologies LLC'
RELEASE_VERSION='0.1.0-rc1'
SOURCE_COMMIT='a0c2f9465fe50ec01b72d14c5be936a10218ac92'
ARCHIVE_NAME='vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'
ARCHIVE_ROOT='vivolution-voice-platform-0.1.0-rc1'
ARCHIVE_URL='https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v0.1.0-rc1/vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz'
ARCHIVE_SHA256='56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed'
ARCHIVE_BYTES='111001'
MAX_ARCHIVE_ENTRIES='2048'
MAX_EXTRACTED_BYTES='67108864'
MODE='install'
LOCAL_ARCHIVE=''
BOOTSTRAP_TMP=''

fail() {
    printf '%s installer: %s\n' "$PRODUCT" "$*" >&2
    exit 1
}

cleanup() {
    if [ -n "$BOOTSTRAP_TMP" ] && [ -d "$BOOTSTRAP_TMP" ]; then
        rm -rf -- "$BOOTSTRAP_TMP"
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

usage() {
    cat <<EOF
$PRODUCT $RELEASE_VERSION Controller installer

Usage:
  install.sh [installer arguments]
  install.sh --verify-only
  install.sh --verify-archive FILE
  install.sh --status

Qualified role: one new standalone Controller Plane on Debian 13 AMD64.
Edge Appliance deployment is not included in this release candidate.
EOF
}

case "${1:-}" in
    --status)
        [ "$#" -eq 1 ] || fail '--status does not accept additional arguments'
        printf '%s\n' "$PRODUCT"
        printf 'Company: %s\n' "$COMPANY"
        printf 'Release: %s\n' "$RELEASE_VERSION"
        printf 'Source commit: %s\n' "$SOURCE_COMMIT"
        printf 'Role: standalone Controller Plane\n'
        printf 'Platform: Debian 13 AMD64\n'
        printf 'Artifact SHA-256: %s\n' "$ARCHIVE_SHA256"
        exit 0
        ;;
    --verify-only)
        [ "$#" -eq 1 ] || fail '--verify-only does not accept additional arguments'
        MODE='verify-only'
        shift
        ;;
    --verify-archive)
        [ "$#" -eq 2 ] || fail '--verify-archive requires exactly one file path'
        MODE='verify-archive'
        LOCAL_ARCHIVE=$2
        shift 2
        ;;
    --help|-h)
        usage
        exit 0
        ;;
esac

for command_name in cp mkdir python3 sha256sum wc tr mktemp rm id; do
    require_command "$command_name"
done
if [ "$MODE" != 'verify-archive' ]; then
    require_command curl
fi
if [ "$MODE" = 'install' ] && [ "$(id -u)" -ne 0 ]; then
    fail 'run the installer as root (the published command uses sudo)'
fi

umask 077
BOOTSTRAP_TMP=$(mktemp -d "${TMPDIR:-/tmp}/vivolution-bootstrap.XXXXXXXXXX") ||
    fail 'could not create a private temporary directory'
trap cleanup EXIT HUP INT TERM

archive_path="$BOOTSTRAP_TMP/$ARCHIVE_NAME"
extract_path="$BOOTSTRAP_TMP/extracted"

if [ "$MODE" = 'verify-archive' ]; then
    if [ ! -f "$LOCAL_ARCHIVE" ] || [ -L "$LOCAL_ARCHIVE" ]; then
        fail 'local archive is missing, not regular, or is a symbolic link'
    fi
    cp -- "$LOCAL_ARCHIVE" "$archive_path"
else
    printf 'Downloading %s %s Controller release candidate...\n' "$PRODUCT" "$RELEASE_VERSION"
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
        --max-time 300 \
        --output "$archive_path" \
        "$ARCHIVE_URL" || fail 'release archive download failed'
fi

archive_bytes=$(wc -c < "$archive_path" | tr -d '[:space:]')
case "$archive_bytes" in
    ''|*[!0-9]*) fail 'downloaded archive has an invalid size' ;;
esac
[ "$archive_bytes" = "$ARCHIVE_BYTES" ] ||
    fail "release archive size mismatch: expected $ARCHIVE_BYTES bytes, received $archive_bytes"
printf '%s  %s\n' "$ARCHIVE_SHA256" "$archive_path" |
    sha256sum --check --strict >/dev/null 2>&1 ||
    fail 'release archive SHA-256 verification failed'

mkdir -p "$extract_path"
python3 - "$archive_path" "$extract_path" "$ARCHIVE_ROOT" "$SOURCE_COMMIT" \
    "$RELEASE_VERSION" "$MAX_ARCHIVE_ENTRIES" "$MAX_EXTRACTED_BYTES" <<'PY'
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import stat
import sys
import tarfile

archive = Path(sys.argv[1])
extract = Path(sys.argv[2])
archive_root = sys.argv[3]
source_commit = sys.argv[4]
release = sys.argv[5]
maximum_entries = int(sys.argv[6])
maximum_bytes = int(sys.argv[7])


def stop(message: str) -> None:
    raise SystemExit(f"archive validation failed: {message}")


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


with tarfile.open(archive, mode="r:gz") as bundle:
    members = bundle.getmembers()
    if not members or len(members) > maximum_entries:
        stop("entry count is outside the approved range")
    seen: set[str] = set()
    extracted_bytes = 0
    for member in members:
        name = member.name
        if name in seen:
            stop(f"duplicate path: {name}")
        seen.add(name)
        if any(ord(character) < 32 or ord(character) == 127 for character in name):
            stop("an archive path contains a control character")
        path = PurePosixPath(name)
        if path.is_absolute() or any(part in {"", ".", ".."} for part in path.parts):
            stop(f"unsafe path: {name}")
        if name != archive_root and not name.startswith(archive_root + "/"):
            stop(f"path is outside the approved archive root: {name}")
        if not (member.isfile() or member.isdir()):
            stop(f"links and special files are forbidden: {name}")
        if member.isfile():
            if member.size < 0:
                stop(f"negative file size: {name}")
            extracted_bytes += member.size
            if extracted_bytes > maximum_bytes:
                stop("uncompressed archive size exceeds the approved limit")
    required = {
        f"{archive_root}/RELEASE-MANIFEST.json",
        f"{archive_root}/VERSION",
        f"{archive_root}/controller/manage.py",
        f"{archive_root}/controller/requirements.txt",
        f"{archive_root}/installer/install.sh",
        f"{archive_root}/installer/turnkey.py",
        f"{archive_root}/packaging/systemd/vivolution-controller.service",
        f"{archive_root}/packaging/caddy/Caddyfile.template",
    }
    missing = sorted(required - seen)
    if missing:
        stop("required paths are missing: " + ", ".join(missing))
    bundle.extractall(extract, filter="data")

root = extract / archive_root
if not root.is_dir() or root.is_symlink():
    stop("the expected release root was not extracted safely")
for candidate in root.rglob("*"):
    metadata = candidate.lstat()
    if stat.S_ISLNK(metadata.st_mode) or not (stat.S_ISREG(metadata.st_mode) or stat.S_ISDIR(metadata.st_mode)):
        stop(f"unsafe extracted object: {candidate.relative_to(root)}")

manifest_path = root / "RELEASE-MANIFEST.json"
try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except (OSError, UnicodeError, ValueError) as error:
    stop(f"internal manifest is unreadable: {error}")
expected_identity = {
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
for key, value in expected_identity.items():
    if manifest.get(key) != value:
        stop(f"internal manifest identity mismatch for {key}")
records = manifest.get("files")
if not isinstance(records, list):
    stop("internal manifest file list is invalid")
approved: dict[str, dict[str, object]] = {}
for record in records:
    if not isinstance(record, dict):
        stop("internal manifest contains a malformed file record")
    relative = record.get("path")
    if not isinstance(relative, str) or relative in approved:
        stop("internal manifest contains an unsafe or duplicate file path")
    path = PurePosixPath(relative)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in path.parts):
        stop(f"internal manifest contains an unsafe path: {relative}")
    approved[relative] = record
actual: dict[str, Path] = {}
for candidate in root.rglob("*"):
    if candidate.is_file() and candidate != manifest_path:
        actual[candidate.relative_to(root).as_posix()] = candidate
if set(actual) != set(approved):
    stop("extracted file set does not match the signed release record")
for relative, path in actual.items():
    record = approved[relative]
    if record.get("sha256") != digest(path):
        stop(f"file digest mismatch: {relative}")
    if record.get("bytes") != path.stat().st_size:
        stop(f"file size mismatch: {relative}")
    mode = record.get("mode")
    if mode not in {"0644", "0755"} or stat.S_IMODE(path.stat().st_mode) != int(mode, 8):
        stop(f"file mode mismatch: {relative}")
entrypoint = root / "installer/install.sh"
if not entrypoint.is_file() or not os.access(entrypoint, os.X_OK):
    stop("installer entry point is missing or not executable")
PY

printf 'Verified %s bytes and SHA-256 %s.\n' "$ARCHIVE_BYTES" "$ARCHIVE_SHA256"
printf 'Verified source commit %s and complete internal file manifest.\n' "$SOURCE_COMMIT"

if [ "$MODE" = 'verify-only' ] || [ "$MODE" = 'verify-archive' ]; then
    printf '%s %s Controller archive verification passed; nothing was installed.\n' \
        "$PRODUCT" "$RELEASE_VERSION"
    exit 0
fi

installer_path="$extract_path/$ARCHIVE_ROOT/installer/install.sh"
printf 'Starting the verified %s Controller installer...\n' "$PRODUCT"
if [ -c /dev/tty ] && ( : </dev/tty ) 2>/dev/null; then
    "$installer_path" "$@" </dev/tty
else
    fail 'no controlling terminal is available; run from an interactive SSH session or use --verify-only'
fi
