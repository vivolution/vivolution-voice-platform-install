# Release verification trust

RC12 and later release bootstraps require an OpenSSH detached publisher
signature in addition to the pinned artifact byte count and SHA-256 digest.
The trust policy embedded in the bootstrap is:

```text
namespace: vivolution-voice-platform-release
identity: vivolution-pilot-release
key type: ssh-ed25519
fingerprint: SHA256:fJPFvSmEO4w70DyJgJh6QLdfaob4I+OqfGI/ZB/dNqY
```

Only the public Ed25519 key is embedded in `install.sh`. The private signing key
must remain offline from this repository, GitHub Actions, release assets, and
installed hosts.

The bootstrap downloads `<archive>.sig`, verifies its pinned size and SHA-256,
then uses `ssh-keygen -Y verify` with the exact namespace and identity before it
reads or executes the archive. A signature made for another namespace or
identity is rejected.

Published releases also use GitHub release immutability and GitHub-managed
release attestations. These are independent, complementary controls.

Operators verify a published release and a downloaded asset with:

```sh
gh release verify VERSION --repo vivolution/vivolution-voice-platform-install
gh release verify-asset VERSION PATH --repo vivolution/vivolution-voice-platform-install
```

For RC12 and later, the version-pinned bootstrap performs detached-signature
verification automatically. An operator can separately reproduce verification
by creating an OpenSSH allowed-signers file containing the documented identity
and public key and running:

```sh
ssh-keygen -Y verify \
  -f allowed_signers \
  -I vivolution-pilot-release \
  -n vivolution-voice-platform-release \
  -s RELEASE_ARCHIVE.sig < RELEASE_ARCHIVE
```
