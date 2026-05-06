# Upstream Sync Scope

Never modify files that also exist in the upstream `community-scripts/ProxmoxVE` repo. The sync workflow periodically pulls upstream content and would overwrite local edits.

Before changing any file, verify it does not exist upstream:

```bash
gh api repos/community-scripts/ProxmoxVE/contents/<path>
```

If it exists upstream, the change is out of scope for this repo. Currently the sync writes `misc/*.func`; the principle applies to any path the sync covers.

Do not create tracking issues here for concerns about upstream-synced files — there is nothing actionable in this repo. If the concern is worth pursuing, it belongs as an issue or PR in `community-scripts/ProxmoxVE`.

Files in `.github/workflows/` are repo-local infrastructure and safe to modify.
