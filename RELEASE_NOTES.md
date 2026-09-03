# Vivolution Voice Platform v0.1.0-rc3 — Controller Plane external test candidate

This prerelease enables one role only: **Create a new standalone Controller Plane** on a fresh Debian GNU/Linux 13 AMD64 host.

RC3 supersedes RC2 for new testing. It retains all RC2 installer, permissions, recovery, MFA, documentation, and HTTPS hardening, and fixes the external UI-consistency finding tracked in [private source issue #12](https://github.com/vivolution/vivolution-voice-platform/issues/12):

- Operations now uses the same Vivolution product identity, release information, primary navigation, Sign out control, light palette, content width, cards, forms, responsive layout, and footer as Dashboard, Calls, Changes, Docs, and Password;
- Django model administration, permissions, actions, breadcrumbs, and CSRF protections remain intact;
- the separate Django dark-mode control and alternate admin logout path are removed;
- Django admin's password shortcut continues to use the TOTP-protected product workflow;
- the clean Debian 13/systemd journey verifies the unified Operations HTML and exact theme asset through trusted HTTPS.

Validated at source commit `ecff3fe017ed30611ffbc7e45a3f24c5aa1de6b9`:

- deterministic allow-listed Controller build;
- Python, shell, installer, dependency, and static-security checks;
- PostgreSQL 17 migrations, Controller tests, and signed row-level tenant isolation;
- complete packaged installation under `umask 077` on an isolated clean Debian 13 systemd host;
- native PostgreSQL, PgBouncer, Caddy, Chrony, Gunicorn, and systemd services;
- TLS, static/media, embedded Docs, unified Operations, first-login/TOTP/password-change, restart, and recovery journeys;
- artifact manifest, SHA-256 checksums, and SPDX SBOM generation.

Use this candidate only for a fresh external Debian 13 Controller installation test. Do not upgrade or repair an RC1 or RC2 host with it.

This remains a controlled Controller-only candidate. Edge SBC, SIP/RTP, Microsoft Teams Direct Routing, carrier interoperability, Controller HA, and production qualification are not included.
