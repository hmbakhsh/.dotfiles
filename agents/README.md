# Personal agent configuration

Personally authored or deliberately imported skills live in `skills/`. Run:

```bash
python3 ~/.dotfiles/agents/install.py
python3 ~/.dotfiles/agents/install.py --check
```

The installer creates per-skill links in `~/.agents/skills` and `~/.claude/skills`. Codex and OpenCode read `~/.agents/skills` natively; Claude Code reads its compatibility links. Skills marked `slash: true` also get an OpenCode command wrapper.

Import a reviewed skill without allowing third-party installers to own the live paths:

```bash
python3 ~/.dotfiles/agents/import_skill.py /path/to/skill --source owner/repository
```

Global instructions are also canonical here. `CLAUDE.md` is Claude-specific; `AGENTS.md` is shared by Codex and OpenCode. These instruction files do not use skill frontmatter.
