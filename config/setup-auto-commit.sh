#!/bin/bash

# Setup script for auto-commit on macOS using launchd

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SCRIPT_PATH="$PROJECT_DIR/config/auto-commit.sh"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/com.projectchimera.autocommit.plist"

echo "=========================================="
echo "Project Chimera - Auto-Commit Setup"
echo "=========================================="
echo ""

# Make auto-commit script executable
chmod +x "$SCRIPT_PATH"
echo "✓ Made auto-commit script executable"

# Create launchd plist file
cat > "$LAUNCHD_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.projectchimera.autocommit</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>%SCRIPT_PATH%</string>
    </array>
    
    <key>StartInterval</key>
    <integer>7200</integer>
    
    <key>StandardOutPath</key>
    <string>%PROJECT_DIR%/logs/autocommit.out</string>
    
    <key>StandardErrorPath</key>
    <string>%PROJECT_DIR%/logs/autocommit.err</string>
    
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Replace placeholders in plist
sed -i '' "s|%SCRIPT_PATH%|$SCRIPT_PATH|g" "$LAUNCHD_PLIST"
sed -i '' "s|%PROJECT_DIR%|$PROJECT_DIR|g" "$LAUNCHD_PLIST"

echo "✓ Created launchd configuration at $LAUNCHD_PLIST"

# Load the launchd job
launchctl load "$LAUNCHD_PLIST"
echo "✓ Loaded auto-commit scheduler"

echo ""
echo "=========================================="
echo "Auto-Commit Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  - Interval: 2 hours (7200 seconds)"
echo "  - Script: $SCRIPT_PATH"
echo "  - Launchd Config: $LAUNCHD_PLIST"
echo "  - Logs: $PROJECT_DIR/logs/"
echo ""
echo "To check status:"
echo "  launchctl list | grep projectchimera"
echo ""
echo "To manually run auto-commit:"
echo "  bash $SCRIPT_PATH"
echo ""
echo "To disable auto-commit:"
echo "  launchctl unload $LAUNCHD_PLIST"
echo ""
