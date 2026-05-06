#!/usr/bin/env bash
# Mirror community-scripts/ProxmoxVE misc/*.func into this repo with the
# URL prefix rewritten to point at this fork. Idempotent — safe to re-run.
#
# Usage:
#   scripts/sync-from-upstream.sh
#
# Env overrides:
#   UPSTREAM_REF=main   (default) — pin to a commit SHA for stability
#   DEST_USER, DEST_REPO, DEST_REF — override destination coordinates
set -euo pipefail

UPSTREAM_USER="community-scripts"
UPSTREAM_REPO="ProxmoxVE"
UPSTREAM_REF="${UPSTREAM_REF:-main}"

DEST_USER="${DEST_USER:-gsky51}"
DEST_REPO="${DEST_REPO:-proxmox-scripts}"
DEST_REF="${DEST_REF:-main}"

UPSTREAM_PREFIX="https://raw.githubusercontent.com/${UPSTREAM_USER}/${UPSTREAM_REPO}/${UPSTREAM_REF}"
DEST_PREFIX="https://raw.githubusercontent.com/${DEST_USER}/${DEST_REPO}/${DEST_REF}"

FUNC_FILES=(
  build.func
  install.func
  core.func
  tools.func
  alpine-install.func
  alpine-tools.func
  vm-core.func
  api.func
  error_handler.func
  cloud-init.func
)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${REPO_ROOT}/misc"
mkdir -p "${DEST_DIR}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

echo "Syncing misc/*.func"
echo "  from: ${UPSTREAM_PREFIX}"
echo "  to:   ${DEST_PREFIX}"
echo

for f in "${FUNC_FILES[@]}"; do
  printf "  %-30s" "${f}"
  if ! curl -fsSL --retry 3 --retry-delay 2 \
      "${UPSTREAM_PREFIX}/misc/${f}" -o "${TMPDIR}/${f}" 2>/dev/null; then
    echo "FAILED (curl error)" >&2
    exit 1
  fi
  if [[ ! -s "${TMPDIR}/${f}" ]]; then
    echo "FAILED (empty response)" >&2
    exit 1
  fi
  # Rewrite any raw.githubusercontent.com URL pointing at the upstream repo,
  # regardless of which ref (branch, tag, or SHA) it contains. This makes
  # UPSTREAM_REF pinning reliable even when synced files contain hardcoded /main/.
  DEST_PREFIX_SED=$(printf '%s\n' "$DEST_PREFIX" | sed 's/[\\&|]/\\&/g')
  sed -E "s|https://raw\.githubusercontent\.com/${UPSTREAM_USER}/${UPSTREAM_REPO}/[^/]+|${DEST_PREFIX_SED}|g" \
    "${TMPDIR}/${f}" > "${DEST_DIR}/${f}"

  if grep -qE "raw\.githubusercontent\.com/${UPSTREAM_USER}/${UPSTREAM_REPO}/" \
      "${DEST_DIR}/${f}" 2>/dev/null; then
    echo "WARNING (upstream URL survived sed — review manually)" >&2
  else
    echo "ok"
  fi
done

echo
echo "Done. To review changes: git -C \"${REPO_ROOT}\" diff misc/"
