#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Accept old_user as arg or read from old_user.txt
if [ -n "$1" ]; then
    OLD_USER="$1"
elif [ -f ~/openclaw-migration-tmp/old_user.txt ]; then
    OLD_USER=$(cat ~/openclaw-migration-tmp/old_user.txt)
elif [ -f /tmp/old_user.txt ]; then
    OLD_USER=$(cat /tmp/old_user.txt)
else
    OLD_USER=$(whoami)
fi

OUTPUT=~/migration-instructions.md

cat > "$OUTPUT" << HEREDOC
# OpenClaw Migration Instructions

> Automated migration instructions for Claude Code. Please follow all steps in order and report status after each step.
> Old device username: \`${OLD_USER}\`

---

## Preparation

First, extract the migration pack to a temporary directory:

\`\`\`bash
mkdir -p ~/migration-tmp
tar xzf ~/openclaw-migration-pack.tar.gz -C ~/migration-tmp
OLD_USER="${OLD_USER}"
NEW_USER=\$(whoami)
\`\`\`

---

## Step 1: Install openclaw and mcporter

\`\`\`bash
npm install -g openclaw
npm install -g mcporter

# Verify installation
which openclaw
which mcporter
openclaw --version
\`\`\`

---

## Step 2: Restore OpenClaw config

\`\`\`bash
mkdir -p ~/.openclaw

# Restore config files (do not overwrite program files)
if [ -d ~/migration-tmp/openclaw-config ]; then
    cp -r ~/migration-tmp/openclaw-config/. ~/.openclaw/
    echo "OpenClaw config restored"
else
    echo "Warning: openclaw-config/ not found in migration pack"
fi
\`\`\`

---

## Step 3: Fix paths

If the username differs between old and new device, bulk-replace paths:

\`\`\`bash
OLD_USER="${OLD_USER}"
NEW_USER=\$(whoami)

if [ "\$OLD_USER" != "\$NEW_USER" ]; then
    echo "Username change: \$OLD_USER → \$NEW_USER, fixing paths..."

    # Fix paths in openclaw.json
    if [ -f ~/.openclaw/openclaw.json ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/.openclaw/openclaw.json
        echo "✅ openclaw.json paths fixed"
    fi

    # Fix paths in CLAUDE.md
    if [ -f ~/.openclaw/CLAUDE.md ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/.openclaw/CLAUDE.md
        echo "✅ CLAUDE.md paths fixed"
    fi

    # Fix paths in crontab backup
    if [ -f ~/migration-tmp/crontab-backup.txt ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/migration-tmp/crontab-backup.txt
        echo "✅ crontab paths fixed"
    fi
else
    echo "Username unchanged (\$NEW_USER), no path fixing needed"
fi
\`\`\`

---

## Step 4: Restore /etc/hosts

\`\`\`bash
if [ -f ~/migration-tmp/hosts-custom.txt ] && [ -s ~/migration-tmp/hosts-custom.txt ]; then
    # Avoid duplicate entries
    while IFS= read -r line; do
        [[ "\$line" =~ ^#.*$ || -z "\$line" ]] && continue
        if ! grep -qF "\$line" /etc/hosts; then
            echo "\$line" | sudo tee -a /etc/hosts > /dev/null
        fi
    done < ~/migration-tmp/hosts-custom.txt
    echo "✅ /etc/hosts custom entries restored"
else
    echo "⚠️  hosts-custom.txt is empty or missing, skipping"
fi
\`\`\`

---

## Step 5: Restore crontab

\`\`\`bash
if [ -f ~/migration-tmp/crontab-backup.txt ] && grep -qv '^#' ~/migration-tmp/crontab-backup.txt 2>/dev/null; then
    crontab ~/migration-tmp/crontab-backup.txt
    echo "✅ crontab restored"
    crontab -l
else
    echo "⚠️  crontab backup is empty, skipping"
fi
\`\`\`

---

## Step 6: Install proxychains4

\`\`\`bash
sudo apt-get install -y proxychains4

# Restore proxychains config from migration pack if available
if [ -f ~/migration-tmp/openclaw-config/proxychains4.conf ]; then
    sudo cp ~/migration-tmp/openclaw-config/proxychains4.conf /etc/proxychains4.conf
    echo "✅ proxychains4.conf restored"
else
    echo "ℹ️  proxychains4.conf not found, using default config"
fi
\`\`\`

---

## Step 7: Check Claude Code nvm wrapper

\`\`\`bash
CLAUDE_BIN=~/.npm-global/bin/claude

# Check if it's an nvm wrapper (should contain nvm-related content)
if [ -f "\$CLAUDE_BIN" ]; then
    if grep -q 'nvm' "\$CLAUDE_BIN" 2>/dev/null; then
        echo "✅ Claude Code is already an nvm wrapper"
    else
        echo "⚠️  Claude Code is not an nvm wrapper, rebuilding..."
        CLAUDE_ACTUAL=\$(find ~/.nvm -name 'claude' -type f 2>/dev/null | head -1)
        if [ -n "\$CLAUDE_ACTUAL" ]; then
            cat > "\$CLAUDE_BIN" << 'WRAPPER'
#!/bin/bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && source "\$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true
exec "\$(dirname "\$(readlink -f "\$0")")/../../lib/node_modules/@anthropic-ai/claude-code/cli.js" "\$@"
WRAPPER
            chmod +x "\$CLAUDE_BIN"
            echo "✅ nvm wrapper rebuilt"
        else
            echo "ℹ️  claude binary not found, skipping wrapper rebuild"
        fi
    fi
else
    echo "⚠️  \$CLAUDE_BIN not found"
fi
\`\`\`

---

## Step 8: Start OpenClaw Gateway

\`\`\`bash
# Start
openclaw gateway start

# Wait for startup
sleep 3

# Configure systemd autostart
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway 2>/dev/null || true
systemctl --user start openclaw-gateway 2>/dev/null || true

# Prevent service from being killed after SSH logout
sudo loginctl enable-linger \$USER

echo "✅ OpenClaw Gateway started"
openclaw gateway status
\`\`\`

---

## Step 9: Restore Dashboard (optional)

\`\`\`bash
if [ -d ~/migration-tmp/dashboard ]; then
    echo "Dashboard data found, restoring..."
    cp -r ~/migration-tmp/dashboard ~/openclaw-dashboard

    # Install Python dependencies
    if [ -f ~/openclaw-dashboard/backend/requirements.txt ]; then
        pip3 install -r ~/openclaw-dashboard/backend/requirements.txt
    fi

    echo "✅ Dashboard restored to ~/openclaw-dashboard/"
    echo "ℹ️  Please manually configure a systemd service to auto-start the Dashboard"
else
    echo "ℹ️  No Dashboard in migration pack, skipping"
fi
\`\`\`

---

## Step 10: Check logs for channel connectivity

\`\`\`bash
echo "=== Last 50 lines of OpenClaw logs ==="
journalctl --user -u openclaw-gateway --no-pager -n 50 2>/dev/null || \
    openclaw gateway logs 2>/dev/null || \
    echo "Unable to retrieve logs, please check manually"

# Check for key indicators
echo ""
echo "=== Connection status check ==="
journalctl --user -u openclaw-gateway --no-pager -n 200 2>/dev/null | grep -Ei 'discord|feishu|connected|error|failed' | tail -20 || true
\`\`\`

---

## Step 11: Clean up migration files

\`\`\`bash
echo "Cleaning up sensitive migration files..."
rm -rf ~/migration-tmp
rm -f ~/openclaw-migration-pack.tar.gz
rm -f ~/setup.sh
echo "✅ Migration temp files cleaned up"
echo "ℹ️  migration-instructions.md kept for reference"
\`\`\`

---

## Post-completion report

After all steps are complete, please report:
1. OpenClaw running status (\`openclaw gateway status\`)
2. systemd service status (\`systemctl --user status openclaw-gateway\`)
3. Whether logs show successful Discord/Feishu connection
4. Any steps that failed or require manual user intervention

For any failed steps, provide detailed error messages and recommended solutions.
HEREDOC

echo -e "${GREEN}✅ migration-instructions.md generated: $OUTPUT${NC}"
