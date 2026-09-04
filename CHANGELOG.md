# Changelog

## 0.1.0-rc13

- Corrected automatic two-node Edge-cluster activation and added concurrent PostgreSQL coverage.
- Corrected the hardened Edge helper's narrowly scoped service-enable write paths.
- Removed the temporary Controller owner password from runtime secrets after successful protected handoff.
- Disabled raw web-admin enrollment-grant issuance in favor of the audited protected-file workflow.
- Enforced the Controller management-only boundary in the capacity/soak harness.
- Preserved RC12 as immutable failed-qualification evidence and reset exact-candidate gates for RC13.

## 0.1.0-rc12

- Added mandatory OpenSSH detached publisher-signature verification for RC12
  artifacts, pinned to a release namespace, publisher identity, public key,
  signature size, and signature SHA-256.
- Established the fail-closed public installer channel.
- Added stable and preview channel metadata.
- Added mandatory release-manifest and SBOM validation.
- Added repeated shell, behavior, JSON, secret, and documentation validation.
- Kept host-changing installation disabled until an exact release candidate is promoted.
- Published one unified offline Controller and Edge artifact for the standalone
  three-VM pilot, with customer onboarding, product RBAC, safe routing setup
  values, VM-native health, and signaling-grade call visibility.
