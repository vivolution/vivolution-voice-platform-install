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
- [ ] Anonymous download and verification pass.
- [ ] Version-pinned command is tested before the stable channel advances.

Published tags and artifacts are never overwritten; a failed candidate receives a new RC number.
