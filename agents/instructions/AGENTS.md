When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

Use simple, plain language. Domain-specific terms are encouraged when they are the precise word, but avoid verbose jargon and buzzwords that add no meaning. Prefer the shortest word that says the thing exactly.

## Browser automation (Claude, Codex, any agent)

- Helium only (`/Applications/Helium.app`, 36 Labs profile). Never Google Chrome, never `Helium.patched.app`.
- Use the agent Helium only: `chrome-devtools` MCP (connects to a separate Helium on 127.0.0.1:9333, data dir `~/.helium-agent`, cookies synced from my 36 Labs profile). It can't see my own windows/tabs. Never drive Helium with computer use / screen clicks.
- Prefer new tabs over new windows. Close tabs you opened when done.
- Hit a login page? Run `~/.config/aerospace/agent-browser.sh sync` (re-copies my cookies, restarts it) and retry once. Still logged out → tell me to log in to that site in my 36 Labs profile.
- Never raise/activate Helium or switch my AeroSpace workspace.
