# Release checklist

A release may be promoted only when all items are complete:

- [ ] Exact private-source commit selected.
- [ ] Complete automated source tests pass.
- [ ] Controller and Edge clean-host installation pass.
- [ ] OpenSIPS and RTPengine runtime validation pass.
- [ ] Release artifact is built from an explicit allowlist.
- [ ] SHA-256 digest is recorded.
- [ ] Release manifest validates.
- [ ] SBOM is generated and published.
- [ ] Bootstrap verifies size, digest, archive layout, and entry point.
- [ ] Repository release immutability is enabled before publication.
- [ ] All assets are attached to a draft and reverified before the one-way publish step.
- [ ] The exact archive has an OpenSSH detached `.sig` asset made with namespace `vivolution-voice-platform-release`; the bootstrap pins and verifies the signature size and SHA-256 and requires identity `vivolution-pilot-release`.
- [ ] Detached verification passes for the final downloaded archive and fails for a tampered archive, signature, namespace, or identity.
- [ ] GitHub release and asset attestation verification pass after publication.
- [ ] Anonymous download and verification pass.
- [ ] Version-pinned command is tested before the stable channel advances.

Published tags and artifacts are never overwritten. Release immutability applies only after publication, so every asset must be complete and verified while the release is still a draft. A failed candidate receives a new RC number.
