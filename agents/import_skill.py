#!/usr/bin/env python3
"""Import a reviewed Agent Skill into the personal canonical store."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import shutil
import subprocess
import sys
from pathlib import Path

from install import ROOT, SKILLS, digest, metadata


SOURCES = ROOT / "sources.json"
BACKUPS = ROOT / ".backups"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path, help="reviewed skill directory or SKILL.md")
    parser.add_argument("--source", help="original URL, repository, package, or 'personal'")
    parser.add_argument("--replace", action="store_true", help="replace an existing personal skill after review")
    parser.add_argument("--no-install", action="store_true", help="import without refreshing agent links")
    return parser.parse_args()


def reject_symlinks(source: Path) -> None:
    links = [path for path in source.rglob("*") if path.is_symlink()]
    if links:
        names = ", ".join(str(path.relative_to(source)) for path in links[:5])
        raise ValueError(f"candidate contains symlinks; inspect and resolve them first: {names}")


def main() -> int:
    args = parse_args()
    candidate = args.path.expanduser().resolve()
    if candidate.name == "SKILL.md":
        candidate = candidate.parent
    if not (candidate / "SKILL.md").is_file():
        print(f"No SKILL.md found in {candidate}", file=sys.stderr)
        return 1

    try:
        values = metadata(candidate)
        reject_symlinks(candidate)
    except ValueError as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1

    destination = SKILLS / values["name"]
    if destination.exists() and digest(destination) == digest(candidate):
        print(f"unchanged      {destination}")
    else:
        if destination.exists() and not args.replace:
            print(f"Conflict: {destination} already exists; review the diff, then rerun with --replace", file=sys.stderr)
            return 1
        if destination.exists():
            stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
            backup = BACKUPS / stamp / destination.name
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(destination, backup)
            print(f"backed-up     {backup}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(candidate, destination, ignore=shutil.ignore_patterns(".git", "node_modules", ".DS_Store"))
        print(f"imported      {destination}")

    records = json.loads(SOURCES.read_text()) if SOURCES.exists() else {"skills": {}}
    records.setdefault("skills", {})[values["name"]] = {
        "source": args.source or str(candidate),
        "digest": digest(destination),
        "imported_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    SOURCES.write_text(json.dumps(records, indent=2, sort_keys=True) + "\n")

    if not args.no_install:
        return subprocess.run([sys.executable, str(ROOT / "install.py")], check=False).returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
