#!/bin/sh
set -eu

PRODUCT='Vivolution Voice Platform'

fail() {
    printf '%s installer: %s\n' "$PRODUCT" "$*" >&2
    exit 1
}

case "${1:-}" in
    '') ;;
    --status)
        printf '%s\n' "$PRODUCT"
        printf '%s\n' 'Stable channel: no approved release is currently published.'
        printf '%s\n' 'Nothing was downloaded or installed.'
        exit 0
        ;;
    *) fail 'supported option: --status' ;;
esac

cat >&2 <<'MESSAGE'
Vivolution Voice Platform
A product of Vivolution Technologies LLC

No approved stable release is currently published in this distribution
repository. This bootstrap is intentionally fail-closed; nothing was downloaded
or installed.
MESSAGE
exit 1
