# Release staging input

The deterministic Controller archive and SPDX SBOM are stored here as ordered base64 chunks because the repository connector publishes UTF-8 files only. The release workflow concatenates the chunks in lexical order, decodes them, verifies the exact byte counts and SHA-256 values recorded in the manifest, and uploads the reconstructed files as immutable GitHub Release assets.
