# RC13 qualification summary — 2026-09-05

Immutable prerelease `v0.1.0-rc13` passed the bounded foundation proof for one
standalone Controller Plane and two separately hosted Edge Appliances on fresh
Debian GNU/Linux 13 AMD64 VMs.

## Release identity

| Field | Value |
|---|---|
| Release | [v0.1.0-rc13](https://github.com/vivolution/vivolution-voice-platform-install/releases/tag/v0.1.0-rc13) |
| Private-source commit | `42a5c8be98b35211afdde3294f337b1c8258e2c9` |
| Public tag target | `88977fda01aef6a5139e9c992adc40fdcc173e03` |
| Artifact SHA-256 | `fa574052befbdc6bb656636ca4493f8285551e47f1256b834c36bcde337fc283` |
| Manifest SHA-256 | `27899d5e63b893fe52250dbc6a182db8a54ecdb2b9232470fa0ec9d0ef46402c` |
| SPDX SBOM SHA-256 | `a9ace82c5efb336f762dcaeaf26cc13984814d5d6ee70ae45625d3bd60d44a5f` |
| Detached signature SHA-256 | `96206484a3ae997e8f998ed2bd3f7d0aa0f5d38ac20b97e22c7fcd4f37f1bd79` |
| Signing identity | `vivolution-pilot-release` |
| Signing namespace | `vivolution-voice-platform-release` |

Two independent builds were byte-identical. The six explicit draft assets were
downloaded and compared before publication. GitHub then reported the release
immutable; release and archive attestation verification passed; and fresh
anonymous downloads of the tagged bootstrap and all assets matched the
approved local files.

## Passed foundation evidence

- The exact public `--verify-only` path passed on all three clean hosts and
  reported that it made no host change.
- The exact public one-line bootstrap installed RC13 on a standalone
  Controller and two Edges with publicly trusted certificates.
- Controller PostgreSQL, PgBouncer, and Gunicorn remained loopback-only. The
  Controller had no SIP, RTP, or SRTP process or listener.
- The initial owner credential handoff remained root-only while the duplicate
  temporary password was absent from runtime secrets after successful handoff.
- Two distinct protected-file enrollment grants were consumed without display,
  and each Edge public-key fingerprint was checked independently.
- After the first Edge approval the cluster remained enrolling. The second
  approval changed it automatically to active and created exactly one valid
  hash-chained activation audit event. No manual state edit was used.
- Both Edges activated signed generation `1`, then reconciled it idempotently.
  The exact hardened helper unit passed verification, OpenSIPS parsed its
  generated configuration, required services were enabled, and no hotfix or
  installed-release edit existed.
- Each VM passed an independent restart. A complete Controller VM outage then
  produced only bounded redacted management errors on the Edges: OpenSIPS and
  signed last-known-good state stayed active and byte-identical. Both Edges
  reconciled without changes after Controller recovery.
- Temporary qualification VM infrastructure and DNS records were deleted after
  evidence capture. No cloud application platform, managed database, analytics,
  workbook, or managed alerting service was used.

A nominal cloud size advertised as 4 GiB exposed only 3917 MiB to Debian and
was correctly refused before package mutation because the installer requires
4096 MiB guest-visible memory. Qualification used 8 GiB VMs.

## Boundaries still open

RC13 is an internal-pilot candidate, not a public-production or certified SBC
release. It does not yet provide evidence for:

- tenant-specific PBX, carrier, Microsoft Teams, PSTN, DID, RTP/SRTP, CDR, or
  human-confirmed call behavior;
- alert delivery and acknowledgement or independently administered off-host
  immutable audit retention;
- backup, isolated restore, upgrade, downgrade-compatibility, and rollback;
- production-sized capacity, soak, admission control, N-1, or active-call
  failure behavior;
- independent security, licence, privacy, and operational acceptance; or
- Microsoft, carrier, emergency-calling, number-assignment, data-retention, and
  regulatory approval.

Controller HA remains unavailable and unqualified. RC13 must not be used to
claim two-node manual failover or three-node automatic Controller failover.
