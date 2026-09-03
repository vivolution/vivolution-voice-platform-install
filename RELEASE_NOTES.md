# Vivolution Voice Platform v0.1.0-rc1 — Controller Plane test candidate

This prerelease enables one role only: **Create a new standalone Controller Plane** on a fresh Debian GNU/Linux 13 AMD64 host.

Validated at source commit `a0c2f9465fe50ec01b72d14c5be936a10218ac92`:

- deterministic allow-listed release build;
- Python, shell, installer, dependency, and static-security checks;
- PostgreSQL 17 migrations and signed row-level tenant isolation;
- complete packaged installation on an isolated clean Debian 13 systemd host;
- native PostgreSQL, PgBouncer, Caddy, Chrony, Gunicorn, and systemd services;
- TLS, static/media serving, first login, forced password replacement, mandatory TOTP enrollment, restart, and recovery journeys;
- artifact manifest, SHA-256, and SPDX SBOM generation.

This is a controlled deployment release candidate. Edge SBC, SIP/RTP, Microsoft Teams Direct Routing, carrier interoperability, Controller HA, and production qualification are not included in this release.
