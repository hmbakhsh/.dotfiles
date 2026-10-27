When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

Use simple, plain language. Domain-specific terms are encouraged when they are the precise word, but avoid verbose jargon and buzzwords that add no meaning. Prefer the shortest word that says the thing exactly.

## Defaults

- Do the obvious next step; don't ask "want me to…?". Ask only for: spend (state cost first), irreversible/prod actions, product-meaning forks, bulk actions on a list I haven't seen.
- "Done" = you tested it (keybinds, app config, UI: trigger it yourself). Else say "untested".
- GUI steps: CLI/API/osascript first. Web: drive the agent Helium yourself (see Browser automation). Native apps / System Settings: Codex `delegate_task` (provider `codex`, latest gpt sol model from `orchestrator_capabilities`, computer use). Me only if those failed, say why.
- Style/taste correction from me → fix it and propose adding it to the matching skill or repo CLAUDE.md.
- Load `writing-style` for text others read. Plain language is for replies to me; expert docs use precise terms.

## Browser automation (Claude, Codex, any agent)

- Helium only (`/Applications/Helium.app`, 36 Labs profile). Never Google Chrome (incl. claude-in-chrome, headless Chrome), never `Helium.patched.app`.
- Showing me a URL / dev server: plain `open <url>` (Rootie routes localhost, 127.0.0.1, 0.0.0.0 to Helium 36 Labs). Never `open -a`.
- Headless screenshots: `"/Applications/Helium.app/Contents/MacOS/Helium" --headless=new --user-data-dir=/tmp/helium-headless --screenshot=OUT.png URL`. Playwright: headless bundled Chromium is fine; anything headed → `chromium.connectOverCDP('http://127.0.0.1:9333')` (agent Helium).
- Use the agent Helium only: `chrome-devtools` MCP (connects to a separate Helium on 127.0.0.1:9333, data dir `~/.helium-agent`, cookies synced from my 36 Labs profile). It can't see my own windows/tabs. Never drive Helium with computer use / screen clicks.
- Prefer new tabs over new windows. Close tabs you opened when done.
- Hit a login page? Run `~/.config/aerospace/agent-browser.sh sync` (re-copies my cookies, restarts it) and retry once. Still logged out → tell me to log in to that site in my 36 Labs profile.
- Never raise/activate Helium or switch my AeroSpace workspace.

## Shell & git

- zsh: `rm` blocked, use `trash`. Quote globs.
- Stage only files you changed (`git add <paths>`); other agents share the repo.
- Before pushing to a branch: check `gh pr view --json state`; if merged, branch fresh from `origin/main`.
- Delegate in the child's own worktree (`existing_worktree`), not the parent's cwd.

## Accounts

- Slack: 36 Labs. Work logins: Helium, 36 Labs profile. Cloudflare: h@hbak.co.
- Secrets: `2password run`, never per-command `op read`.

## Hidden skills

Many skills in `~/.claude/skills/` hide from your skill list (`disable-model-invocation: true`). If I write `/<name>`, read `~/.claude/skills/<name>/SKILL.md` before saying it doesn't exist. Run it only if I'm asking you to; if I'm just referring to it ("like /x"), read it but don't run it.
