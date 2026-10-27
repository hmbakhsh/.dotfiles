When reporting information to me, be extremely concise and sacrifice grammar for the sake of concision.

Use simple, plain language. Domain-specific terms are encouraged when they are the precise word, but avoid verbose jargon and buzzwords that add no meaning. Prefer the shortest word that says the thing exactly.

## Browser automation (Claude, Codex, any agent)

- Helium only (`/Applications/Helium.app`, 36 Labs profile). Never Google Chrome (incl. claude-in-chrome, headless Chrome), never `Helium.patched.app`.
- Showing me a URL / dev server: plain `open <url>` (Rootie routes localhost, 127.0.0.1, 0.0.0.0 to Helium 36 Labs). Never `open -a`.
- Headless screenshots: `"/Applications/Helium.app/Contents/MacOS/Helium" --headless=new --user-data-dir=/tmp/helium-headless --screenshot=OUT.png URL`. Playwright: headless bundled Chromium is fine; anything headed → `chromium.connectOverCDP('http://127.0.0.1:9333')` (agent Helium).
- Use the agent Helium only: `chrome-devtools` MCP (connects to a separate Helium on 127.0.0.1:9333, data dir `~/.helium-agent`, cookies synced from my 36 Labs profile). It can't see my own windows/tabs. Never drive Helium with computer use / screen clicks.
- Prefer new tabs over new windows. Close tabs you opened when done.
- Hit a login page? Run `~/.config/aerospace/agent-browser.sh sync` (re-copies my cookies, restarts it) and retry once. Still logged out → tell me to log in to that site in my 36 Labs profile.
- Never raise/activate Helium or switch my AeroSpace workspace.
