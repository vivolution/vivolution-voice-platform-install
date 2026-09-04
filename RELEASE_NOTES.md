# Vivolution Voice Platform v0.1.0-rc12 - signed standalone pilot candidate

This immutable prerelease contains both supported roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- one standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

Use three separate VMs for the pilot: `Vivo-Voice-CP1`, `Vivo-Voice-Edge1`, and `Vivo-Voice-Edge2`. Controller HA installation and join are deliberately unavailable in RC12. The names `Vivo-Voice-CP2` and `Vivo-Voice-CP3` are reserved for future qualification and must not be represented as supported HA.

RC12 is built from source commit `4a89d6b28b16fa7acd4541d4ac8d6071ab7a2c04`. Two independent builds were byte-for-byte identical. The unified archive is 30,724,599 bytes with SHA-256 `546a8a8e059d531f31ddd6eebbfee0a108af4012da4672c4928f71e4d2c25d5a`. Its detached OpenSSH signature is 334 bytes with SHA-256 `bdbe44b605b009c957e4bcc2ed5b2725d3d2ed32b7e78f146b31443dbc89d127` and is bound to identity `vivolution-pilot-release` and namespace `vivolution-voice-platform-release`.

RC12 adds:

- deterministic offline Controller and Edge Python dependency closures, exact native-package contracts, SPDX 2.3 SBOM validation, and dual dependency audits;
- mandatory detached publisher-signature verification before archive inspection or extraction;
- a hard standalone-only Controller gate in both menu and direct installer paths;
- audited atomic customer and first-administrator onboarding with display-once temporary credentials, mandatory password replacement, and MFA enrollment;
- product-specific platform and tenant role enforcement;
- a tenant-safe, read-only Teams and generic SIP setup summary;
- authenticated, replay-resistant Edge call-event delivery, signaling-grade completed call records, and bounded active-call summaries;
- VM-native health and audit visibility without Azure monitoring, database, storage, or alerting services;
- restart-safe session admission, drain, quarantine, replacement, and a deterministic SIPp capacity/soak harness; and
- an operator guide covering Microsoft Teams Direct Routing configuration and its Microsoft, carrier, emergency-calling, and regulatory boundaries.

Automated qualification tied to this exact source commit covers Foundation, Controller/PostgreSQL 17, signed row-level tenant isolation, Edge protocol and reconciliation, dependency vulnerability audits, Debian 13 native packages, packaged Controller/systemd installation, documentation, and security scans. Call accounting is intentionally classified as pilot signaling visibility, not billing-grade, SLA, media-quality, emergency-calling, or regulatory evidence.

Install only from the version-pinned command after the GitHub prerelease and all assets are published:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc12/install.sh && sudo sh "$tmp")
```

This is a pilot release candidate, not a public-production or certified SBC release. Before external or paid production use, complete clean-host Controller and both-Edge installation from this exact candidate, exact signed tenant-state activation, human-confirmed two-way audio and the full call matrix, independently administered VM-hosted immutable audit export with refusal/recovery proof, actionable alert delivery, backup/restore/upgrade/rollback drills, capacity/soak and failure testing, independent security/licence review, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

An operator with GitHub CLI 2.79 or later can independently verify the immutable release and a downloaded archive:

```sh
gh release verify v0.1.0-rc12 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc12 ./vivolution-voice-platform-0.1.0-rc12-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
