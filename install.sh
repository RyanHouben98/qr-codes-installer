#!/bin/sh
#
# qr-codes installer. Clones the private qr-codes repo and hands off to
# provision.sh. Meant to be run on a fresh droplet as root:
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

git clone "https://${GH_USER}:${GH_TOKEN}@github.com/${REPO}.git" "$DEST"
unset GH_TOKEN

cd "$DEST"

if [ "$(id -u)" -eq 0 ]; then
  echo
  echo "Cloned to $DEST. Continuing with provision.sh..."
  exec ./provision.sh
else
  echo
  echo "Cloned to $DEST. Continue per the README from here (create .env files, run setup.sh)."
fi
