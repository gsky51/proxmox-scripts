# proxmox-scripts

Personal Proxmox helper scripts (LXC, VM, host tooling) for my own homelab use.

Not submitted to [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE), but built on top of that project's framework.

## Attribution

The `misc/*.func` framework files are mirrored from [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) (MIT) with the URL prefix rewritten to point at this repo. All upstream copyright comments are preserved. See [LICENSE](LICENSE).

## Using a script

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gsky51/proxmox-scripts/main/ct/<slug>.sh)"
```

Run from your Proxmox host. The repo must be public so `curl` can fetch it.

## Adding a new script

Bootstrap a new LXC + install pair from the latest upstream template:

```bash
scripts/new-script.sh <slug>
# optional: specify a different upstream template
scripts/new-script.sh <slug> librechat
```

Then edit `ct/<slug>.sh` and `install/<slug>-install.sh` to replace the template's app-specific logic.

## Syncing the framework

`misc/*.func` is a URL-patched mirror of upstream. To re-sync manually:

```bash
scripts/sync-from-upstream.sh
git diff misc/   # review changes
```

A weekly GitHub Actions cron opens a PR automatically if upstream changes.

To pin to a specific upstream commit instead of `main`:

```bash
UPSTREAM_REF=<sha> scripts/sync-from-upstream.sh
```

## Catalog

A static script catalog is published to GitHub Pages at
`https://gsky51.github.io/proxmox-scripts/` and rebuilt automatically on every push.

## Upstream contribution

If you want to submit one of these scripts to `community-scripts/ProxmoxVED`:
- Change the `source <(curl …)` URL in `ct/<slug>.sh` from this repo to `community-scripts/ProxmoxVE/main`.
- `install/<slug>-install.sh` needs no changes (its URLs come from `build.func` at runtime).
- Submit to [ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) (the testing repo), not ProxmoxVE directly.
