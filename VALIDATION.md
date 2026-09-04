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

No stable product release is promoted yet. RC13 records the exact source
commit, byte-for-byte reproducible unified artifact, detached publisher
signature, byte counts, digests, manifest, and SBOM. All nine required source
repository checks passed for that exact commit before publication approval.
RC12 remains immutable but is not qualified because its clean-host run required
operator activation fixes. RC13 requires a fresh, unmodified public one-line
Controller-plus-two-Edge rerun before internal-pilot qualification.
