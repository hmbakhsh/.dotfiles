#!/usr/bin/env zsh

# Git Worktree helper - creates a new branch + worktree and cd's into it
# Usage: gwt <branch-name> [--base <branch>] [--env <path>]

unalias gwt 2>/dev/null
gwt() {
  local branch_name="" base_branch="" env_file=""
  local branch_created=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --base|-b) base_branch="$2"; shift 2 ;;
      --env|-e)  env_file="$2"; shift 2 ;;
      *)
        if [[ -z "$branch_name" ]]; then
          branch_name="$1"
        else
          echo "Error: Unknown argument '$1'"
          echo "Usage: gwt <branch-name> [--base <branch>] [--env <path>]"
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$branch_name" ]]; then
    echo "Error: Branch name required"
    echo "Usage: gwt <branch-name> [--base <branch>] [--env <path>]"
    return 1
  fi

  # Auto-detect default branch if not specified
  if [[ -z "$base_branch" ]]; then
    # Try local ref first (fast, no network)
    base_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')

    # Fall back to GitHub CLI
    if [[ -z "$base_branch" ]] && command -v gh &>/dev/null; then
      base_branch=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
    fi

    if [[ -z "$base_branch" ]]; then
      echo "Error: Could not detect default branch. Use --base to specify."
      return 1
    fi
  fi

  local dir_name="${branch_name//\//-}"
  local worktree_path="../${dir_name}"
  local main_worktree_path="$(git rev-parse --show-toplevel)"

  echo ""
  echo "Branch: ${branch_name}"
  echo "Base: ${base_branch}"
  echo "Path: ${worktree_path}"
  echo ""

  # Handle environment file prompts BEFORE creating anything
  local env_source="" env_dest_name=".env.local"

  if [[ -n "$env_file" ]]; then
    env_source="${~env_file}"
    if [[ ! -f "$env_source" ]]; then
      echo "Warning: Specified env file not found: ${env_source}"
      echo "Skipping env file copy."
      env_source=""
    else
      env_dest_name=$(basename "$env_source")
    fi
  elif [[ -f "${main_worktree_path}/.env.local" ]]; then
    read -k 1 "reply?Copy .env.local from main worktree? (Y/n): "
    echo
    if [[ "$reply" =~ ^[Yy]$ ]] || [[ -z "$reply" ]]; then
      env_source="${main_worktree_path}/.env.local"
    fi
  else
    read -k 1 "reply?Copy environment file? (y/N): "
    echo
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      read "env_input?Enter path to env file: "
      env_source="${~env_input}"
      if [[ ! -f "$env_source" ]]; then
        echo "Warning: File not found: ${env_source}"
        echo "Skipping env file copy."
        env_source=""
      else
        env_dest_name=$(basename "$env_source")
      fi
    fi
  fi

  # All prompts completed - now create branch and worktree
  echo ""
  echo "Fetching latest changes..."
  git fetch origin "${base_branch}" || return 1

  echo "Creating branch '${branch_name}' from ${base_branch}..."
  git branch "${branch_name}" "origin/${base_branch}" || return 1
  branch_created=true

  echo "Creating worktree at ${worktree_path}..."
  if ! git worktree add "${worktree_path}" "${branch_name}"; then
    echo "Cleaning up: deleting branch '${branch_name}'..."
    git branch -D "${branch_name}" 2>/dev/null
    return 1
  fi

  # Copy env file if we have a valid source
  if [[ -n "$env_source" ]] && [[ -f "$env_source" ]]; then
    echo "Copying $(basename "$env_source") to worktree..."
    cp "$env_source" "${worktree_path}/${env_dest_name}"
    echo "Done: ${env_dest_name} copied"
  fi

  # Install dependencies
  echo ""
  echo "Installing dependencies with bun..."
  (cd "${worktree_path}" && bun install)

  echo ""
  echo "Done!"
  echo ""

  cd "${worktree_path}" && ls
}

# Remove a git worktree and its branch
# Usage: gwt-rm [branch-name]  (uses fzf picker if no arg given)

gwt-rm() {
  local main_worktree="$(git worktree list --porcelain | head -1 | awk '{print $2}')"

  # List worktrees excluding the main one
  local worktrees=()
  local branches=()
  while IFS= read -r line; do
    local wt_path=$(echo "$line" | awk '{print $1}')
    local wt_branch=$(echo "$line" | awk '{print $3}' | sed 's/\[//;s/\]//')
    [[ "$wt_path" == "$main_worktree" ]] && continue
    worktrees+=("$wt_path")
    branches+=("$wt_branch")
  done < <(git worktree list)

  if [[ ${#worktrees[@]} -eq 0 ]]; then
    echo "No worktrees to remove."
    return 0
  fi

  local selected_idx=""

  if [[ -n "$1" ]]; then
    # Match by branch name
    for i in {1..${#branches[@]}}; do
      if [[ "${branches[$i]}" == "$1" ]]; then
        selected_idx=$i
        break
      fi
    done
    if [[ -z "$selected_idx" ]]; then
      echo "Error: No worktree found for branch '$1'"
      return 1
    fi
  else
    # fzf picker
    local display=()
    for i in {1..${#worktrees[@]}}; do
      display+=("${branches[$i]}  ${worktrees[$i]}")
    done

    local selection=$(printf '%s\n' "${display[@]}" | fzf --height=~10 --prompt="Remove worktree: " --header="Select worktree to remove")
    [[ -z "$selection" ]] && echo "Cancelled." && return 0

    local selected_branch=$(echo "$selection" | awk '{print $1}')
    for i in {1..${#branches[@]}}; do
      if [[ "${branches[$i]}" == "$selected_branch" ]]; then
        selected_idx=$i
        break
      fi
    done
  fi

  local wt_path="${worktrees[$selected_idx]}"
  local wt_branch="${branches[$selected_idx]}"

  echo ""
  echo "Removing worktree: ${wt_path}"
  echo "Deleting branch:   ${wt_branch}"
  echo ""

  # If we're inside the worktree being removed, cd to main first
  if [[ "${PWD:A}" == "${wt_path:A}"* ]]; then
    cd "$main_worktree"
  fi

  git worktree remove "$wt_path" --force && \
    git branch -D "$wt_branch" 2>/dev/null

  echo "Done!"
}
