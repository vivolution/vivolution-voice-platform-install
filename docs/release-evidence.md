# Release evidence

A green repository build is source evidence only. Clean-host installation, live SIP/RTP, Microsoft Teams interoperability, carrier acceptance, capacity, failover, upgrade, restore, and regulatory approval remain separate evidence classes.

For every published release, retain:

- the exact private-source commit and successful qualification run URLs;
- the public release tag, manifest, SHA-256 file, SBOM, and build summary;
- successful `gh release verify` output for the immutable release;
- successful `gh release verify-asset` output for the downloaded product archive;
- anonymous download and version-pinned bootstrap verification results;
- separate, dated evidence for each operational acceptance class.

A GitHub release attestation proves that a tag and its assets match the immutable release record. It does not prove voice quality, interoperability, security, capacity, recovery, or regulatory acceptance; those gates must remain explicit.
