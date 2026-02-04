#!/bin/bash

# Auto-commit script for Project Chimera
# Runs every 2 hours to commit changes if they exist

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LOG_FILE="$PROJECT_DIR/logs/auto-commit.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create logs directory if it doesn't exist
mkdir -p "$PROJECT_DIR/logs"

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Change to project directory
cd "$PROJECT_DIR" || exit 1

log_message "Starting auto-commit check..."

# Check if git is initialized
if [ ! -d .git ]; then
    log_message "ERROR: Not a git repository"
    exit 1
fi

# Check for changes
if git diff-index --quiet HEAD --; then
    log_message "No changes detected. Skipping commit."
    exit 0
fi

# Get count of changed files
CHANGED_FILES=$(git diff-index --name-only HEAD --)
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)

log_message "Changes detected in $FILE_COUNT file(s)"

# Stage all changes
git add -A

# Create commit message
COMMIT_MESSAGE="chore: auto-commit at $TIMESTAMP"

# Attempt to commit
if git commit -m "$COMMIT_MESSAGE"; then
    log_message "✓ Successfully committed changes"
    
    # Try to push if remote is configured
    if git rev-parse --git-dir > /dev/null 2>&1; then
        REMOTE=$(git remote -v | head -n 1 | awk '{print $1}')
        if [ -n "$REMOTE" ]; then
            if git push origin HEAD:$(git rev-parse --abbrev-ref HEAD) 2>/dev/null; then
                log_message "✓ Successfully pushed changes to remote"
            else
                log_message "⚠ Push skipped (no remote configured or authentication required)"
            fi
        fi
    fi
else
    log_message "ERROR: Failed to commit changes"
    exit 1
fi

log_message "Auto-commit check completed"
