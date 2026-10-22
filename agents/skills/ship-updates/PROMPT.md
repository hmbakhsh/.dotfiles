# Coding agent prompt

Paste into any coding agent (Claude Code, Codex, Cursor) from the project's repo:

```text
Make this project ship updates the way ClaudeSwap does. Read and follow
https://raw.githubusercontent.com/hmbakhsh/.dotfiles/main/agents/skills/ship-updates/SKILL.md
and the shape file it links (SHAPES.md, same folder). The reference
implementation is https://github.com/hmbakhsh/claudeswap.

Users on any earlier version of this project must reach the new version
with one action or none, keeping their data. Work through "Applying it to a
project" in order. Before writing code, show me: the project's shape, the
footprint of each past release (paths, names, background parts), and which
contract items are missing. Run the upgrade test in a throwaway $HOME or a
separate macOS user, never my own setup. Ask before tagging a release or
pushing.
```

With the `ship-updates` skill installed, `/ship-updates` does the same.
