# Shapes

Per-shape details for the [`ship-updates`](SKILL.md) contract.

## Mac app (ClaudeSwap)

- **Artifact:** CI on `macos-15` runs `VERSION="${GITHUB_REF_NAME#v}" app/build.sh`, which writes the version into `CFBundleShortVersionString`, then `gh release create "$GITHUB_REF_NAME" dist/App.zip --generate-notes`.
- **Install paths:** Homebrew cask in `hmbakhsh/homebrew-tap` (`release.sh` updates `version` and `sha256` through `gh api`), plus `install.sh` that downloads `releases/latest/download/App.zip`, quits the running app, removes old-name copies, `ditto`s it into `/Applications` and opens it.
- **Detect install method:** `/opt/homebrew/Caskroom/<cask>` or `/usr/local/Caskroom/<cask>` exists → `brew update --quiet && brew upgrade --cask <cask>`; otherwise run `install.sh` (foreground) or swap the zip in quietly (background).
- **Background part:** a helper bundle inside the app (`Contents/Helpers/`) run by a LaunchAgent with `KeepAlive`. It updates only when the main app isn't running (`NSRunningApplication` by bundle id), then exits so launchd starts the new binary.
- **Restart once per version:** the main app stores the version the agent last ran as in `UserDefaults` and runs `launchctl kickstart -k gui/$UID/<label>` when it differs.
- **Converge on open:** rewrite the LaunchAgent plist when `ProgramArguments[0]` isn't the current helper path.
- **Cask:** `uninstall quit:` the bundle id; `zap` removes the LaunchAgent and logs, since background services survive upgrades.

## CLI / package (npm, PyPI, Homebrew formula, single binary)

- **Artifact:** CI on tag publishes to the registry and/or attaches binaries to the release; `release.sh` bumps the tap formula.
- **Detect install method:** the binary's resolved path (`Cellar/`, `node_modules/`, `uv/tools/`, `pipx/`) picks `brew upgrade`, `npm i -g pkg@latest`, `uv tool upgrade pkg`, or re-running `install.sh`.
- **Update:** a `<tool> update` subcommand doing the above. The 6-hourly check caches its timestamp and result in the state dir and prints to stderr, never stdout, so piped output stays clean. Skip the check when `CI` is set or stdout isn't a TTY.
- **Migrations:** run at the start of every command, before reading config.

## Script / config repo (omakase dotfiles)

- **Artifact:** the tagged source tarball (`archive/refs/tags/vX.Y.tar.gz`). A repo whose `main` is always releasable may use `main` as the channel instead; say so in the README.
- **Install:** `curl -fsSL .../install.sh | bash` clones or updates into a fixed path (`git fetch --tags && git checkout vX.Y`, or `git pull --ff-only` on a `main` channel), links configs with backups of anything replaced, and records the installed version in `~/.local/state/<tool>/version`.
- **Update:** re-running the installer, plus an `update` script or shell function; check on shell start at most every 6 hours in the background and print one line when behind.
- **Migrations:** `migrations/NNNN-name.sh`, each idempotent, run in order by the installer; converge checks are the link-and-backup step itself. Local edits in the clone block the update: stop and tell the user rather than overwrite.
