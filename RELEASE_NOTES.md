# Vivolution Voice Platform v0.1.0-rc2 — Controller Plane external test candidate

This prerelease enables one role only: **Create a new standalone Controller Plane** on a fresh Debian GNU/Linux 13 AMD64 host.

RC2 supersedes RC1 for new testing and fixes the field defects tracked in [private source issue #9](https://github.com/vivolution/vivolution-voice-platform/issues/9):

- correct service, TLS, release-tree, and Django static-file permissions under the public launcher's restrictive `umask 077`;
- automatic discovery and clear resumption of compatible interrupted installations;
- bounded pip timeouts, retries, and download-resume attempts;
- TOTP enrollment before the temporary password is replaced;
- fresh TOTP verification for bootstrap and later password changes, including interception of Django admin's native password-change route;
- immutable release-matched documentation embedded in the Controller console;
- trusted-HTTPS validation of a real Django admin static asset.

Validated at source commit `13f04ab66bba2dc5f8442d410be0c96919b56710`:

- deterministic allow-listed Controller build;
- Python, shell, installer, dependency, and static-security checks;
- PostgreSQL 17 migrations and signed row-level tenant isolation;
- complete packaged installation under `umask 077` on an isolated clean Debian 13 systemd host;
- native PostgreSQL, PgBouncer, Caddy, Chrony, Gunicorn, and systemd services;
- TLS, static/media, Docs, first-login/TOTP/password-change, restart, and recovery journeys;
- artifact manifest, SHA-256 checksums, and SPDX SBOM generation.

Use this candidate only for a fresh external Debian 13 Controller installation test. Do not upgrade or repair an RC1 host with it.

This remains a controlled Controller-only candidate. Edge SBC, SIP/RTP, Microsoft Teams Direct Routing, carrier interoperability, Controller HA, and production qualification are not included.
