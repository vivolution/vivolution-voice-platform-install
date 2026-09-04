# Operator safety

- Use only a version-pinned command published in an approved release notice.
- Confirm that the pinned bootstrap reports the expected publisher identity,
  release-signing namespace, artifact SHA-256, and detached-signature SHA-256
  before installation. RC12 requires `ssh-keygen -Y verify` support on the host.
- Never paste credentials, private keys, PFX passwords, TOTP seeds, enrollment grants, or Microsoft/carrier secrets into GitHub issues or terminal command lines.
- Run the installer only on a fresh supported host.
- Review detected interfaces, private/public IPv4 values, DNS, NAT, and external-firewall requirements before authorizing mutation.
- Preserve the installer ledger and redacted support bundle after any failure.
- Do not reuse or rewrite a published release tag.
