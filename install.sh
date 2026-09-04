#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'
RELEASE_VERSION='0.1.0-rc12'
SOURCE_COMMIT='4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04'
ARCHIVE_NAME='vivolution-voice-platform-0.1.0-rc12-amd64.tar.gz'
ARCHIVE_ROOT='vivolution-voice-platform-0.1.0-rc12'
ARCHIVE_SHA256='546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a'
ARCHIVE_BYTES='30724599'
ARCHIVE_URL="https://github.com/vivolution/vivolution-voice-platform-install/releases/download/v${RELEASE_VERSION}/${ARCHIVE_NAME}"
SIGNATURE_NAME="${ARCHIVE_NAME}.sig"
SIGNATURE_SHA256='bdbe44b605b009c957e4bcc2ed5b2725d3d2ed32b7e78f146b31443dbc89d127'
SIGNATURE_BYTES='334'
SIGNATURE_URL="${ARCHIVE_URL}.sig"
RELEASE_SIGNING_NAMESPACE='vivolution-voice-platform-release'
RELEASE_SIGNER_IDENTITY='vivolution-pilot-release'
RELEASE_SIGNING_PUBLIC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXDQQsKYGszOebD6Ik4+MxhqOXP72R114hI98N+kCt3'
MAX_ARCHIVE_BYTES='268435456'
MAX_ARCHIVE_ENTRIES='4096'
MAX_SIGNATURE_BYTES='16384'
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

metadata_is_final() {
    case "$SOURCE_COMMIT" in
        ''|*[!0-9a-f]*) return 1 ;;
    esac
    [ "${#SOURCE_COMMIT}" -eq 40 ] || return 1

    case "$ARCHIVE_SHA256" in
        ''|*[!0-9a-f]*) return 1 ;;
    esac
    case "$SIGNATURE_SHA256" in
        ''|*[!0-9a-f]*) return 1 ;;
    esac
    [ "${#ARCHIVE_SHA256}" -eq 64 ] || return 1
    [ "${#SIGNATURE_SHA256}" -eq 64 ] || return 1

    case "$ARCHIVE_BYTES" in
        ''|*[!0-9]*) return 1 ;;
    esac
    case "$SIGNATURE_BYTES" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$ARCHIVE_BYTES" -gt 0 ] || return 1
    [ "$ARCHIVE_BYTES" -le "$MAX_ARCHIVE_BYTES" ] || return 1
    [ "$SIGNATURE_BYTES" -gt 0 ] || return 1
    [ "$SIGNATURE_BYTES" -le "$MAX_SIGNATURE_BYTES" ] || return 1
}

validate_downloaded_file() {
    checked_path=$1
    checked_label=$2
    expected_bytes=$3
    maximum_bytes=$4
    expected_sha256=$5

    checked_bytes=$(wc -c < "$checked_path" | tr -d '[:space:]')
    case "$checked_bytes" in
        ''|*[!0-9]*) fail "downloaded ${checked_label} size is invalid" ;;
    esac
    [ "$checked_bytes" -gt 0 ] && [ "$checked_bytes" -le "$maximum_bytes" ] ||
        fail "downloaded ${checked_label} size is outside the approved limit: ${checked_bytes} bytes"
    [ "$checked_bytes" -eq "$expected_bytes" ] ||
        fail "downloaded ${checked_label} size does not match the release record: ${checked_bytes} bytes"

    printf '%s  %s\n' "$expected_sha256" "$checked_path" |
        sha256sum -c - >/dev/null 2>&1 ||
        fail "downloaded ${checked_label} SHA-256 verification failed"
}

verify_detached_signature() {
    signed_path=$1
    signature_path=$2
    allowed_signers_path=$3

    ssh-keygen -Y verify \
        -f "$allowed_signers_path" \
        -I "$RELEASE_SIGNER_IDENTITY" \
        -n "$RELEASE_SIGNING_NAMESPACE" \
        -s "$signature_path" \
        < "$signed_path" >/dev/null 2>&1 ||
        fail 'release artifact publisher signature verification failed'
}

case "${1:-}" in
    --status)
        if metadata_is_final; then
            printf '%s\n' \
                "$PRODUCT" \
                "Release candidate: v${RELEASE_VERSION}" \
                'Enabled roles: standalone Controller Plane and Edge Appliance' \
                'Qualified host: Debian GNU/Linux 13 AMD64/x86_64' \
                "Source commit: ${SOURCE_COMMIT}" \
                "Artifact SHA-256: ${ARCHIVE_SHA256}" \
                "Detached signature SHA-256: ${SIGNATURE_SHA256}" \
                "Publisher identity: ${RELEASE_SIGNER_IDENTITY}" \
                "Signature namespace: ${RELEASE_SIGNING_NAMESPACE}"
        else
            printf '%s\n' \
                "$PRODUCT" \
                "Release candidate: v${RELEASE_VERSION}" \
                'Release metadata: incomplete; installation and verification are disabled.' \
                'Nothing was downloaded or installed.'
        fi
        exit 0
        ;;
    --verify-only)
        MODE='verify-only'
        shift
        [ "$#" -eq 0 ] || fail '--verify-only does not accept installer arguments'
        ;;
esac

metadata_is_final ||
    fail 'RC12 release metadata is incomplete; nothing was downloaded or installed'

[ "$(id -u)" -eq 0 ] || fail 'run through sudo as documented'

for required_command in awk curl find id mkdir mktemp python3 readlink rm sha256sum ssh-keygen tar tr uname wc; do
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
signature="$TMP_ROOT/$SIGNATURE_NAME"
allowed_signers="$TMP_ROOT/release.allowed_signers"
listing="$TMP_ROOT/archive.list"
metadata="$TMP_ROOT/archive.metadata"
extract="$TMP_ROOT/source"

printf '%s\n' \
    "$PRODUCT v${RELEASE_VERSION}" \
    'A product of Vivolution Technologies LLC' \
    'Release scope: unified Controller Plane and Edge Appliance release-candidate testing.' \
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
    --max-time 60 \
    --output "$signature" \
    "$SIGNATURE_URL" || fail 'release artifact publisher signature download failed'

validate_downloaded_file \
    "$archive" 'artifact' "$ARCHIVE_BYTES" "$MAX_ARCHIVE_BYTES" "$ARCHIVE_SHA256"
validate_downloaded_file \
    "$signature" 'publisher signature' "$SIGNATURE_BYTES" "$MAX_SIGNATURE_BYTES" "$SIGNATURE_SHA256"

printf '%s %s\n' "$RELEASE_SIGNER_IDENTITY" "$RELEASE_SIGNING_PUBLIC_KEY" > "$allowed_signers" ||
    fail 'could not prepare the publisher trust policy'
verify_detached_signature "$archive" "$signature" "$allowed_signers"

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
    edge/requirements.txt \
    edge/vivolution_edge/agent.py \
    edge/vivolution_edge/renderer.py \
    installer/turnkey.py \
    packaging/bin/vivolution-edge-voice-check \
    packaging/bin/vivolution-teams-options-check \
    packaging/caddy/Caddyfile.template \
    packaging/systemd/vivolution-controller.service \
    packaging/systemd/vivolution-edge-agent.service \
    packaging/systemd/vivolution-edge-helper.service \
    packaging/systemd/vivolution-rtpengine@.service
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
    "roles": ["controller", "edge"],
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

printf 'Verified v%s artifact SHA-256 %s and detached publisher signature for %s.\n' \
    "$RELEASE_VERSION" "$ARCHIVE_SHA256" "$RELEASE_SIGNER_IDENTITY"

if [ "$MODE" = 'verify-only' ]; then
    printf '%s\n' 'Verification passed. Nothing was installed or changed on the host.'
    exit 0
fi

printf '%s\n' \
    'Starting the verified interactive installer.' \
    'Select either a standalone Controller Plane or an Edge Appliance.'
if [ -c /dev/tty ] && (: </dev/tty) 2>/dev/null; then
    "$installer" "$@" </dev/tty
else
    fail 'no controlling terminal is available; run from an interactive SSH session'
fi
