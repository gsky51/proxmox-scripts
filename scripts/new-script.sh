#!/usr/bin/env bash
# Bootstrap a new LXC script pair from the latest upstream template.
# This ensures your new scripts always reflect current upstream conventions
# (var_* knobs, helper-call sequences, comment header format).
#
# Usage:
#   scripts/new-script.sh <slug> [<template-slug>]
#
# Examples:
#   scripts/new-script.sh myapp               # uses 'adguard' as template
#   scripts/new-script.sh myapp librechat     # uses 'librechat' as template
#
# After running, edit the two new files:
#   ct/<slug>.sh             — set APP=, var_*, and update_script()
#   install/<slug>-install.sh — replace the template's install steps
set -euo pipefail

SLUG="${1:?usage: $0 <slug> [<template-slug>]}"
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]] \
  || { echo "ERROR: slug must contain only lowercase letters, digits, and hyphens" >&2; exit 1; }
TEMPLATE="${2:-adguard}"

DEST_USER="${DEST_USER:-gsky51}"
DEST_REPO="${DEST_REPO:-proxmox-scripts}"
DEST_REF="${DEST_REF:-main}"

UPSTREAM_PREFIX="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
DEST_PREFIX="https://raw.githubusercontent.com/${DEST_USER}/${DEST_REPO}/${DEST_REF}"
DEST_PREFIX_SED=$(printf '%s\n' "$DEST_PREFIX" | sed 's/[\\&|]/\\&/g')
UPSTREAM_PREFIX_SED=$(printf '%s\n' "$UPSTREAM_PREFIX" | sed 's/[\\&|]/\\&/g')

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CT_OUT="${REPO_ROOT}/ct/${SLUG}.sh"
INSTALL_OUT="${REPO_ROOT}/install/${SLUG}-install.sh"

[[ -e "${CT_OUT}" ]] && { echo "ERROR: ${CT_OUT} already exists" >&2; exit 1; }
[[ -e "${INSTALL_OUT}" ]] && { echo "ERROR: ${INSTALL_OUT} already exists" >&2; exit 1; }

mkdir -p "${REPO_ROOT}/ct" "${REPO_ROOT}/install"

echo "Fetching ct/${TEMPLATE}.sh from upstream"
if ! curl -fsSL "${UPSTREAM_PREFIX}/ct/${TEMPLATE}.sh" \
    | sed "s|${UPSTREAM_PREFIX_SED}|${DEST_PREFIX_SED}|g" \
    | sed "s|^APP=.*|APP=\"${SLUG^}\"|" \
    > "${CT_OUT}"; then
  echo "ERROR: failed to fetch upstream ct/${TEMPLATE}.sh" >&2
  rm -f "${CT_OUT}"
  exit 1
fi

echo "Fetching install/${TEMPLATE}-install.sh from upstream"
if ! curl -fsSL "${UPSTREAM_PREFIX}/install/${TEMPLATE}-install.sh" \
    > "${INSTALL_OUT}"; then
  echo "ERROR: failed to fetch upstream install/${TEMPLATE}-install.sh" >&2
  rm -f "${CT_OUT}" "${INSTALL_OUT}"
  exit 1
fi

chmod +x "${CT_OUT}" "${INSTALL_OUT}"

echo
echo "Created:"
echo "  ${CT_OUT}"
echo "  ${INSTALL_OUT}"
echo
echo "Next steps:"
echo "  1. Edit ct/${SLUG}.sh         — set APP=, var_* defaults, update_script()"
echo "  2. Edit install/${SLUG}-install.sh — replace ${TEMPLATE}'s install logic"
echo "  3. git add ct/${SLUG}.sh install/${SLUG}-install.sh && git commit"
