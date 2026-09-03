# Vivolution Voice Platform v0.1.0-rc1

Controller-only release candidate for a fresh Debian 13 AMD64 VM.

## Included

- Native PostgreSQL, PgBouncer, Caddy, Gunicorn/Django, and systemd services.
- Local platform administrator with mandatory initial password replacement and TOTP MFA enrollment.
- Tenant-aware Controller data model, PostgreSQL row-level isolation, branding, Edge inventory and desired-state foundations.
- ACME/Let's Encrypt or validated PEM certificate workflow for the Controller web/API endpoint.
- Durable installer ledger, explicit `INSTALL` confirmation, DNS/NAT guidance, redacted logs, and safe resume boundaries.

## Qualification

- Exact dependencies, migrations, Controller tests, signed RLS isolation, pip-audit, Ruff and Bandit passed.
- Deterministic package build passed.
- The exact packaged artifact completed clean Debian 13 systemd installation, web/MFA journey, listener/permission checks, service restart, and readiness recovery.

## Not included

- Edge Appliance/SBC installation.
- OpenSIPS/RTPengine production data plane.
- Microsoft Teams or carrier live-call qualification.
- Controller HA or production qualification.

## Identity

- Source commit: `a0c2f9465fe50ec01b72d14c5be936a10218ac92`
- Artifact SHA-256: `56adf021bc3d3badde2de7db78d27c3e1c3aa7c33f21bcbad11136cff0cc28ed`
- Artifact bytes: `111001`
- SBOM SHA-256: `0b1c1edb6edc40ae9c31e4164a521fa070821a43a31ba42909f5461ddfba0755`
