#!/usr/bin/env python3
"""Validate that user scripts only reference var_* knobs and helper functions
that are defined in the current misc/*.func mirror.

Fails with exit code 1 if drift is detected.
Fails with exit code 2 if misc/ is empty (sync hasn't run yet).

Add identifiers to BUILTIN to suppress false positives on common commands.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MISC = REPO / "misc"
USER_DIRS = ["ct", "install", "vm"]

DEF_VAR = re.compile(r'(?:^|\s)(var_[A-Za-z0-9_]+)\s*=', re.M)
DEF_FUNC = re.compile(r'^\s*(?:function\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\)\s*\{', re.M)
REF_VAR = re.compile(r'\b(var_[A-Za-z0-9_]+)\b')
REF_FUNC_LINE = re.compile(r'^\s*([a-z_][a-z0-9_]*)\b', re.M)

BUILTIN = {
    # bash keywords
    "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
    "case", "esac", "function", "return", "exit", "in",
    # shell builtins
    "echo", "printf", "read", "local", "export", "set", "unset", "source",
    "cd", "pwd", "true", "false", "test", "eval", "trap", "shift", "shopt",
    "declare", "let", "getopts",
    # common binaries
    "mkdir", "rm", "cp", "mv", "ln", "chmod", "chown", "cat", "grep",
    "sed", "awk", "curl", "wget", "apt", "apt-get", "systemctl", "useradd",
    "groupadd", "tee", "tr", "cut", "sort", "uniq", "head", "tail", "find",
    "xargs", "ls", "touch", "which", "command", "jq", "python3", "node",
    "npm", "git", "docker", "pct", "pveam", "lxc-attach", "bash", "sh",
    "env", "sleep", "date", "stat", "wc", "id", "uname", "hostname",
    # framework entry points (defined in misc/ but also referenced as top-level calls)
    "color", "header_info", "variables", "catch_errors", "start",
    "build_container", "description", "verb_ip6",
    # sourcing idiom
    "source",
}


def collect_defs() -> tuple[set[str], set[str]]:
    var_defs: set[str] = set()
    func_defs: set[str] = set()
    for f in MISC.glob("*.func"):
        text = f.read_text(errors="replace")
        var_defs.update(DEF_VAR.findall(text))
        func_defs.update(DEF_FUNC.findall(text))
    return var_defs, func_defs


def check_scripts(var_defs: set[str], func_defs: set[str]) -> list[str]:
    errors: list[str] = []
    for d in USER_DIRS:
        for f in sorted((REPO / d).glob("**/*.sh")):
            text = f.read_text(errors="replace")
            rel = f.relative_to(REPO)

            # var_* references
            for var in sorted(set(REF_VAR.findall(text))):
                if var not in var_defs:
                    errors.append(f"{rel}: references undefined knob '{var}'")

            # helper function calls (heuristic: bare identifier at line start)
            local_funcs = set(DEF_FUNC.findall(text))
            for line in text.splitlines():
                m = REF_FUNC_LINE.match(line)
                if not m:
                    continue
                name = m.group(1)
                if name in BUILTIN:
                    continue
                if name in func_defs:
                    continue
                if name in local_funcs:
                    continue
                # skip lines that are assignments
                stripped = line.split("#", 1)[0]
                if "=" in stripped:
                    continue
                if name.startswith("var_"):
                    continue
                errors.append(f"{rel}: calls undefined helper '{name}' (line: {line.strip()!r})")

    return errors


def main() -> int:
    if not MISC.exists() or not any(MISC.glob("*.func")):
        print(
            "ERROR: misc/*.func not found — run scripts/sync-from-upstream.sh first",
            file=sys.stderr,
        )
        return 2

    var_defs, func_defs = collect_defs()
    if not var_defs and not func_defs:
        print("ERROR: misc/*.func appears empty — sync may have failed", file=sys.stderr)
        return 2

    errors = check_scripts(var_defs, func_defs)
    if errors:
        print(f"Convention drift detected ({len(errors)} issue(s)):", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        print(
            "\nIf this is a false positive, add the identifier to BUILTIN in "
            "scripts/lint-conventions.py",
            file=sys.stderr,
        )
        return 1

    print(
        f"OK — {len(var_defs)} var_* knobs, {len(func_defs)} helpers defined in misc/; "
        "no drift in user scripts"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
