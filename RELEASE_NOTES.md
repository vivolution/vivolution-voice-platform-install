# Vivolution Voice Platform v0.1.0-rc13 - corrected signed standalone pilot candidate

This immutable prerelease contains both supported roles for fresh Debian GNU/Linux 13 AMD64 hosts:

- one standalone Controller Plane; and
- an Edge Appliance enrolled to an existing Controller Plane.

Use three separate VMs for the pilot: `Vivo-Voice-CP1`, `Vivo-Voice-Edge1`, and `Vivo-Voice-Edge2`. Controllers never carry SIP, RTP, or SRTP. Controller HA installation and join remain deliberately unavailable in RC13. `Vivo-Voice-CP2` and `Vivo-Voice-CP3` are reserved for future qualification and must not be represented as supported HA.

RC13 is built from source commit `42a5c8be98b35211afdde3294f337b1c8258e2c9`. Two independent builds were byte-for-byte identical. The unified archive is 30,735,281 bytes with SHA-256 `fa574052befbdc6bb656636ca4493f8285551e47f1256b834c36bcde337fc283`. Its detached OpenSSH signature is 334 bytes with SHA-256 `96206484a3ae997e8f998ed2bd3f7d0aa0f5d38ac20b97e22c7fcd4f37f1bd79` and is bound to identity `vivolution-pilot-release` and namespace `vivolution-voice-platform-release`.

RC13 corrects defects and unsafe boundaries found during the immutable RC12 clean-host run:

- the Edge cluster transitions automatically and auditably from `ENROLLING` to `ACTIVE` only after exactly two nodes are approved, including concurrent PostgreSQL approval coverage;
- the Edge root helper retains `ProtectSystem=strict` while permitting only the systemd target-link and Debian service-enable compatibility paths required to activate verified signed state;
- after successful Controller owner creation and root-only credential handoff, the temporary administrator password is atomically removed from runtime secrets; failed bootstrap remains safely resumable;
- the web admin no longer generates or renders enrollment grants in browser, message, or session state, and records blocked attempts in the hash-chained audit trail; operators use the protected-file `bootstrap_edge_pair` workflow; and
- the capacity/soak harness fails closed on Controller hosts and requires a separate disposable `Vivo-Voice-Qual-Gen1` generator/PBX VM.

The nine source, Controller/PostgreSQL, Edge, package, clean-systemd, documentation, dependency, and secret-scan checks passed on the exact source commit before release preparation. This is source/package evidence only. RC13 still requires an unmodified public one-line clean-host rerun on one standalone Controller and two Edges before internal-pilot qualification.

Install only from the version-pinned command after the GitHub prerelease and all six explicit assets are published and independently verified:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc13/install.sh && sudo sh "$tmp")
```

This is a pilot release candidate, not a public-production or certified SBC release. Before external or paid production use, complete exact-candidate Controller and both-Edge installation, signed tenant-state activation, human-confirmed two-way audio and the full call matrix, independently administered VM-hosted immutable audit export with refusal/recovery proof, actionable alert delivery, backup/restore/upgrade/rollback drills, capacity/soak and failure testing, independent security/licence review, and applicable Microsoft, carrier, emergency-calling, and regulatory acceptance.

An operator with GitHub CLI 2.79 or later can independently verify the immutable release and a downloaded archive:

```sh
gh release verify v0.1.0-rc13 --repo vivolution/vivolution-voice-platform-install
gh release verify-asset v0.1.0-rc13 ./vivolution-voice-platform-0.1.0-rc13-amd64.tar.gz --repo vivolution/vivolution-voice-platform-install
```
