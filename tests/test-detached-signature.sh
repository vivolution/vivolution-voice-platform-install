#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
BOOTSTRAP="$ROOT/install.sh"

for required_command in awk cp mktemp rm sha256sum ssh-keygen tr wc; do
    command -v "$required_command" >/dev/null 2>&1 || {
        printf 'Required test command not found: %s\n' "$required_command" >&2
        exit 1
    }
done

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vivolution-signature-test.XXXXXXXXXX")
cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup 0
trap 'exit 130' 1 2 15

helpers="$TEST_ROOT/bootstrap-verifiers.sh"
awk '
    /^validate_downloaded_file\(\) \{/ { capture=1 }
    capture { print }
    capture && /^}$/ { exit }
' "$BOOTSTRAP" > "$helpers"
awk '
    /^verify_detached_signature\(\) \{/ { capture=1 }
    capture { print }
    capture && /^}$/ { exit }
' "$BOOTSTRAP" >> "$helpers"
grep -F 'validate_downloaded_file()' "$helpers" >/dev/null
grep -F 'verify_detached_signature()' "$helpers" >/dev/null

fail() {
    printf 'test verifier: %s\n' "$*" >&2
    exit 1
}

# shellcheck source=/dev/null
. "$helpers"

RELEASE_SIGNING_NAMESPACE='vivolution-voice-platform-release'
RELEASE_SIGNER_IDENTITY='vivolution-pilot-release'

test_key="$TEST_ROOT/test-only-ed25519"
wrong_key="$TEST_ROOT/wrong-test-only-ed25519"
payload="$TEST_ROOT/release.tar.gz"
allowed_signers="$TEST_ROOT/allowed_signers"
wrong_allowed_signers="$TEST_ROOT/wrong-allowed-signers"

ssh-keygen -q -t ed25519 -N '' -f "$test_key"
ssh-keygen -q -t ed25519 -N '' -f "$wrong_key"
printf '%s\n' 'synthetic release archive bytes for detached-signature tests' > "$payload"
ssh-keygen -q -Y sign -f "$test_key" -n "$RELEASE_SIGNING_NAMESPACE" "$payload" >/dev/null 2>&1
signature="${payload}.sig"

awk -v identity="$RELEASE_SIGNER_IDENTITY" '{ print identity " " $1 " " $2 }' \
    "${test_key}.pub" > "$allowed_signers"
awk -v identity="$RELEASE_SIGNER_IDENTITY" '{ print identity " " $1 " " $2 }' \
    "${wrong_key}.pub" > "$wrong_allowed_signers"

payload_bytes=$(wc -c < "$payload" | tr -d '[:space:]')
payload_sha256=$(sha256sum "$payload" | awk '{ print $1 }')
signature_bytes=$(wc -c < "$signature" | tr -d '[:space:]')
signature_sha256=$(sha256sum "$signature" | awk '{ print $1 }')

validate_downloaded_file "$payload" 'test artifact' "$payload_bytes" 4096 "$payload_sha256"
validate_downloaded_file "$signature" 'test signature' "$signature_bytes" 4096 "$signature_sha256"
verify_detached_signature "$payload" "$signature" "$allowed_signers"

expect_failure() {
    failure_label=$1
    shift
    if ("$@") >"$TEST_ROOT/failure.stdout" 2>"$TEST_ROOT/failure.stderr"; then
        printf 'Expected failure did not occur: %s\n' "$failure_label" >&2
        exit 1
    fi
}

expect_failure 'wrong byte count' \
    validate_downloaded_file "$payload" 'test artifact' "$((payload_bytes + 1))" 4096 "$payload_sha256"
expect_failure 'maximum byte count exceeded' \
    validate_downloaded_file "$payload" 'test artifact' "$payload_bytes" "$((payload_bytes - 1))" "$payload_sha256"
expect_failure 'wrong SHA-256' \
    validate_downloaded_file "$payload" 'test artifact' "$payload_bytes" 4096 \
    '0000000000000000000000000000000000000000000000000000000000000000'
expect_failure 'signature maximum byte count exceeded' \
    validate_downloaded_file "$signature" 'test signature' "$signature_bytes" \
    "$((signature_bytes - 1))" "$signature_sha256"

tampered_payload="$TEST_ROOT/tampered-release.tar.gz"
cp "$payload" "$tampered_payload"
printf '%s\n' 'tamper' >> "$tampered_payload"
expect_failure 'tampered artifact signature' \
    verify_detached_signature "$tampered_payload" "$signature" "$allowed_signers"

tampered_signature="$TEST_ROOT/tampered-release.tar.gz.sig"
awk '
    NR == 2 {
        replacement = substr($0, 1, 1) == "A" ? "B" : "A"
        $0 = replacement substr($0, 2)
    }
    { print }
' "$signature" > "$tampered_signature"
expect_failure 'tampered signature hash' \
    validate_downloaded_file "$tampered_signature" 'test signature' \
    "$signature_bytes" 4096 "$signature_sha256"
expect_failure 'tampered signature verification' \
    verify_detached_signature "$payload" "$tampered_signature" "$allowed_signers"

expect_failure 'wrong signing key' \
    verify_detached_signature "$payload" "$signature" "$wrong_allowed_signers"
expect_failure 'missing signature' \
    verify_detached_signature "$payload" "$TEST_ROOT/missing.sig" "$allowed_signers"
# shellcheck disable=SC2016  # Positional parameters expand inside the child shell.
expect_failure 'wrong namespace' sh -c '
    RELEASE_SIGNING_NAMESPACE=wrong-release-namespace
    export RELEASE_SIGNING_NAMESPACE
    . "$1"
    verify_detached_signature "$2" "$3" "$4"
' sh "$helpers" "$payload" "$signature" "$allowed_signers"
# shellcheck disable=SC2016  # Positional parameters expand inside the child shell.
expect_failure 'wrong signer identity' sh -c '
    RELEASE_SIGNER_IDENTITY=wrong-release-identity
    export RELEASE_SIGNER_IDENTITY
    . "$1"
    verify_detached_signature "$2" "$3" "$4"
' sh "$helpers" "$payload" "$signature" "$allowed_signers"

printf '%s\n' 'Detached publisher-signature verification tests passed.'
