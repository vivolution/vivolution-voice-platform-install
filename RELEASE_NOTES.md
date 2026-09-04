# Vivolution Voice Platform v0.1.0-rc9 — immutable unified internal-pilot candidate

This immutable prerelease contains both supported deployment roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- a standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

RC9 is built from source commit `4227d40e4c1d5f354e15fd7762dde078faef8fc9`. Two independent builds were byte-for-byte identical, and the public manifest, SHA-256 checksums, archive layout, and SPDX 2.3 SBOM were verified.

RC9 replaces RC8 after clean-host qualification exposed two additional fail-closed Edge activation defects. RC9 makes only the non-secret `/etc/vivolution` parent traversable while preserving the Edge configuration directory at `0750` and the management private key at `0600`. It also sends the authenticated inventory heartbeat when a newly approved cluster has no active desired-state revision, allowing the Controller to move the node from `APPROVED` to `ACTIVE`. RC6, RC7, and RC8 remain immutable for audit evidence and must not be deployed.

A bounded diagnostic test on the disposable qualification hosts independently matched the Edge Ed25519 public-key fingerprint, approved the node, exercised the RC9 heartbeat change atop the RC8 installation, and moved the Controller record to `ACTIVE`; the Controller audit chain remained valid. This diagnostic is not a substitute for the required fresh-host installation from the exact immutable RC9 artifact.

Automated qualification tied to this exact source commit passed:

- 134 foundation and installer tests;
- 22 Edge protocol, rendering, activation, reconciliation, and service-output tests;
- PostgreSQL 17 migrations, Controller tests, deployment checks, and signed tenant-isolation verification;
- native Debian 13 package installation for OpenSIPS 3.6, RTPengine, PostgreSQL, PgBouncer, Caddy, and systemd;
- production-shaped OpenSIPS rendering and parser validation;
- complete packaged Controller installation and service-recovery checks on an isolated clean systemd host;
- strict documentation and source-secret checks.

The existing Azure internal pilot independently operates one Controller, two Edges, and a qualification PBX, with bidirectional Teams/PBX signaling, live RTPengine control, public SIP/TLS checks, Edge failover recovery, and centralized monitoring. That estate remains independent of the operator Mac.

This is an internal-pilot release candidate under qualification, not a public-production or certified SBC release. Before external or paid production use, complete fresh-host Controller and Edge installation from this exact candidate, human-confirmed two-way audio and the full call matrix, security review, capacity/soak and recovery drills, off-host immutable audit export, alert delivery, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

The version-pinned bootstrap verifies platform identity, exact byte size, SHA-256, archive paths and types, embedded release identity, both role payloads, and the installer entry point before it executes anything. GitHub release immutability locks the published tag and assets and creates a cryptographically verifiable release attestation.

Before installation, an operator with GitHub CLI 2.79 or later can independently verify the release and downloaded artifact:

```sh
gh release verify v0.1.0-rc9 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc9 ./vivolution-voice-platform-0.1.0-rc9-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
