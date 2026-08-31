# qr-codes-installer

One-command bootstrap for a fresh droplet running [qr-codes](https://github.com/RyanHouben98/qr-codes). That repo is private, so this tiny public repo exists to solve exactly one problem: getting from "blank droplet" to "cloned the private repo" without needing `git` credentials configured on the box beforehand.

## Usage

On a fresh Ubuntu droplet, as root:

```bash
curl -fsSL https://raw.githubusercontent.com/RyanHouben98/qr-codes-installer/main/install.sh | sh
```

You'll be prompted for a GitHub username and Personal Access Token to clone the private `qr-codes` repo.

**Use a fine-grained PAT scoped to just `RyanHouben98/qr-codes`, Contents: Read-only** — not a broad classic `repo`-scope token. The token ends up stored in the clone's git config on the droplet (needed for future `git pull`s via `qr-codes`'s own `update.sh`), so a narrowly-scoped token bounds what's exposed if the box is ever compromised.

## What it does

1. Prompts for a GitHub username + PAT, reading from `/dev/tty` directly — stdin is consumed by the `curl | sh` pipe itself, so a normal prompt wouldn't work.
2. Clones `RyanHouben98/qr-codes` into `/var/www/qr-codes` — as a partial, sparse checkout: only the top-level deployment files (`docker-compose.yml`, `Caddyfile`, `setup.sh`, etc.) are fetched and checked out, not the app source (`apps/api`, `apps/web`) that also lives in that repo. The droplet only ever runs pre-built images from `ghcr.io`, so it has no use for that source — this just keeps it off disk. `git pull` (via `qr-codes`'s own `update.sh`) works completely normally against a sparse checkout like this.
3. Prints what to do next — it doesn't decide for you. `qr-codes`'s own `provision.sh` (updates packages, creates a hardened non-root `deploy` user) is there if you want it, but it's an explicit next step, not something this script runs automatically. Everything after that is documented in `qr-codes`'s own README.

## Why a separate repo instead of living inside qr-codes itself

`qr-codes` is private, so nothing inside it — including a bootstrap script — can be fetched anonymously via `curl`. This repo is the minimum public surface needed to get past that one problem, and nothing else lives here.
