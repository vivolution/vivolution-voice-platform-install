# Vivolution Voice Platform v0.1.0-rc4 — Controller Plane external test candidate

This prerelease enables one role only: **Create a new standalone Controller Plane** on a fresh Debian GNU/Linux 13 AMD64 host.

RC4 supersedes RC3 for new testing and resolves the Operations and operational-readiness findings tracked in [private source issue #21](https://github.com/vivolution/vivolution-voice-platform/issues/21):

- Operations uses the same full-width Vivolution application shell as Dashboard, Calls, Changes, and Docs;
- **Operations → Security → Change my password** provides the TOTP-protected password workflow;
- **Operations → Security → Login history** shows understandable successful and rejected authentication events, account, method, client IP, browser/device, tenant, and timestamp;
- audit events are read-only in Operations and append-only at the PostgreSQL policy layer;
- trusted proxy handling prevents a remote client from spoofing its displayed address;
- `sudo vivolution account recover EXACT_USERNAME` provides root-only break-glass recovery, invalidates sessions, resets MFA/recovery codes, and forces complete security setup;
- `sudo vivolution logs installer` follows the consolidated, redacted installer log in real time;
- `sudo vivolution status`, `diagnostics`, and `logs controller` provide supported host operations.

Validated at source commit `6a1cfa4d58e7af14fdf170dbe6c12e70a9e8f46e`:

- deterministic allow-listed Controller build;
- 33 Controller tests plus PostgreSQL 17 migrations and tenant-isolation checks;
- complete packaged installation under `umask 077` on an isolated clean Debian 13 systemd host;
- HTTPS login, MFA enrollment, Operations shell, password change, read-only login history, root recovery, forced re-enrollment, service restart, and reboot-recovery journeys;
- artifact manifest, SHA-256 checksums, and SPDX SBOM generation.

Use this candidate only for a fresh external Debian 13 Controller installation test. Do not upgrade or repair an RC1, RC2, or RC3 host with it.

This remains a controlled Controller-only candidate. Edge SBC, SIP/RTP, Microsoft Teams Direct Routing, carrier interoperability, Controller HA, and production qualification are not included.
