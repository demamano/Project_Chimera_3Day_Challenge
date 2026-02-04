# Auto-Commit Configuration Guide

## Overview

This project is configured with automatic commit functionality that runs every **2 hours** to save any changes to git.

## How It Works

1. **auto-commit.sh** - Main script that:
   - Checks for uncommitted changes
   - Stages all changes with `git add -A`
   - Commits with timestamp message: `chore: auto-commit at YYYY-MM-DD HH:MM:SS`
   - Logs all activity to `logs/auto-commit.log`
   - Attempts to push to remote if configured

2. **setup-auto-commit.sh** - Setup script that:
   - Configures launchd (macOS native scheduler)
   - Sets up 2-hour interval (7200 seconds)
   - Creates LaunchAgent for background execution
   - Routes logs to `logs/` directory

## Installation

### On macOS

```bash
# Run from project root
bash config/setup-auto-commit.sh
```

This will:
- Create `~/Library/LaunchAgents/com.projectchimera.autocommit.plist`
- Load the auto-commit scheduler
- Configure logs directory

## Usage

### Check Auto-Commit Status

```bash
launchctl list | grep projectchimera
```

### Manually Trigger Auto-Commit

```bash
bash config/auto-commit.sh
```

### View Auto-Commit Logs

```bash
tail -f logs/auto-commit.log
```

### Disable Auto-Commit

```bash
launchctl unload ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
```

### Re-enable Auto-Commit

```bash
launchctl load ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
```

### Completely Remove Auto-Commit

```bash
launchctl unload ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
rm ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
```

## Configuration

To change the interval, edit the plist file:

```bash
# Edit the interval (in seconds)
defaults write ~/Library/LaunchAgents/com.projectchimera.autocommit.plist StartInterval -int 3600  # 1 hour
```

Then reload:

```bash
launchctl unload ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
launchctl load ~/Library/LaunchAgents/com.projectchimera.autocommit.plist
```

## Current Configuration

| Setting | Value |
|---------|-------|
| **Interval** | 7200 seconds (2 hours) |
| **Script Path** | `config/auto-commit.sh` |
| **Log Location** | `logs/auto-commit.log` |
| **Error Log** | `logs/autocommit.err` |
| **Scheduler** | macOS launchd |

## Commit Message Format

Auto-commits use a standardized message:

```
chore: auto-commit at YYYY-MM-DD HH:MM:SS
```

This helps identify automatic commits in git history.

## Behavior

- **No Changes**: Script exits cleanly without creating a commit
- **With Changes**: Creates a commit and attempts to push
- **Errors**: Logged to `logs/auto-commit.log` for troubleshooting

## Logs

All auto-commit activity is logged to:

- `logs/auto-commit.log` - Main activity log
- `logs/autocommit.out` - Standard output
- `logs/autocommit.err` - Errors

## Troubleshooting

### Auto-commit not running

Check if launchd job is loaded:
```bash
launchctl list | grep projectchimera
```

If not listed, run setup again:
```bash
bash config/setup-auto-commit.sh
```

### Permission Denied

Ensure scripts are executable:
```bash
chmod +x config/auto-commit.sh
chmod +x config/setup-auto-commit.sh
```

### Push failures

Auto-commit will still commit locally even if push fails. Check the error log:
```bash
cat logs/autocommit.err
```

---

*Last Updated: February 4, 2026*
