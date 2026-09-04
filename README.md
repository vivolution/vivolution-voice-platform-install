# Vivolution Voice Platform Installer

Public, auditable release channel for **Vivolution Voice Platform**, a product of
**Vivolution Technologies LLC**.

The complete product source remains private. This repository contains only the
small bootstrap, public release metadata, checksums/signatures, SBOMs, release
notes, and approved versioned release assets.

## Permanent one-line command

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/main/install.sh && sudo sh "$tmp")
```

Downloading the complete bootstrap before execution ensures a failed or partial
transfer cannot be mistaken for a successful installation.

**No stable release is promoted yet.** The permanent command exits safely
without downloading a product artifact or changing the host. An immutable
unified internal-pilot candidate is available through the version-pinned RC10
command after its GitHub prerelease is published:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc10/install.sh && sudo sh "$tmp")
```

Check the channel without installing:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/main/install.sh && sudo sh "$tmp" --status)
```

## Release policy

- `main/install.sh` points only to the latest explicitly promoted release.
- Version-pinned paths remain available for reproducibility.
- Published tags and release assets are protected by GitHub release immutability and are never replaced.
- Every immutable release receives a cryptographically verifiable GitHub release attestation.
- The bootstrap verifies the exact artifact digest before execution.
- A failed validation results in a new release candidate, never a rewritten tag.
- The first three-host deployment will use `v0.1.0-rc1` or a later RC.
- Final `v0.1.0` is published only after the Controller plus two-Edge proof passes.

## Supported product target

The current product line targets native services on **Debian GNU/Linux 13
AMD64/x86-64**, with one standalone Controller Plane and two dedicated Edge
Appliances. Controller and Edge roles must not share a host.

## Security

Never paste passwords, TOTP seeds, private keys, PFX passwords, carrier
credentials, Microsoft credentials, or enrollment grants into an issue. See
[SECURITY.md](SECURITY.md).
