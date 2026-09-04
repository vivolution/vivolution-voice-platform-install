# Vivolution Voice Platform v0.1.0-rc8 — immutable unified internal-pilot candidate

This immutable prerelease contains both supported deployment roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- a standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

RC8 is built from source commit `756e0ae6c336a5c4a3a46d416d461f579f7c9750`. Two independent builds were byte-for-byte identical, and the public manifest, SHA-256 checksums, archive layout, and SPDX 2.3 SBOM were verified.

RC8 replaces RC7 after clean-host qualification exposed a fail-closed permission defect before enrollment. The bootstrap uses a restrictive umask, so RC8 explicitly normalizes only the verified, non-secret Edge release tree and fixed parent directories before the unprivileged Edge agent uses them. It also includes RC7's correction that derives the Edge private signaling address from the persisted service-interface answer. Regression coverage now exercises both contracts. RC6 and RC7 remain immutable for audit evidence and must not be deployed.

Automated qualification tied to this exact source commit passed:

- 131 foundation and installer tests;
- 21 Edge protocol, rendering, activation, and service-output tests;
- PostgreSQL 17 migrations, Controller tests, deployment checks, and signed tenant-isolation verification;
- native Debian 13 package installation for OpenSIPS 3.6, RTPengine, PostgreSQL, PgBouncer, Caddy, and systemd;
- production-shaped OpenSIPS rendering and parser validation;
- complete packaged Controller installation and service-recovery checks on an isolated clean systemd host;
- strict documentation and source-secret checks.

The existing Azure internal pilot independently operates one Controller, two Edges, and a qualification PBX, with bidirectional Teams/PBX signaling, live RTPengine control, public SIP/TLS checks, Edge failover recovery, and centralized monitoring. That estate remains independent of the operator Mac.

This is an internal-pilot release candidate, not a public-production or certified SBC release. Before external or paid production use, complete fresh-host Controller and Edge installation from this exact candidate, human-confirmed two-way audio and the full call matrix, security review, capacity/soak and recovery drills, alert delivery, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

The version-pinned bootstrap verifies platform identity, exact byte size, SHA-256, archive paths and types, embedded release identity, both role payloads, and the installer entry point before it executes anything. GitHub release immutability locks the published tag and assets and creates a cryptographically verifiable release attestation.

Before installation, an operator with GitHub CLI 2.79 or later can independently verify the release and downloaded artifact:

```sh
gh release verify v0.1.0-rc8 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc8 ./vivolution-voice-platform-0.1.0-rc8-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
