# Vivolution Voice Platform v0.1.0-rc10 — immutable unified internal-pilot candidate

This immutable prerelease contains both supported deployment roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- a standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

RC10 is built from source commit `8623a344785a2fe68d139afeb3fd8ec217359e88`. Two independent builds were byte-for-byte identical, and the public manifest, SHA-256 checksums, archive layout, and SPDX 2.3 SBOM were verified.

RC10 replaces RC9 by adding a fail-closed, keyless off-host immutable audit exporter for Azure Blob Storage. The exporter writes one canonical JSON object per audit event with create-only semantics, records independently verifiable PostgreSQL receipts, serializes concurrent Controller exporters, and verifies content identity, version identity, and locked retention after upload. Authentication uses only the Controller VM's managed identity; account keys, SAS tokens, client secrets, and bearer-token files are not accepted. A least-privilege Azure deployment template, operator runbook, systemd timer, alerting guidance, tenant-isolated receipt model, and read-only receipt UI are included. RC6 through RC9 remain immutable for audit evidence; RC10 is the only candidate containing this exporter.

Automated qualification tied to this exact source commit passed:

- 139 foundation, packaging, bootstrap, and installer tests;
- 40 PostgreSQL 17 Controller tests, including signed tenant-isolation verification for archive receipts;
- 22 Edge protocol, rendering, activation, reconciliation, and service-output tests;
- native Debian 13 package installation for OpenSIPS 3.6, RTPengine, PostgreSQL, PgBouncer, Caddy, and systemd;
- production-shaped OpenSIPS rendering and parser validation;
- complete packaged Controller installation and service-recovery checks on an isolated clean systemd host;
- Azure Resource Manager validation of the immutable-storage deployment template;
- strict documentation and source-secret checks, dependency vulnerability audit, Ruff definite-error checks, and Bandit medium/high security checks.

The exact RC9 predecessor passed independent clean-host Controller and Edge installation from its public immutable release. RC10 retains those installer fixes, but RC10 itself must complete fresh-host installation and live Azure immutable-retention qualification before that evidence transfers to this candidate.

This is an internal-pilot release candidate under qualification, not a public-production or certified SBC release. Before external or paid production use, complete fresh-host Controller and Edge installation from this exact candidate, live locked-retention export including overwrite/delete refusal and receipt recovery, human-confirmed two-way audio and the full call matrix, actionable alert delivery, lifecycle/backup/restore/upgrade/rollback drills, capacity/soak and security acceptance, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

The version-pinned bootstrap verifies platform identity, exact byte size, SHA-256, archive paths and types, embedded release identity, both role payloads, and the installer entry point before it executes anything. GitHub release immutability locks the published tag and assets and creates a cryptographically verifiable release attestation.

Before installation, an operator with GitHub CLI 2.79 or later can independently verify the release and downloaded artifact:

```sh
gh release verify v0.1.0-rc10 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc10 ./vivolution-voice-platform-0.1.0-rc10-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
