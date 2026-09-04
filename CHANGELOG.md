# Changelog

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
