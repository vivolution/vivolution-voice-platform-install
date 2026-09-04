# Vivolution Voice Platform v0.1.0-rc5 — unified internal-pilot candidate

This immutable prerelease contains both supported deployment roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- a standalone Controller Plane;
- an Edge Appliance enrolled to an existing Controller Plane.

RC5 is built from source commit `921bdf20be756bc12c345e84eb2bca818f7bcab8`. Two independent builds were byte-for-byte identical, and the public manifest, SHA-256 checksums, archive layout, and SPDX 2.3 SBOM were verified.

Automated qualification tied to this exact source commit passed:

- 131 foundation and installer tests;
- 21 Edge protocol, rendering, activation, and service-output tests;
- PostgreSQL 17 migrations, Controller tests, deployment checks, and signed tenant-isolation verification;
- native Debian 13 package installation for OpenSIPS 3.6, RTPengine, PostgreSQL, PgBouncer, Caddy, and systemd;
- production-shaped OpenSIPS rendering and parser validation;
- complete packaged Controller installation and service-recovery checks on an isolated clean systemd host;
- strict documentation and source-secret checks.

The existing Azure internal pilot independently operates one Controller, two Edges, and a qualification PBX, with bidirectional Teams/PBX signaling, live RTPengine control, public SIP/TLS checks, Edge failover recovery, and centralized monitoring. That estate remains independent of the operator Mac.

This is an internal-pilot release candidate, not a public-production or certified SBC release. Before external or paid production use, complete fresh-host Edge installation from this exact candidate, human-confirmed two-way audio and the full call matrix, security review, capacity/soak and recovery drills, alert delivery, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

The version-pinned bootstrap verifies platform identity, exact byte size, SHA-256, archive paths and types, embedded release identity, both role payloads, and the installer entry point before it executes anything.
