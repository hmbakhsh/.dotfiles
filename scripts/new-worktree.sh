#!/usr/bin/env bash
set -e

# Script to create a new branch from dev and set up a worktree
# Usage: ./scripts/new-worktree.sh <branch-name> [--env <path>]

# Parse arguments
BRANCH_NAME=""
ENV_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --env|-e)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      if [ -z "$BRANCH_NAME" ]; then
        BRANCH_NAME="$1"
      else
        echo "Error: Unknown argument '$1'"
        echo "Usage: ./scripts/new-worktree.sh <branch-name> [--env <path>]"
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name required"
  echo "Usage: ./scripts/new-worktree.sh <branch-name> [--env <path>]"
  exit 1
fi

# Replace '/' with '-' for directory name
DIR_NAME="${BRANCH_NAME//\//-}"
WORKTREE_PATH="../${DIR_NAME}"
MAIN_WORKTREE_PATH="$(git rev-parse --show-toplevel)"

echo "Creating branch: ${BRANCH_NAME}"
echo "Worktree path: ${WORKTREE_PATH}"
echo ""

# Fetch latest changes
echo "Fetching latest changes..."
git fetch origin dev

# Create new branch from dev
echo "Creating branch '${BRANCH_NAME}' from dev..."
git branch "${BRANCH_NAME}" dev

# Create worktree
echo "Creating worktree at ${WORKTREE_PATH}..."
git worktree add "${WORKTREE_PATH}" "${BRANCH_NAME}"

# Handle environment file copying
echo ""
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

echo ""
echo "✓ Done!"
echo ""
echo "Worktree created at: ${WORKTREE_PATH}"

# Output the path for the shell function to use
echo "__WORKTREE_PATH__:${WORKTREE_PATH}"
