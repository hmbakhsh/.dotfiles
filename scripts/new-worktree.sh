#!/usr/bin/env bash

# Script to create a new branch and set up a worktree
# Usage: nw <branch-name> [--base <branch>] [--env <path>]

# Parse arguments
BRANCH_NAME=""
BASE_BRANCH=""
ENV_FILE=""
BRANCH_CREATED=false

# Cleanup function to delete branch if script exits early
cleanup() {
  if [ "$BRANCH_CREATED" = true ] && [ -n "$BRANCH_NAME" ]; then
    echo ""
    echo "Cleaning up: deleting branch '${BRANCH_NAME}'..."
    git branch -D "${BRANCH_NAME}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case $1 in
    --base|-b)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --env|-e)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      if [ -z "$BRANCH_NAME" ]; then
        BRANCH_NAME="$1"
      else
        echo "Error: Unknown argument '$1'"
        echo "Usage: nw <branch-name> [--base <branch>] [--env <path>]"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name required"
  echo "Usage: nw <branch-name> [--base <branch>] [--env <path>]"
  exit 1
fi

# Interactive base branch selection if not specified
if [ -z "$BASE_BRANCH" ]; then
  # Detect available branches
  AVAILABLE_BRANCHES=()
  for branch in main dev master; do
    if git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
      AVAILABLE_BRANCHES+=("$branch")
    fi
  done

  if [ ${#AVAILABLE_BRANCHES[@]} -eq 0 ]; then
    echo "Error: Could not detect any base branch (main/master/dev). Use --base to specify."
    exit 1
  fi

  # Use fzf if available for nice arrow key selection
  if command -v fzf &> /dev/null; then
    BASE_BRANCH=$(printf '%s\n' "${AVAILABLE_BRANCHES[@]}" | fzf --height=~10 --prompt="Base branch: " --header="Select base branch")
    if [ -z "$BASE_BRANCH" ]; then
      echo "Cancelled."
      exit 1
    fi
  else
    # Fallback to simple numbered menu
    echo "Select base branch:"
    for i in "${!AVAILABLE_BRANCHES[@]}"; do
      echo "  $((i+1))) ${AVAILABLE_BRANCHES[$i]}"
    done
    read -p "> " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_BRANCHES[@]}" ]; then
      BASE_BRANCH="${AVAILABLE_BRANCHES[$((choice-1))]}"
    else
      echo "Invalid choice."
      exit 1
    fi
  fi
fi

# Replace '/' with '-' for directory name
DIR_NAME="${BRANCH_NAME//\//-}"
WORKTREE_PATH="../${DIR_NAME}"
MAIN_WORKTREE_PATH="$(git rev-parse --show-toplevel)"

echo ""
echo "Branch: ${BRANCH_NAME}"
echo "Base: ${BASE_BRANCH}"
echo "Path: ${WORKTREE_PATH}"
echo ""

# Handle environment file prompts BEFORE creating anything
ENV_SOURCE=""
ENV_DEST_NAME=".env.local"

if [ -n "$ENV_FILE" ]; then
  # --env flag was provided
  ENV_SOURCE=$(eval echo "$ENV_FILE")  # Expand ~ and variables
  if [ ! -f "$ENV_SOURCE" ]; then
    echo "Warning: Specified env file not found: ${ENV_SOURCE}"
    echo "Skipping env file copy."
  else
    ENV_DEST_NAME=$(basename "$ENV_SOURCE")
  fi
elif [ -f "${MAIN_WORKTREE_PATH}/.env.local" ]; then
  # No flag provided, but .env.local exists in main worktree
  read -p "Copy .env.local from main worktree? (Y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    ENV_SOURCE="${MAIN_WORKTREE_PATH}/.env.local"
  fi
else
  # No flag and no .env.local in main worktree - prompt for path
  read -p "Copy environment file? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter path to env file: " ENV_INPUT
    ENV_SOURCE=$(eval echo "$ENV_INPUT")  # Expand ~ and variables
    if [ ! -f "$ENV_SOURCE" ]; then
      echo "Warning: File not found: ${ENV_SOURCE}"
      echo "Skipping env file copy."
      ENV_SOURCE=""
    else
      ENV_DEST_NAME=$(basename "$ENV_SOURCE")
    fi
  fi
fi

# All prompts completed - now create branch and worktree
echo ""
echo "Fetching latest changes..."
git fetch origin "${BASE_BRANCH}"

# Create new branch from base
echo "Creating branch '${BRANCH_NAME}' from ${BASE_BRANCH}..."
git branch "${BRANCH_NAME}" "origin/${BASE_BRANCH}"
BRANCH_CREATED=true

# Create worktree
echo "Creating worktree at ${WORKTREE_PATH}..."
git worktree add "${WORKTREE_PATH}" "${BRANCH_NAME}"

# Copy the env file if we have a valid source
if [ -n "$ENV_SOURCE" ] && [ -f "$ENV_SOURCE" ]; then
  echo "Copying $(basename "$ENV_SOURCE") to worktree..."
  cp "$ENV_SOURCE" "${WORKTREE_PATH}/${ENV_DEST_NAME}"
  echo "✓ ${ENV_DEST_NAME} copied"
fi

# Run bun install in the new worktree
echo ""
echo "Installing dependencies with bun..."
cd "${WORKTREE_PATH}"
bun install

# Success - disable cleanup trap
BRANCH_CREATED=false

echo ""
echo "✓ Done!"
echo ""
echo "Worktree created at: ${WORKTREE_PATH}"

# Output the path for the shell function to use
echo "__WORKTREE_PATH__:${WORKTREE_PATH}"
