#!/usr/bin/env python3
"""Generate json/index.json from ct/*.sh and vm/*.sh metadata.

Reads each script's header comments and var_* assignments, emits a JSON
catalog consumed by site/catalog.js. Safe to re-run; output is deterministic.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "json" / "index.json"

import os as _os
_gh_repo = _os.environ.get("GITHUB_REPOSITORY", "gsky51/proxmox-scripts").split("/", 1)
DEST_USER = _os.environ.get("DEST_USER", _gh_repo[0])
DEST_REPO = _os.environ.get("DEST_REPO", _gh_repo[1] if len(_gh_repo) > 1 else "proxmox-scripts")
DEST_REF = _os.environ.get("DEST_REF", _os.environ.get("GITHUB_REF_NAME", "main"))

VAR_RE = re.compile(r'^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)="?([^"\n]*?)"?\s*$')
APP_RE = re.compile(r'^\s*APP="?([^"\n]+?)"?\s*$')
HEADER_COMMENT_RE = re.compile(r'^#\s*(Author|License|Source):\s*(.+)$')

INTERESTING = {
    "APP",
    "var_tags",
    "var_cpu",
    "var_ram",
    "var_disk",
    "var_os",
    "var_version",
    "var_unprivileged",
    "var_install",
}

STRIP_DEFAULT_RE = re.compile(r'\$\{[^:}]+:-([^}]*)\}')


def parse_script(path: Path, kind: str) -> dict | None:
    text = path.read_text(errors="replace").splitlines()
    entry: dict = {
        "kind": kind,
        "slug": path.stem,
        "path": str(path.relative_to(REPO)),
    }
    in_header = True
    for line in text[:100]:
        if in_header:
            m = HEADER_COMMENT_RE.match(line)
            if m:
                entry[m.group(1).lower()] = m.group(2).strip()
                continue
        m = APP_RE.match(line)
        if m:
            entry["name"] = m.group(1)
            in_header = False
            continue
        m = VAR_RE.match(line)
        if m and m.group(1) in INTERESTING:
            v = m.group(2).strip()
            v = STRIP_DEFAULT_RE.sub(r"\1", v)
            entry[m.group(1)] = v

    if "name" not in entry:
        return None

    install = REPO / "install" / f"{path.stem}-install.sh"
    entry["has_installer"] = install.exists()
    entry["install_command"] = (
        f'bash -c "$(curl -fsSL https://raw.githubusercontent.com/'
        f'{DEST_USER}/{DEST_REPO}/{DEST_REF}/{entry["path"]})"'
    )
    return entry


def main() -> int:
    entries: list[dict] = []
    for p in sorted((REPO / "ct").glob("*.sh")):
        e = parse_script(p, "ct")
        if e:
            entries.append(e)
    for p in sorted((REPO / "vm").glob("*.sh")):
        e = parse_script(p, "vm")
        if e:
            entries.append(e)

    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(json.dumps({"scripts": entries}, indent=2) + "\n")
    print(f"Wrote {len(entries)} entries to {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
