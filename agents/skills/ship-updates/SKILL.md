---
name: ship-updates
description: Release, update and migration pattern for anything the user ships to other people (Mac apps, CLIs, script/config repos). Use when adding an installer, cutting a release, adding auto-update or an update command, or making a change that needs existing installs migrated.
slash: true
---

# Ship updates

Everything shipped follows one contract, so any user on any old version reaches the latest with one action or none. ClaudeSwap (`hmbakhsh/claudeswap`) is the reference build: `install.sh`, `release.sh`, `.github/workflows/release.yml`, `Updater` in `app/Switcher.swift`, `update()` in `app/Watcher.swift`.

## The contract

1. **Release = tag.** `./release.sh X.Y` tags `vX.Y`, CI builds the artifact and publishes it as the latest GitHub release, then the script bumps any package manager entry (Homebrew tap). One command; nothing is released by hand. Before publishing, CI starts the built artifact exactly as shipped (signed, packaged) and checks it runs, e.g. `App.app/Contents/MacOS/App --version`; a local or debug build passing isn't enough.
2. **Channel = latest release.** Installers and updaters fetch `releases/latest`, never `main`. Check for updates with a `HEAD` request to `https://github.com/OWNER/REPO/releases/latest` and read the version from the `/tag/vX.Y` redirect (not rate-limited, unlike the API). Compare numerically.
3. **Install = update.** One idempotent install command. Re-running it is the manual update from any version. `VERSION=X.Y` installs a specific release (rollback).
4. **Update the way it was installed.** Detect the install method (Homebrew Caskroom/Cellar, curl into a fixed path, git clone) and update through it, so the package manager's record never drifts.
5. **Updates apply themselves.** A background component checks every 6 hours and applies quietly when the user isn't using the thing; the foreground part checks on open, including the first-run screen, so a broken first run can fetch its own fix. CLIs without a background part check at most every 6 hours on run and print one line with the update command. Never swap files mid-use. Notify after: "Updated to X.Y. Nothing to do on your end."
6. **Restart once per version.** Long-running parts (launch agents, daemons) store the version they last ran as and restart when it changes.
7. **Migrations run on every start.** See below. A user who skips ten versions gets all ten migrations, in order.
8. **User data lives outside the install.** The install directory is replaced wholesale on update; config, credentials and state live in `~/Library/Application Support/<tool>/`, `~/.config/<tool>/` or `~/.local/state/<tool>/`.
9. **README carries three lines:** install, update ("automatic", plus the manual command), uninstall. Renames get a note: "Installed it as <old name>? Run the install line once."

## Migrations

Two kinds, both idempotent, both run on every start or install before anything else:

- **Converge checks** — fix drift with no history needed: compare actual state to desired and repair it. Examples: the launch agent points at the current binary path; the old-name app is gone; a required permission or file exists. Prefer these; they also heal hand-edited or half-failed installs.
- **Versioned migrations** — one-way data changes (renamed keys, new file layout). Store the last migrated version in the state dir (`migrated-version`). On start, run every migration newer than it, oldest first, recording the version after each one succeeds. A missing file means a pre-pattern install: detect its legacy footprint (old paths, old names) rather than assuming fresh.

Rules for both: back up before changing user data and move rather than delete; a failed migration stops the run, leaves the recorded version unchanged and shows the error with the log path, so the next start retries. Never drop support for migrating from an older version; old migrations stay in the code.

**Bridge** — versions shipped before the updater existed can't update themselves. The first release with the updater must also be reachable by re-running the install line; say so in the README and release notes.

## Applying it to a project

1. **Map the project.** Identify its shape (read [`SHAPES.md`](SHAPES.md) for that shape), every place it writes outside its install dir, every name or path it has used across past tags (`git log --follow`, `git tag`), and every long-running part. Done when each past release's footprint is listed.
2. **Build each contract item** that is missing, matching ClaudeSwap's files where the shape allows. Done when all nine items are present or explicitly marked not applicable with a reason.
3. **Write migrations** for every footprint difference between the oldest release and now. Done when each listed difference has a converge check or versioned migration.
4. **Run the upgrade test.** Install the oldest still-relevant release (and the previous release), add realistic user data, then update to the new build through the real update path. It passes when the result matches a fresh install of the new build and the user data survives intact. Run it again to prove the update and migrations are idempotent. Use a throwaway `$HOME` or a macOS user/VM, never the user's own setup.
5. **Release** with `./release.sh`, then confirm the live check: the previous version detects and applies the new one.
