# Vivolution Voice Platform v0.1.0-rc11 — immutable unified internal-pilot candidate

This immutable prerelease contains both supported deployment roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- a standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

RC11 is built from source commit `ad481774a054e99b1430cde24e6ed0facdf81c0b`. Two independent builds were byte-for-byte identical, and the public manifest, SHA-256 checksums, archive layout, and SPDX 2.3 SBOM were verified.

RC11 supersedes RC10 after live Azure qualification exposed two correctness defects. Azure rejected RC10's hyphenated Blob metadata keys with `InvalidMetadata`, and actorless system lifecycle audits could fail under the non-owner PostgreSQL runtime role. RC11 uses Azure-valid underscore metadata names, reasserts explicit platform scope only for trusted actorless/tenantless lifecycle events, and preserves tenant fail-closed behavior. It also repairs durable Edge rollback so a failed activation cannot later become the last-known-good snapshot, and adds parameterized dual-receiver failure and silence alert contracts without embedding destinations or credentials. RC10 and all earlier candidates remain immutable as evidence and must not be modified or retagged.

Automated qualification tied to this exact source commit passed:

- 143 foundation, packaging, bootstrap, and installer tests;
- 45 PostgreSQL 17 Controller tests, including signed tenant-isolation verification for platform system audits and archive receipts;
- 26 Edge protocol, rendering, durable rollback, activation, reconciliation, and service-output tests;
- native Debian 13 package installation for OpenSIPS 3.6, RTPengine, PostgreSQL, PgBouncer, Caddy, and systemd;
- production-shaped OpenSIPS rendering and parser validation;
- complete packaged Controller installation and service-recovery checks on an isolated clean systemd host;
- Azure Resource Manager validation of the immutable-storage, Controller-availability, and audit-alert-delivery deployment templates;
- strict documentation and source-secret checks, dependency vulnerability audit, Ruff definite-error checks, and Bandit medium/high security checks.

The exact RC10 predecessor passed fresh standalone Controller installation, but its immutable export failed live for the metadata defect corrected here. RC11 must therefore complete fresh-host Controller and Edge installation and the full locked-retention export/recovery/refusal qualification before promotion.

This is an internal-pilot release candidate under qualification, not a public-production or certified SBC release. Before external or paid production use, complete fresh-host Controller and Edge installation from this exact candidate, live locked-retention export including overwrite/delete refusal and receipt recovery, human-confirmed two-way audio and the full call matrix, actionable alert delivery, lifecycle/backup/restore/upgrade/rollback drills, capacity/soak and security acceptance, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

The version-pinned bootstrap verifies platform identity, exact byte size, SHA-256, archive paths and types, embedded release identity, both role payloads, and the installer entry point before it executes anything. GitHub release immutability locks the published tag and assets and creates a cryptographically verifiable release attestation.

Before installation, an operator with GitHub CLI 2.79 or later can independently verify the release and downloaded artifact:

```sh
gh release verify v0.1.0-rc11 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc11 ./vivolution-voice-platform-0.1.0-rc11-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
