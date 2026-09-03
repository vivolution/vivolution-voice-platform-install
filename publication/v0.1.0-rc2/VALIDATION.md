# v0.1.0-rc2 validation record

- Private source commit: `13f04ab66bba2dc5f8442d410be0c96919b56710`
- Deterministic Controller package build: passed.
- Dependency, migration, Controller, signed-RLS, Ruff, Bandit and pip-audit gates: passed.
- Exact packaged Controller installation on clean Debian 13 systemd under public-launcher `umask 077`: passed.
- TOTP-first enrollment, mandatory protected password changes, and recovery login journeys: passed.
- Trusted HTTPS, Django admin static asset, embedded documentation, internal listener, secret-boundary, service restart, and readiness-recovery checks: passed.
- Public bootstrap shell, metadata, checksum, archive-tamper, anonymous asset-download, and version-pinned verification gates: enforced by the publication workflow.

RC2 is ready for a fresh external Debian 13 Controller installation test once the public publication workflow completes successfully. Issue #9 remains open until that external test is qualified.

This is Controller release-candidate evidence only. Edge/SBC and live-call qualification remain outside this release.
