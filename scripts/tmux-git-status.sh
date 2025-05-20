#!/bin/bash
set -euo pipefail # Exit on error, exit on unset variables, fail pipe

# Set a robust PATH to ensure 'git' is found
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/git/bin:$PATH"

# Get the current pane's path from Tmux (this will only work when run by Tmux).
# When run directly (e.g., from your bash prompt), this variable will be the literal string "#{pane_current_path}".
# So, we need to handle that by using the current working directory ($PWD) instead.
TMUX_VAR_PANE_PATH="#{pane_current_path}"

# Determine the actual target directory for git operations
if [[ "$TMUX_VAR_PANE_PATH" == "#"{pane_current_path} ]]; then
    # Script is likely being run directly from the shell, not via Tmux's evaluation
    target_dir="$PWD"
else
    # Script is being run by Tmux, so use the pane's current path
    target_dir="$TMUX_VAR_PANE_PATH"
fi

# If target_dir is empty or does not exist, exit quietly
if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    exit 0
fi

# Change to the target directory. If it fails (e.g., directory no longer exists), exit quietly.
cd "$target_dir" || exit 0

# Check if the current directory is inside a Git repository.
# If not, exit quietly.
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    exit 0
fi

# Get current branch name. Handle detached HEAD state gracefully.
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null) # Fallback to short commit hash
fi

# Check for uncommitted changes (dirty status)
# --porcelain -unormal is a stable format for scripting
status_output=$(git status --porcelain -unormal 2>/dev/null)
dirty=""
if [[ -n "$status_output" ]]; then
    dirty="*" # Indicates modified, unstaged, etc.
fi

# Check for staged changes specifically (added to index but not committed)
staged=""
if ! git diff --cached --quiet 2>/dev/null; then
    staged="+"
fi

# Check for untracked files
untracked=""
# Use 'git ls-files' to reliably check for untracked files
if git ls-files --others --exclude-standard --directory --no-empty-directory 2>/dev/null | grep -q .; then
    untracked="!"
fi

# Output the combined status.
# The .tmux.conf handles the icon () and colors.
# This script just provides the branch name and status indicators.
echo "${branch} ${staged}${dirty}${untracked}"
