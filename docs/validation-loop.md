# Validation loop

Every change to this distribution repository follows the same loop:

1. Run shell syntax, behavior, ShellCheck, JSON, and secret checks.
2. Review all failures and automated review findings.
3. Fix every confirmed finding.
4. Rerun the complete checks from a clean checkout.
5. Repeat until the current revision has no known unresolved finding.

A clean repository validation does not promote a product release. Promotion additionally requires an exact private-source commit, reviewed artifact, SHA-256 digest, mandatory SBOM, release manifest, anonymous post-publication verification, and clean-host Controller/Edge qualification.
