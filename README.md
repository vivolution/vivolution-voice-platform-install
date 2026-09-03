# Vivolution Voice Platform Installer

Public, checksum-pinned release bootstrap for **Vivolution Voice Platform**, a product of **Vivolution Technologies LLC**.

## v0.1.0-rc1 Controller test

This release candidate installs **one new standalone Controller Plane** on a fresh **Debian GNU/Linux 13 AMD64** VM. Edge Appliance/SBC deployment is not included in this RC.

### One-line installation

Run from a normal interactive SSH session using a sudo-enabled administrator:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc1/install.sh && sudo sh "$tmp")
```

The command downloads the complete bootstrap before execution. The bootstrap then downloads one exact release artifact and verifies its byte size, SHA-256, archive safety, source commit, role, platform, internal file list, file modes, and every packaged file digest before starting the installer.

### VM and network prerequisites

- Fresh Debian 13 AMD64 (`x86_64`).
- Recommended: 2 vCPU, 8 GiB RAM, 64 GiB SSD. Enforced minimum: 2 vCPU, 4 GiB RAM, 40 GiB root disk.
- Static private IPv4 and confirmed public service IPv4 or dedicated one-to-one NAT.
- Two public DNS A records: one unique Controller-node FQDN and one stable Controller Shared FQDN, both resolving to the service IPv4.
- No AAAA record for either name in this IPv4-only RC.
- Inbound TCP 22 from approved administrators and TCP 80/443 as required for HTTPS/ACME.
- Outbound TCP 80/443, UDP/TCP 53, and UDP 123.
- External NSG/firewall/NAT ownership remains with the operator; the installer does not change it.

### Non-installing verification

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc1/install.sh && sh "$tmp" --verify-only)
```

### Exact release record

- Release: `0.1.0-rc1`
- Private source commit: `a0c2f9465fe50ec01b72d14c5be936a10218ac92`
- Artifact: `vivolution-voice-platform-0.1.0-rc1-controller-amd64.tar.gz`
- Artifact bytes: `111001`
- Artifact SHA-256: `56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed`
- SBOM SHA-256: `0b1c1edb6edc40ae9c31e4164a521fa070821a43a31ba42909f5461ddfba0755`

The complete package was installed and exercised in a clean Debian 13 systemd qualification host, including PostgreSQL, PgBouncer, Caddy, native Gunicorn/Django, first-login password replacement, mandatory TOTP MFA, static/media delivery, loopback-only internal listeners, service restart, and readiness recovery.

This is a controlled Controller release candidate, not an Edge/SBC, Microsoft-certified SBC, live-call, HA, or production-readiness claim.
