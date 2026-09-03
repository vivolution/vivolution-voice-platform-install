# Vivolution Voice Platform Installer

Public, auditable release channel for **Vivolution Voice Platform**, a product of
**Vivolution Technologies LLC**.

The complete product source remains private. This repository contains only the
small bootstrap, public release metadata, checksums/signatures, SBOMs, release
notes, and approved versioned release assets.

## Permanent command

```sh
curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/main/install.sh | sudo sh
```

**No release is promoted yet.** The command currently exits safely without
downloading or changing the host. It becomes active only after an exact release
candidate has passed automated validation and its artifact, digest, manifest,
and SBOM have been published.

Check the channel without installing:

```sh
curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/main/install.sh | sudo sh -s -- --status
```

## Release policy

- `main/install.sh` points only to the latest explicitly promoted release.
- Version-pinned paths remain available for reproducibility.
- Published tags and release assets are never replaced.
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
