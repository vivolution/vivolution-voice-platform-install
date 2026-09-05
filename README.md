# Vivolution Voice Platform Installer

Public, auditable release channel for **Vivolution Voice Platform**, a product of
**Vivolution Technologies LLC**.

The complete product source remains private. This repository contains only the
small bootstrap, public release metadata, checksums/signatures, SBOMs, release
notes, and approved versioned release assets.

## Deploy your first Controller and two Edges

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc13/install.sh && printf '%s  %s\n' 'd0550a63256b0d099ce5e9c4d69bde0a78e6ec38cfe3289092c15f0d7dff8e8e' "$tmp" | sha256sum --check --status && sudo sh "$tmp")
```

Run this command inside an interactive SSH session on **each of three fresh
Debian 13 AMD64 VMs**, starting with the Controller:

1. `Vivo-Voice-CP1`: select **1 — Create a new standalone Controller Plane**.
2. Prepare the two Edge identities and their separate enrollment grants on the Controller.
3. `Vivo-Voice-Edge1` and `Vivo-Voice-Edge2`: select **3 — Deploy an Edge Appliance (SBC)** on each, then approve each fingerprint on the Controller.

Use 2 vCPU, 8 GiB RAM and 64 GB disk per VM for the qualified pilot shape.
Prepare public DNS A records with TTL **60** and certificate-validation network access first. Minimal
images also need `ca-certificates curl python3 openssh-client sudo`.
Follow the [complete three-VM deployment guide](docs/first-controller-two-edges.md)
for DNS, firewall, credentials, grant transfer and approval.

This command pins **RC13**, the signed release with three-host installation
evidence. It verifies the bootstrap checksum before execution, then the bootstrap
verifies the exact product archive and publisher signature. RC14 development
changes are not included. **RC13 is for a controlled internal pilot; production
and Controller HA qualification remain open.**

No stable release is promoted yet. `main/install.sh` remains intentionally
unavailable for installation.

Check the channel without installing:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/main/install.sh && sudo sh "$tmp" --status)
```

## Release policy

- `main/install.sh` remains fail-closed until a stable release is explicitly
  promoted. Preview candidates are available only from immutable version-pinned
  tags.
- Version-pinned paths remain available for reproducibility.
- Published tags and release assets are protected by GitHub release
  immutability and are never replaced.
- Every immutable release receives a cryptographically verifiable GitHub
  release attestation.
- The bootstrap verifies the exact artifact size and digest before execution.
- RC12 and later bootstraps also require an OpenSSH detached publisher
  signature bound to the documented Vivolution release namespace and identity.
- A failed validation results in a new release candidate, never a rewritten tag.
- The current three-host standalone pilot uses a version-pinned RC; Controller
  HA remains a separate qualification target.
- Final `v0.1.0` requires the remaining voice, operational, lifecycle, security,
  capacity and applicable external-acceptance gates as well as installation proof.

## Supported product target

The current product line targets native services on **Debian GNU/Linux 13
AMD64/x86-64**, with one standalone Controller Plane and two dedicated Edge
Appliances. Controller and Edge roles must not share a host.

RC13 detached-signature verification requires the Debian `openssh-client`
package and an `ssh-keygen` version supporting `-Y verify` before the product
archive can be authenticated.

The dated [RC13 qualification summary](docs/rc13-qualification.md) records the
bounded clean-host, restart, and Controller-outage proof and keeps the remaining
production gates explicit.

## Security

Never paste passwords, TOTP seeds, private keys, PFX passwords, carrier
credentials, Microsoft credentials, or enrollment grants into an issue. See
[SECURITY.md](SECURITY.md).
