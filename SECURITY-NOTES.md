# Security notes

The public repository is intentionally small. Its threat model includes partial downloads, checksum substitution, malicious archive paths, symlinks and special files, oversized artifacts, stale release metadata, credential leakage, and accidental execution of an unpromoted channel.

The active release bootstrap must fail closed for every verification error and must never log secrets supplied later to the product installer.
