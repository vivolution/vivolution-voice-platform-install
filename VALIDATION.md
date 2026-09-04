# Validation record

The public bootstrap foundation has passed repeated automated validation.

## Completed cycles

1. ShellCheck found an unused variable; fixed and revalidated.
2. Review found a missing mandatory SBOM field; fixed and revalidated.
3. Review found an unsafe `curl | sudo sh` documentation pattern; replaced with complete-download-before-execution and revalidated.
4. Review found incomplete GitHub token detection; expanded to fine-grained token prefixes and revalidated.
5. Review found incomplete HTTPS URL validation; strengthened and revalidated.
6. ShellCheck found a test quoting warning; fixed and revalidated.
7. Final branch and post-merge `main` workflows passed.

No stable product release is promoted yet. The permanent `main/install.sh`
bootstrap remains intentionally fail-closed. RC13 records the exact source
commit, byte-for-byte reproducible unified artifact, detached publisher
signature, byte counts, digests, manifest, and SBOM. All nine required source
repository checks passed for that exact commit before publication approval.
RC12 remains immutable but is not qualified because its clean-host run required
operator activation fixes. RC13 subsequently passed a fresh, unmodified public
one-line Controller-plus-two-Edge install, automatic Edge-cluster activation,
independent VM restarts, and bounded Controller-outage last-known-good proof
without an installed-file patch. The dated
[RC13 qualification summary](docs/rc13-qualification.md) separates that
foundation evidence from the production gates that remain open.

## Distribution correction

The first RC13 preview pull request accidentally merged the active,
version-pinned bootstrap into `main`. An immediate follow-up revert restored the
permanent command to fail-closed and retained only RC13 preview metadata and
qualification documentation. No tagged file or immutable release asset was
changed. Regression tests require `main/install.sh` to contain no downloader or
dynamic execution path.
