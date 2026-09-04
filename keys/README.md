# Release verification trust

Published releases use GitHub release immutability and GitHub-managed release attestations. Verification is identity-bound to this public repository, so the release process does not require a long-lived Vivolution signing key in CI or in this repository.

Operators verify a published release and a downloaded asset with:

```sh
gh release verify VERSION --repo vivolution/vivolution-voice-platform-install
gh release verify-asset VERSION PATH --repo vivolution/vivolution-voice-platform-install
```

If an independent offline signing key is introduced later, only its public verification key may be stored here. Private signing keys must never be committed to any repository.
