# Release channels

`stable.json` and `preview.json` are machine-readable channel records.
The preview channel points to immutable internal-pilot `v0.1.0-rc13`; stable
remains unavailable. Use the exact version-pinned command in the repository
README. Channel promotion must point to an immutable version and never discover
or execute an arbitrary latest tag.
