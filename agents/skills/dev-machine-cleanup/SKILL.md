---
name: dev-machine-cleanup
description: Diagnose and safely clean a slow development machine: stranded agent processes, Docker containers and volumes, stale dev servers, orphaned Compose projects, and abandoned Git worktrees. Use whenever the user says their laptop is slow, asks what is consuming CPU/RAM/swap/disk, or wants old development environments and background processes cleaned up.
slash: true
---

# Development machine cleanup

Run a machine-wide **inventory → approval → cleanup → proof** workflow. Optimize for responsiveness first and disk second. Treat process termination, dev-database deletion, and worktree removal as separate decisions.

## 1. Establish the pressure

On macOS, capture a baseline:

```bash
ps -axo pid,ppid,%cpu,%mem,rss,etime,state,command -r | head -40
vm_stat
sysctl -n vm.swapusage
memory_pressure
df -h /
```

Aggregate related process families as well as listing individual leaders. Agent CLIs often look harmless one process at a time while dozens of sessions, MCP servers, browser helpers, and language servers consume most memory together.

Report:

- CPU leaders and sustained CPU, not just a one-sample spike
- RSS by process family
- memory compression and swap
- free disk
- zombie count and the parent processes responsible for reaping them

## 2. Inventory development processes

Find old agent sessions, dev servers, browser automation, test runners, and MCP servers. Record PID, PPID, age, state, RSS, command, and working directory where useful.

Distinguish:

- **Definite orphan:** command or working directory points to a deleted worktree; detached child has no useful parent; stopped process belongs to a dead session.
- **Likely stale:** days old, idle, duplicated, or attached to an inactive terminal. Age alone is evidence, not proof.
- **Active:** recent activity, current terminal/session ancestry, current worktree, or an expected foreground service.

Build the current agent's PID ancestry and exclude it from every proposed kill. Group process trees by their session root so approval and termination operate on whole trees rather than leaving MCP/browser children behind.

## 3. Inventory Docker and VM load

```bash
docker compose ls -a --format json
docker ps -a --format '{{json .}}'
docker stats --no-stream
docker volume ls --format '{{json .}}'
docker image ls --filter dangling=true
docker system df -v
```

Classify resources:

- **Orphaned Compose project:** every path in `ConfigFiles` is missing.
- **Partially orphaned shared project:** at least one config path is valid. Preserve it and explain the stale path.
- **Stray container:** no live Compose owner, or its project is orphaned.
- **Stopped stale stack:** source still exists, but its runtime is old and plausibly inactive. Offer a data-preserving stop separately from deletion.
- **Orphaned volume:** no container link and its Compose project/worktree is gone.
- **Preserved volume:** belongs to a stopped stack whose data the user chose to retain.

Compose profiles can make `docker compose down` leave services behind. After every teardown, query all containers by `com.docker.compose.project`; remove approved leftovers explicitly. Preserve named volumes unless the user approved deleting that stack's data.

Never use `docker system prune -a`. Prefer exact resource IDs and `docker image prune -f` for dangling images only.

## 4. Inventory worktrees

Start with the current repository and known worktree homes such as `~/.herdr/worktrees`:

```bash
git worktree list --porcelain
```

For every registered worktree capture:

- path, branch, and disk usage
- clean/dirty status
- unpushed commits when an upstream exists
- PR state via `gh`, when available
- whether the branch commit is merged into the local or remote main branch

Also find directories under known worktree homes that are not registered Git worktrees. A directory that merely sits below another repository may make `git -C` walk upward and report the parent repository; verify its own `.git` marker before calling it a worktree.

Classify conservatively:

- Clean + merged PR: finished cleanup candidate.
- Clean + closed PR: stale candidate; preserve the branch unless deletion is separately approved.
- Dirty, unpushed, open PR, or uncertain ownership: preserve and report.
- Unregistered directory with files: inspect before proposing deletion; never infer that it is disposable from its location.

Default worktree cleanup removes only the checkout and leaves its branch intact.

## 5. Ask for scoped approval

The initial request authorizes diagnosis, not destruction. Before changing anything, show exact candidates grouped into independently selectable scopes:

1. **Definite orphans** — exact containers, volumes, images, processes, and missing source paths.
2. **Finished worktrees** — path, branch, PR state, dirty/unpushed checks, disk size, and whether stack volumes will be deleted.
3. **Stop stale stacks** — containers and estimated RAM; explicitly say volumes/data are retained.
4. **Old agent sessions** — selection rule, count, approximate RSS, and assurance that the current session is excluded.
5. **Optional disk-only cleanup** — build cache or other resources that do not explain runtime slowness.

Use a multi-select confirmation when available. Do not combine a reversible stop with irreversible volume deletion under one vague option.

## 6. Execute only approved scopes

Re-check state immediately before each action. If a worktree became dirty or a resource gained an active owner, preserve it and report the change.

Order cleanup to retain the information needed for safe teardown:

1. Stop approved processes gracefully, then force only survivors the user approved.
2. Tear down approved Compose projects while their config exists.
3. Query project-labelled containers and remove approved leftovers.
4. Delete only approved volumes.
5. Remove clean approved worktree checkouts from a surviving main checkout.
6. Remove exact dangling images; leave shared images and caches alone unless separately approved.

Keep user data, branches, dirty files, unpushed commits, and unrelated resources.

## 7. Prove the result

Repeat the baseline and summarize before/after:

- running container count and Compose projects remaining
- worktree count and paths removed
- CPU and RSS leaders
- swap/memory pressure (noting that macOS may retain swap until processes exit or the machine restarts)
- Docker and filesystem space reclaimed

Name the largest remaining pressure. If the user deliberately preserved it, say so rather than implying the machine is fully clean.

## Final report

Lead with the outcome. Use one concise line per category: processes, containers/stacks, volumes/images, worktrees, disk reclaimed, and remaining bottleneck. Mention preserved suspicious resources and why they were left alone.
