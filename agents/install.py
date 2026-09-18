#!/usr/bin/env python3
"""Expose dotfiles-managed skills and instructions to coding agents."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SKILLS = ROOT / "skills"
INSTRUCTIONS = ROOT / "instructions"
NAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---(?:\n|\Z)", re.DOTALL)
COMMAND_MARKER = "<!-- managed-by: personal-agent-skills -->"


@dataclass(frozen=True)
class Result:
    status: str
    target: Path
    detail: str = ""


def metadata(skill: Path) -> dict[str, str]:
    text = (skill / "SKILL.md").read_text()
    match = FRONTMATTER.match(text)
    if not match:
        raise ValueError(f"{skill}: missing YAML frontmatter")

    values: dict[str, str] = {}
    lines = match.group(1).splitlines()
    index = 0
    while index < len(lines):
        line = lines[index]
        field = re.match(r"^([a-z][a-z0-9-]*):\s*(.*)$", line)
        if not field:
            index += 1
            continue
        key, raw = field.groups()
        if raw in {"|", ">"}:
            block: list[str] = []
            index += 1
            while index < len(lines) and (not lines[index] or lines[index][0].isspace()):
                block.append(lines[index].strip())
                index += 1
            raw = ("\n" if raw == "|" else " ").join(block).strip()
            values[key] = raw
            continue
        if raw.startswith('"'):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError as exc:
                raise ValueError(f"{skill}: invalid {key!r} value") from exc
        elif len(raw) >= 2 and raw.startswith("'") and raw.endswith("'"):
            raw = raw[1:-1].replace("''", "'")
        values[key] = raw
        index += 1

    name = values.get("name", "")
    if name != skill.name or not NAME.fullmatch(name) or len(name) > 64:
        raise ValueError(f"{skill}: name must match its lowercase kebab-case directory")
    if not values.get("description"):
        raise ValueError(f"{skill}: missing description")
    return values


def digest(path: Path) -> str:
    value = hashlib.sha256()
    if path.is_file():
        value.update(path.read_bytes())
        return value.hexdigest()
    for child in sorted(item for item in path.rglob("*") if item.is_file()):
        value.update(child.relative_to(path).as_posix().encode())
        value.update(child.read_bytes())
    return value.hexdigest()


def install_link(
    source: Path,
    target: Path,
    *,
    check: bool,
    adopt_identical: bool,
    adopt_empty: bool = False,
) -> Result:
    if target.is_symlink() and target.resolve(strict=False) == source.resolve():
        return Result("ok", target)

    exists = target.exists() or target.is_symlink()
    if exists and adopt_identical and not target.is_symlink():
        if target.is_file() == source.is_file() and digest(target) == digest(source):
            if check:
                return Result("needs-adoption", target)
            if target.is_dir():
                shutil.rmtree(target)
            else:
                target.unlink()
            exists = False
    if exists and adopt_empty and target.is_file() and target.stat().st_size == 0:
        if check:
            return Result("needs-adoption", target)
        target.unlink()
        exists = False
    if exists:
        return Result("conflict", target, "unmanaged entry left untouched")
    if check:
        return Result("missing", target)

    target.parent.mkdir(parents=True, exist_ok=True)
    target.symlink_to(os.path.relpath(source, target.parent), target_is_directory=source.is_dir())
    return Result("linked", target)


def command_body(skill_id: str, description: str) -> str:
    return (
        "---\n"
        f"description: {json.dumps(description)}\n"
        "---\n\n"
        f"{COMMAND_MARKER}\n"
        f"Load the skill with the exact ID `{skill_id}` using the skill tool, then follow it in the current session. "
        "Do not substitute another skill.\n\n"
        "Additional user scope: $ARGUMENTS\n"
    )


def install_command(skill: Path, values: dict[str, str], home: Path, check: bool) -> Result | None:
    if values.get("slash", "false").lower() != "true":
        return None

    target = home / ".config/opencode/commands" / f"{skill.name}.md"
    expected = command_body(skill.name, values["description"])
    if target.is_file() and target.read_text() == expected:
        return Result("ok", target)
    if target.exists() and COMMAND_MARKER not in target.read_text(errors="ignore"):
        return Result("conflict", target, "unmanaged command left untouched")
    if check:
        return Result("stale" if target.exists() else "missing", target)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(expected)
    return Result("written", target)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="report drift without changing files")
    parser.add_argument(
        "--adopt-identical",
        action="store_true",
        help="replace an identical unmanaged skill directory with the canonical link",
    )
    parser.add_argument("--home", type=Path, default=Path.home(), help=argparse.SUPPRESS)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    home = args.home.expanduser().resolve()
    results: list[Result] = []

    skills = sorted(path.parent for path in SKILLS.glob("*/SKILL.md"))
    for skill in skills:
        try:
            values = metadata(skill)
        except ValueError as exc:
            print(f"ERROR {exc}")
            return 1
        for target_root in (home / ".agents/skills", home / ".claude/skills"):
            results.append(
                install_link(
                    skill,
                    target_root / skill.name,
                    check=args.check,
                    adopt_identical=args.adopt_identical,
                )
            )
        command = install_command(skill, values, home, args.check)
        if command:
            results.append(command)

    instruction_links = (
        (INSTRUCTIONS / "CLAUDE.md", home / ".claude/CLAUDE.md", False),
        (INSTRUCTIONS / "AGENTS.md", home / ".codex/AGENTS.md", True),
        (INSTRUCTIONS / "AGENTS.md", home / ".config/opencode/AGENTS.md", False),
    )
    for source, target, adopt_empty in instruction_links:
        results.append(
            install_link(
                source,
                target,
                check=args.check,
                adopt_identical=args.adopt_identical,
                adopt_empty=adopt_empty,
            )
        )

    for result in results:
        suffix = f" — {result.detail}" if result.detail else ""
        print(f"{result.status:14} {result.target}{suffix}")

    bad = {"conflict", "missing", "needs-adoption", "stale"}
    return 1 if any(result.status in bad for result in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
