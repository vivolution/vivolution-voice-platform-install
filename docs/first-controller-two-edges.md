# First Controller and two Edges — RC13 pilot

Use this guide for a new standalone Controller and a new pair of Edge
Appliances. It uses the immutable signed `v0.1.0-rc13` release, whose
[bounded installation evidence](rc13-qualification.md) covers this topology.
RC14 changes are not included. Controller HA and production approval remain open.

## 1. Prepare three fresh VMs

| VM name | Installer selection | Pilot VM size |
|---|---|---|
| `Vivo-Voice-CP1` | 1 — Create a new standalone Controller Plane | 2 vCPU, 8 GiB RAM, 64 GB disk |
| `Vivo-Voice-Edge1` | 3 — Deploy an Edge Appliance (SBC) | 2 vCPU, 8 GiB RAM, 64 GB disk |
| `Vivo-Voice-Edge2` | 3 — Deploy an Edge Appliance (SBC) | 2 vCPU, 8 GiB RAM, 64 GB disk |

Each VM must run Debian GNU/Linux 13 AMD64/x86-64 with systemd. Use an
interactive SSH session with an account that has sudo access. Controller and
Edge roles must be on separate hosts. The 8 GiB recommendation avoids nominal
4 GiB VM sizes exposing less than the installer's required 4096 MiB.

On a minimal image, install bootstrap prerequisites first:

```sh
sudo apt-get update && sudo apt-get install -y ca-certificates curl python3 openssh-client sudo
```

If the image has only a root account and no sudo yet, run that prerequisite
command from its root console without the two `sudo` prefixes. The Debian system
Python must be 3.13. Standard Debian utilities, including `sha256sum` and
`tar`, are also required.

All database, web/API, Controller, Edge-agent and voice services run inside
these VMs. No cloud-managed database or application monitoring service is
required for this installation.

## 2. Prepare names and network access

Use your own domain and dedicated static public IPv4 addresses. These example
names are placeholders, not existing product endpoints:

| DNS A record | Destination | TTL |
|---|---|---|
| `vivo-voice-cp1.voice.example.com` | Controller public IPv4 | 60 |
| `controller.voice.example.com` | Same Controller public IPv4 | 60 |
| `vivo-voice-edge1.voice.example.com` | Edge 1 public IPv4 | 60 |
| `vivo-voice-edge2.voice.example.com` | Edge 2 public IPv4 | 60 |

The Controller's node and shared names must be **different**. Do not publish
AAAA records for these names in this candidate. Each Edge needs a separate
public IPv4. Use direct public addressing or dedicated 1:1 NAT; shared PAT is
not supported. Record each node's actual private/service interface address.
TTL 60 applies to the DNS records; it cannot remove caches of older records
before their previous TTL expires.

For the documented Let's Encrypt path:

- Allow inbound TCP 80 and 443 to the Controller.
- Allow inbound TCP 80 to **each Edge** for certificate issuance and renewal.
- Allow both Edges to reach the shared Controller name on TCP 443.
- Restrict SSH access to your administration addresses.
- Allow outbound access to the required package repositories, GitHub release
  assets, certificate services, DNS and time synchronization.

Keep Controller PostgreSQL/PgBouncer/Gunicorn ports 5432, 6432 and 8000 private.
Voice firewall rules must later match assigned tenant ports and approved peers;
do not open broad SIP/media ranges simply to complete enrollment. Review the
installer's plan for your chosen interface and NAT topology.

## 3. Install the Controller

Run this same one-line command inside each VM's SSH session. Start on
`Vivo-Voice-CP1`:

```sh
(tmp=$(mktemp) && trap 'rm -f "$tmp"' EXIT HUP INT TERM && curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' --tlsv1.2 --output "$tmp" https://raw.githubusercontent.com/vivolution/vivolution-voice-platform-install/v0.1.0-rc13/install.sh && printf '%s  %s\n' 'd0550a63256b0d099ce5e9c4d69bde0a78e6ec38cfe3289092c15f0d7dff8e8e' "$tmp" | sha256sum --check --status && sudo sh "$tmp")
```

The command downloads the complete bootstrap and verifies its pinned SHA-256
before execution. The bootstrap then downloads the exact release archive and
verifies its size, checksum and detached publisher signature before starting
the interactive installer. A GitHub account or repository token is not needed.

Choose **1 — Create a new standalone Controller Plane**. Enter the actual
interfaces, public IPv4, node name and shared name from step 2. Set the initial
Platform Owner username/email and timezone, and complete the
certificate prompts. Review the plan and type `INSTALL` only when correct.

In a second SSH session you can follow progress:

```sh
sudo tail --follow=name --retry /var/log/vivolution/installer/current.log
```

After installation, open `https://controller.YOUR-DOMAIN/` using the actual
shared name you entered. Access the temporary credential handoff privately on
the Controller at `/root/vivolution-controller-credentials.txt`. Do not paste
its contents into email, chat or an issue.

Complete the initial login in this order: temporary password, TOTP enrollment
and verification, secure recovery-code storage, then a fresh TOTP code and
replacement of the temporary password.

## 4. Create the new Edge pair and protected enrollment files

Prepare both Edge VMs and their DNS first. On the Controller, replace every
uppercase placeholder below with your actual non-secret values. `--actor`
is the Platform Owner username you created, not necessarily the email address.

```sh
sudo systemd-run --quiet --wait --pipe --collect \
  --property=WorkingDirectory=/opt/vivolution/current/controller \
  --property=EnvironmentFile=/etc/vivolution/controller/runtime.env \
  /opt/vivolution/current/controller-venv/bin/python manage.py bootstrap_edge_pair \
  --name Vivo-Voice-Edges --mode SHARED_ENHANCED \
  --edge-a-fqdn EDGE1_FQDN --edge-a-private-ip EDGE1_PRIVATE_IPV4 --edge-a-public-ip EDGE1_PUBLIC_IPV4 \
  --edge-b-fqdn EDGE2_FQDN --edge-b-private-ip EDGE2_PRIVATE_IPV4 --edge-b-public-ip EDGE2_PUBLIC_IPV4 \
  --actor PLATFORM_OWNER_USERNAME --valid-minutes 60 \
  --output-directory /root/vivolution-edge-grants
```

Run this pair-creation command **once for the new pair**. It creates both
expected identities and writes distinct grant files with mode 0600 inside a
root-owned mode-0700 directory. Only node IDs and file paths are printed.
The grants expire after 60 minutes; package installation must finish in time
for enrollment to consume them. Do not rerun this command on an enrolled pair,
because it resets the expected node identities and state. Resolve a failed or
expired enrollment before proceeding with a replacement grant.

RC13's web-admin enrollment-grant action directs operators to this protected
file workflow; it does not display usable grant tokens.

Transfer the file labelled `slot=A` to Edge 1 and `slot=B` to Edge 2 through
your authenticated SSH/SFTP secret-transfer procedure. Preserve mode 0600 and
restrict access to the intended operator. On each Edge, put its file at
`/root/vivolution-edge.grant`, owned by root, mode 0600, as a regular file with
one link. If your transfer used a protected staging file, install it and remove
only that transfer copy:

```sh
sudo install -o root -g root -m 0600 -- /PATH/TO/THIS-EDGES-PROTECTED-GRANT /root/vivolution-edge.grant
sudo unlink -- /PATH/TO/THIS-EDGES-PROTECTED-GRANT
```

Do not display a grant or put it in a command argument, environment variable,
answer file or shell history. Each Edge must receive its own file.

## 5. Install and approve each Edge

Run the command from step 3 on `Vivo-Voice-Edge1` and select **3 — Deploy an
Edge Appliance (SBC)**. Enter its actual interfaces, node FQDN and addresses.
Use the shared Controller HTTPS URL from step 3. Choose the intended
certificate mode and supply `/root/vivolution-edge.grant` when prompted for the
protected enrollment-grant file. Review the plan and confirm installation.
Repeat on Edge 2 with its separate identity and grant.

Successful enrollment consumes and removes the local grant file. A pending
approval state is expected at this point. Keep a failed enrollment's grant
protected while resolving the failure; never disclose its contents.

In the Controller's `/admin/` interface:

1. Open **Edge nodes** and select exactly one pending node.
2. Choose **Approve selected claimed nodes**.
3. Read the 64-character management-key fingerprint directly from that Edge's
   trusted installation session; the approval form does not supply it for you.
4. Enter that fingerprint, your current password and a fresh TOTP code, then
   confirm the independent comparison. The Controller checks the entered value
   against the claimed key.
5. Repeat for the other Edge.

The cluster remains enrolling after the first approval. After both approvals,
the Controller activates the pair and the Edges reconcile signed configuration.
Remove remaining protected transit and Controller grant copies once both
enrollments have succeeded, following your credential-handling procedure.

## 6. Check the result

Confirm that the shared Controller HTTPS portal is reachable with a trusted
certificate, both Edges appear active and approved, and both report the same
signed configuration generation. Check each VM again after a controlled reboot.

This installs the Controller and Edge foundation. A new deployment initially
has no tenant voice configuration. Customer creation, a PBX/SIP trunk or
Microsoft Teams configuration, phone numbers and witnessed calls are subsequent
steps. Enrollment alone does not demonstrate working calls or production
readiness. Controller 2/3 and HA remain unavailable in this pilot release.
