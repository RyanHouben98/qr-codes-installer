#!/bin/sh
#
# qr-codes installer. Clones the private qr-codes repo -- nothing more.
# What you run after that (provision.sh for a hardened non-root deploy
# user, or straight into setup.sh as whoever you are now) is your call;
# this script doesn't decide that for you. Meant to be run on a fresh
# droplet as root:
#
#   curl -fsSL <hosted-url> | sh
#
# Since stdin is consumed by the pipe above, prompts below read from
# /dev/tty directly instead of stdin -- the standard trick for interactive
# curl|sh installers (rustup's installer does the same thing).

set -eu

REPO="RyanHouben98/qr-codes"
DEST="/var/www/qr-codes"

if [ ! -e /dev/tty ]; then
  echo "No terminal available to prompt for credentials -- run this interactively." >&2
  exit 1
fi

echo "qr-codes installer"
echo "This repo is private, so cloning it needs a GitHub Personal Access Token."
echo "Recommended: a fine-grained PAT scoped to just '$REPO', Contents: Read-only --"
echo "not a broad classic 'repo'-scope token. This token stays in the clone's git"
echo "config on this box (needed for future 'git pull's), so keep its scope narrow."
echo

exec 3</dev/tty
printf "GitHub username: "
read -r GH_USER <&3
printf "GitHub PAT: "
stty -echo <&3
read -r GH_TOKEN <&3
stty echo <&3
exec 3<&-
echo

if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$DEST"
else
  sudo mkdir -p "$DEST"
  sudo chown "$(id -u):$(id -g)" "$DEST"
fi

# The droplet only ever runs pre-built images pulled from ghcr.io -- it never
# needs the app source (apps/api, apps/web) that also lives in this repo.
# A partial clone + cone-mode sparse-checkout fetches and checks out just the
# top-level deploy files (docker-compose.yml, Caddyfile, setup.sh, etc.),
# leaving apps/ and .github/ untouched. `git pull` later (via update.sh)
# still works completely normally against this.
git clone --filter=blob:none --no-checkout "https://${GH_USER}:${GH_TOKEN}@github.com/${REPO}.git" "$DEST"
unset GH_TOKEN

cd "$DEST"
git sparse-checkout init --cone
git checkout main

echo
echo "Cloned to $DEST."
echo
echo "Next, from $DEST:"
echo "  - For a hardened non-root 'deploy' user (recommended for anything that'll"
echo "    carry real traffic): ./provision.sh, then follow its own next-steps output."
echo "  - To skip that and continue as $(whoami) for now: just run ./setup.sh --"
echo "    it prompts for the Supabase connection string itself if needed."
