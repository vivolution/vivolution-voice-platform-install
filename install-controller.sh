#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'
COMPANY='Vivolution Technologies LLC'
CHANNEL='v0.1.0-rc1-internal'
PRIVATE_REPO='vivolution/vivolution-voice-platform'
EVIDENCE_REF='evidence/controller-rc1-pass-confirmed'
EVIDENCE_PATH='qualification/controller-rc1-deep-validation.json'
MAX_ARCHIVE_BYTES=67108864
MAX_ARCHIVE_ENTRIES=8192
MAX_EXPANDED_BYTES=268435456
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

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

case "${1:-}" in
    --status)
        printf '%s\n' "$PRODUCT"
        printf 'Company: %s\n' "$COMPANY"
        printf 'Channel: %s\n' "$CHANNEL"
        printf 'Distribution: authenticated internal validation channel\n'
        printf 'Target: one standalone Controller Plane on Debian 13 AMD64\n'
        printf 'Evidence ref: %s\n' "$EVIDENCE_REF"
        exit 0
        ;;
    --verify-only)
        MODE='verify-only'
        shift
        [ "$#" -eq 0 ] || fail '--verify-only does not accept installer arguments'
        ;;
esac

if [ "$(id -u)" -eq 0 ]; then
    fail 'run this bootstrap as the normal sudo-enabled operator, not as root; it preserves that user’s GitHub authentication and invokes sudo only after verification'
fi

[ -r /etc/os-release ] || fail '/etc/os-release is unavailable'
# shellcheck disable=SC1091
. /etc/os-release
[ "${ID:-}" = 'debian' ] || fail 'Debian GNU/Linux 13 is required'
[ "${VERSION_ID:-}" = '13' ] || fail 'Debian GNU/Linux 13 is required'
case "$(uname -m)" in
    x86_64|amd64) ;;
    *) fail 'AMD64/x86_64 architecture is required' ;;
esac

for command_name in gh python3 base64 sha256sum mktemp rm id uname wc tr awk sudo; do
    require_command "$command_name"
done

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    fail 'GitHub CLI is not authenticated. Run: gh auth login --hostname github.com'
fi
if ! gh repo view "$PRIVATE_REPO" >/dev/null 2>&1; then
    fail "the authenticated GitHub account cannot read ${PRIVATE_REPO}"
fi

umask 077
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vivolution-internal-bootstrap.XXXXXXXXXX") ||
    fail 'could not create a private temporary directory'
trap cleanup EXIT HUP INT TERM

report_path="${TMP_ROOT}/validation.json"
archive_path="${TMP_ROOT}/source.tar.gz"
extract_path="${TMP_ROOT}/source"
commit_path="${TMP_ROOT}/validated-commit"

printf 'Validating the approved internal Controller evidence...\n'
if ! gh api \
    -H 'Accept: application/vnd.github+json' \
    "/repos/${PRIVATE_REPO}/contents/${EVIDENCE_PATH}?ref=${EVIDENCE_REF}" \
    --jq '.content' |
    tr -d '\n' |
    base64 --decode > "$report_path"
then
    fail 'could not download the Controller validation evidence'
fi

python3 - "$report_path" "$commit_path" <<'PY'
import json
import re
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
commit_path = Path(sys.argv[2])
try:
    report = json.loads(report_path.read_text(encoding='utf-8'))
except Exception as exc:
    raise SystemExit(f'invalid validation evidence: {exc}')

required_success = ('source_and_installer', 'controller', 'documentation', 'overall')
for field in required_success:
    if report.get(field) != 'success':
        raise SystemExit(f'validation evidence is not approved: {field}={report.get(field)!r}')
commit = report.get('validated_commit', '')
if not re.fullmatch(r'[0-9a-f]{40}', commit):
    raise SystemExit('validation evidence does not contain a full lowercase commit SHA')
commit_path.write_text(commit + '\n', encoding='ascii')
PY

validated_commit=$(tr -d '[:space:]' < "$commit_path")
resolved_commit=$(gh api \
    -H 'Accept: application/vnd.github+json' \
    "/repos/${PRIVATE_REPO}/commits/${validated_commit}" \
    --jq '.sha') || fail 'could not resolve the validated private commit'
[ "$resolved_commit" = "$validated_commit" ] || fail 'private commit resolution did not match the validated commit'

printf 'Downloading exact validated source commit %s...\n' "$validated_commit"
if ! gh api \
    -H 'Accept: application/vnd.github+json' \
    "/repos/${PRIVATE_REPO}/tarball/${validated_commit}" > "$archive_path"
then
    fail 'validated private source archive download failed'
fi
archive_bytes=$(wc -c < "$archive_path" | tr -d '[:space:]')
case "$archive_bytes" in
    ''|*[!0-9]*) fail 'downloaded archive has an invalid size' ;;
esac
if [ "$archive_bytes" -eq 0 ] || [ "$archive_bytes" -gt "$MAX_ARCHIVE_BYTES" ]; then
    fail "downloaded archive size is outside the allowed range: ${archive_bytes} bytes"
fi
archive_sha256=$(sha256sum "$archive_path" | awk '{print $1}')

mkdir -p "$extract_path"
python3 - "$archive_path" "$extract_path" "$MAX_ARCHIVE_ENTRIES" "$MAX_EXPANDED_BYTES" <<'PY'
import pathlib
import sys
import tarfile

archive = pathlib.Path(sys.argv[1])
destination = pathlib.Path(sys.argv[2])
maximum_entries = int(sys.argv[3])
maximum_expanded = int(sys.argv[4])

with tarfile.open(archive, mode='r:gz') as handle:
    members = handle.getmembers()
    if not members or len(members) > maximum_entries:
        raise SystemExit('archive entry count is outside the allowed range')
    roots = set()
    expanded = 0
    for member in members:
        pure = pathlib.PurePosixPath(member.name)
        if pure.is_absolute() or not pure.parts or any(part in ('', '.', '..') for part in pure.parts):
            raise SystemExit(f'unsafe archive path: {member.name!r}')
        roots.add(pure.parts[0])
        if member.issym() or member.islnk() or member.isdev() or member.isfifo():
            raise SystemExit(f'archive contains a link or special file: {member.name!r}')
        if not (member.isfile() or member.isdir()):
            raise SystemExit(f'archive contains an unsupported object: {member.name!r}')
        if member.size < 0:
            raise SystemExit(f'archive contains a negative file size: {member.name!r}')
        expanded += member.size
        if expanded > maximum_expanded:
            raise SystemExit('archive expanded size exceeds the allowed limit')
    if len(roots) != 1:
        raise SystemExit('archive must contain exactly one top-level directory')
    handle.extractall(destination, filter='data')

root = destination / next(iter(roots))
required = (
    'installer/install.sh',
    'installer/turnkey.py',
    'controller/manage.py',
    'controller/requirements.txt',
    'config/product.json',
    'config/platform-support.json',
)
for relative in required:
    candidate = root / relative
    if not candidate.is_file() or candidate.is_symlink():
        raise SystemExit(f'validated source is missing required file: {relative}')

entrypoint = root / 'installer/install.sh'
entrypoint.chmod(entrypoint.stat().st_mode | 0o100)
(destination / '.source-root').write_text(str(root) + '\n', encoding='utf-8')
PY

source_root=$(tr -d '\n' < "${extract_path}/.source-root")
installer_path="${source_root}/installer/install.sh"
[ -x "$installer_path" ] || fail 'validated installer entry point is not executable'

printf 'Verified internal source commit %s\n' "$validated_commit"
printf 'Downloaded archive SHA-256 %s\n' "$archive_sha256"
printf 'Boundary: authenticated internal Controller release candidate; not an anonymous production release.\n'

if [ "$MODE" = 'verify-only' ]; then
    printf 'Verification passed; no sudo operation was performed and nothing was installed.\n'
    exit 0
fi

[ -c /dev/tty ] || fail 'an interactive controlling terminal is required'
printf 'Starting the verified Vivolution Controller installer...\n'
sudo "$installer_path" "$@" </dev/tty
