# Release staging input

This directory records the exact text metadata from the deterministic private-source build selected for v0.1.0-rc2. The publication workflow downloads the corresponding short-lived GitHub Actions artifact bundle, compares these records byte-for-byte, verifies all checksums and archive invariants, and publishes the five verified files under a new release tag. Existing tags and assets are never rewritten.
