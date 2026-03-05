#!/bin/bash
# NOTE: Intentionally NOT using set -e here.
# Individual step failures are tracked via FAILED_STEPS array
# and reported in the final summary, rather than aborting early.

# deploy.sh - OpenClaw deployment on new device
# Called by agent via: ssh USER@HOST 'bash ~/deploy.sh [OLD_USER]'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Source nvm + npm-global (setup.sh already installed them, but non-login SSH shells dont load .bashrc)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
export PATH="$HOME/.npm-global/bin:$PATH"

# Check if sudo is available without password (non-interactive SSH)
SUDO_OK=false
if sudo -n true 2>/dev/null; then
    SUDO_OK=true
fi

TOTAL=12
PROGRESS_FILE="/tmp/openclaw-deploy-progress.txt"
MIGRATION_TMP=~/migration-tmp

# Initialize progress file
echo "0/${TOTAL} 初始化..." > "$PROGRESS_FILE"

update_progress() {
    echo "$1" > "$PROGRESS_FILE"
}

# Accept OLD_USER as arg or read from migration-tmp
if [ -n "$1" ]; then
    OLD_USER="$1"
elif [ -f "$MIGRATION_TMP/old_user.txt" ]; then
    OLD_USER=$(cat "$MIGRATION_TMP/old_user.txt")
elif [ -f ~/migration-tmp/old_user.txt ]; then
    OLD_USER=$(cat ~/migration-tmp/old_user.txt)
else
    OLD_USER=$(whoami)
fi

NEW_USER=$(whoami)

echo ""
echo "========================================"
echo "  OpenClaw Deploy on New Device"
echo "========================================"
echo -e "  Old user: ${YELLOW}${OLD_USER}${NC}  →  New user: ${YELLOW}${NEW_USER}${NC}"
echo ""

step=0
FAILED_STEPS=()

# ─── [1/12] Extract migration pack ──────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 解压迁移包..."
echo -n "[${step}/${TOTAL}] Extracting migration pack..."
if [ -f ~/openclaw-migration-pack.tar.gz ]; then
    mkdir -p "$MIGRATION_TMP"
    if tar xzf ~/openclaw-migration-pack.tar.gz -C "$MIGRATION_TMP"; then
        EXTRACT_SIZE=$(du -sh "$MIGRATION_TMP" | cut -f1)
        echo -e " ${GREEN}✅${NC} (${EXTRACT_SIZE})"
    else
        echo -e " ${RED}❌ 解压失败${NC}"
        FAILED_STEPS+=("Step ${step}: extract migration pack")
    fi
else
    echo -e " ${RED}❌ ~/openclaw-migration-pack.tar.gz not found!${NC}"
    FAILED_STEPS+=("Step ${step}: migration pack missing")
fi

# ─── [2/12] npm install openclaw + mcporter ─────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 安装 openclaw + mcporter..."
echo -n "[${step}/${TOTAL}] Installing openclaw + mcporter (npm -g)..."
npm install -g openclaw mcporter > /tmp/npm-install.log 2>&1 && {
    OC_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    echo -e " ${GREEN}✅${NC} (openclaw ${OC_VER})"
} || {
    echo -e " ${RED}❌ npm install failed (see /tmp/npm-install.log)${NC}"
    FAILED_STEPS+=("Step ${step}: npm install openclaw mcporter")
}

# ─── [3/12] Restore ~/.openclaw/ config ─────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 恢复 OpenClaw 配置..."
echo -n "[${step}/${TOTAL}] Restoring ~/.openclaw/ config..."
if [ -d "$MIGRATION_TMP/openclaw-config" ]; then
    mkdir -p ~/.openclaw
    # git objects are 444 (read-only); chmod destination to allow overwrite
    chmod -R u+w ~/.openclaw 2>/dev/null || true
    chmod -R u+w "$MIGRATION_TMP/openclaw-config" 2>/dev/null || true
    if cp -r "$MIGRATION_TMP/openclaw-config/." ~/.openclaw/; then
        OC_ITEMS=$(ls ~/.openclaw | wc -l)
        echo -e " ${GREEN}✅${NC} (${OC_ITEMS} 项)"
    else
        echo -e " ${RED}❌ 复制失败${NC}"
        FAILED_STEPS+=("Step ${step}: restore openclaw config")
    fi
else
    echo -e " ${YELLOW}⚠️  openclaw-config/ not found in pack, skipping${NC}"
fi

# ─── [4/12] Fix paths if username changed ───────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 修复路径..."
echo -n "[${step}/${TOTAL}] Fixing paths (${OLD_USER} → ${NEW_USER})..."
if [ "$OLD_USER" != "$NEW_USER" ]; then
    echo ""
    for target_file in ~/.openclaw/openclaw.json "$MIGRATION_TMP/crontab-backup.txt"; do
        if [ -f "$target_file" ]; then
            sed -i "s|/home/${OLD_USER}|/home/${NEW_USER}|g" "$target_file" || true
            echo -e "       ${GREEN}✓${NC} $(basename "$target_file") paths fixed"
        fi
    done
else
    echo -e " ${GREEN}✅${NC} (username unchanged, no fix needed)"
fi

# ─── [5/12] Restore /etc/hosts ──────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 恢复 /etc/hosts..."
echo -n "[${step}/${TOTAL}] Restoring /etc/hosts custom entries..."
if [ -f "$MIGRATION_TMP/hosts-custom.txt" ] && grep -qv '^#' "$MIGRATION_TMP/hosts-custom.txt" 2>/dev/null; then
    if [ "$SUDO_OK" = true ]; then
        ADDED=0
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            if ! grep -qF "$line" /etc/hosts 2>/dev/null; then
                echo "$line" | sudo tee -a /etc/hosts > /dev/null && ADDED=$((ADDED+1))
            fi
        done < "$MIGRATION_TMP/hosts-custom.txt"
        echo -e " ${GREEN}✅${NC} (${ADDED} 条新增)"
    else
        echo -e " ${YELLOW}⚠️  sudo requires password, skipping /etc/hosts (manual fix needed)${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  hosts-custom.txt empty or missing, skipping${NC}"
fi

# ─── [6/12] Restore crontab ─────────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 恢复 crontab..."
echo -n "[${step}/${TOTAL}] Restoring crontab..."
if [ -f "$MIGRATION_TMP/crontab-backup.txt" ] && grep -qv '^#' "$MIGRATION_TMP/crontab-backup.txt" 2>/dev/null; then
    crontab "$MIGRATION_TMP/crontab-backup.txt" && {
        CRON_COUNT=$(crontab -l 2>/dev/null | grep -cv '^#' || echo 0)
        echo -e " ${GREEN}✅${NC} (${CRON_COUNT} 条任务)"
    } || {
        echo -e " ${RED}❌ crontab restore failed${NC}"
        FAILED_STEPS+=("Step ${step}: restore crontab")
    }
else
    echo -e " ${YELLOW}⚠️  crontab backup empty, skipping${NC}"
fi

# ─── [7/12] Configure proxychains4 ──────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 配置 proxychains4..."
echo -n "[${step}/${TOTAL}] Configuring proxychains4..."
if command -v proxychains4 > /dev/null 2>&1; then
    echo -ne " ${GREEN}✅ (already installed)${NC}"
    if [ -f "$MIGRATION_TMP/openclaw-config/proxychains4.conf" ]; then
        if [ "$SUDO_OK" = true ]; then
            sudo cp "$MIGRATION_TMP/openclaw-config/proxychains4.conf" /etc/proxychains4.conf && \
                echo -e ", config restored from pack" || \
                echo -e " ${YELLOW}⚠️  config copy failed, using default${NC}"
        else
            echo -e " ${YELLOW}⚠️  sudo requires password, skipping config restore${NC}"
        fi
    else
        echo ""
    fi
elif [ "$SUDO_OK" = true ] && sudo apt-get install -y proxychains4 > /tmp/apt-proxychains.log 2>&1; then
    if [ -f "$MIGRATION_TMP/openclaw-config/proxychains4.conf" ]; then
        sudo cp "$MIGRATION_TMP/openclaw-config/proxychains4.conf" /etc/proxychains4.conf && \
            echo -e " ${GREEN}✅ (config restored from pack)${NC}" || \
            echo -e " ${YELLOW}⚠️  copy failed, using default${NC}"
    else
        echo -e " ${GREEN}✅ (installed, using default config)${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  proxychains4 install failed or sudo not available, skipping${NC}"
fi

# ─── [8/12] Check/fix Claude Code nvm wrapper ───────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 检查 Claude Code nvm wrapper..."
echo -n "[${step}/${TOTAL}] Checking Claude Code nvm wrapper..."
CLAUDE_BIN=~/.npm-global/bin/claude
if [ -f "$CLAUDE_BIN" ]; then
    if grep -q 'nvm' "$CLAUDE_BIN" 2>/dev/null; then
        echo -e " ${GREEN}✅ (already nvm wrapper)${NC}"
    else
        echo -e " ${YELLOW}⚠️  not nvm wrapper, rebuilding...${NC}"
        CLAUDE_ACTUAL=$(find ~/.nvm -name 'claude' -type f 2>/dev/null | head -1)
        if [ -n "$CLAUDE_ACTUAL" ]; then
            cat > "$CLAUDE_BIN" << 'WRAPPER'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true
exec "$(dirname "$(readlink -f "$0")")/../../lib/node_modules/@anthropic-ai/claude-code/cli.js" "$@"
WRAPPER
            chmod +x "$CLAUDE_BIN"
            echo -e "       ${GREEN}✓${NC} nvm wrapper rebuilt"
        else
            echo -e "       ${YELLOW}ℹ️  claude binary not found in ~/.nvm, skipping${NC}"
        fi
    fi
else
    echo -e " ${YELLOW}⚠️  ${CLAUDE_BIN} not found, searching nvm...${NC}"
    CLAUDE_NVM=$(find ~/.nvm -name 'claude' -type f 2>/dev/null | head -1)
    if [ -n "$CLAUDE_NVM" ]; then
        mkdir -p ~/.npm-global/bin
        cat > "$CLAUDE_BIN" <<WRAPPER
#!/bin/bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && source "\$NVM_DIR/nvm.sh"
exec "${CLAUDE_NVM}" "\$@"
WRAPPER
        chmod +x "$CLAUDE_BIN"
        echo -e "       ${GREEN}✓${NC} wrapper created → ${CLAUDE_NVM}"
    else
        echo -e "       ${YELLOW}ℹ️  claude not found in ~/.nvm either, skipping${NC}"
        FAILED_STEPS+=("Step ${step}: claude binary not found in ~/.npm-global or ~/.nvm")
    fi
fi

# ─── [9/12] Start OpenClaw Gateway + systemd + linger ───────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 启动 OpenClaw Gateway..."
echo -n "[${step}/${TOTAL}] Starting OpenClaw Gateway..."
# Install systemd service unit first (required on fresh devices)
openclaw gateway install > /tmp/openclaw-install.log 2>&1 || true
openclaw gateway start > /tmp/openclaw-start.log 2>&1 || {
    echo -e " ${YELLOW}⚠️  gateway start returned non-zero (may already be running)${NC}"
}
sleep 3
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable openclaw-gateway 2>/dev/null || true
systemctl --user start openclaw-gateway 2>/dev/null || true
sudo loginctl enable-linger "$USER" 2>/dev/null || true
GW_STATUS=$(openclaw gateway status 2>/dev/null || echo "unknown")
if echo "$GW_STATUS" | grep -qi 'running\|online\|active'; then
    echo -e " ${GREEN}✅ (${GW_STATUS})${NC}"
else
    echo -e " ${YELLOW}⚠️  status: ${GW_STATUS}${NC}"
    FAILED_STEPS+=("Step ${step}: openclaw gateway may not be running")
fi

# ─── [10/12] Restore Dashboard (optional) ───────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 恢复 Dashboard (可选)..."
echo -n "[${step}/${TOTAL}] Restoring Dashboard (optional)..."
if [ -d "$MIGRATION_TMP/dashboard" ]; then
    cp -r "$MIGRATION_TMP/dashboard" ~/openclaw-dashboard || true
    if [ -f ~/openclaw-dashboard/backend/requirements.txt ]; then
        timeout 120 pip3 install -r ~/openclaw-dashboard/backend/requirements.txt > /tmp/pip-dashboard.log 2>&1 || true
    fi
    echo -e " ${GREEN}✅ (restored to ~/openclaw-dashboard/)${NC}"
    echo -e "       ${YELLOW}ℹ️  Please manually configure systemd to auto-start Dashboard${NC}"
else
    echo -e " ${YELLOW}⚠️  No dashboard in pack, skipping${NC}"
fi

# ─── [11/12] Check logs for channel connectivity ─────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 检查日志连接状态..."
echo "[${step}/${TOTAL}] Checking OpenClaw logs for connectivity..."
echo ""
echo -e "  === ${YELLOW}Last 30 lines of OpenClaw logs${NC} ==="
journalctl --user -u openclaw-gateway --no-pager -n 30 2>/dev/null || \
    openclaw gateway logs 2>/dev/null | tail -30 || \
    echo "  (Unable to retrieve logs, check manually)"
echo ""
echo -e "  === ${YELLOW}Connection keywords${NC} ==="
CONN_LINES=$(journalctl --user -u openclaw-gateway --no-pager -n 200 2>/dev/null | \
    grep -Ei 'discord|feishu|connected|error|failed' | tail -10 || true)
if [ -n "$CONN_LINES" ]; then
    echo "$CONN_LINES"
else
    echo "  (No relevant log lines found)"
fi
echo ""

# ─── [12/12] Cleanup migration files ────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 清理临时文件..."
echo -n "[${step}/${TOTAL}] Cleaning up migration temp files..."
rm -rf "$MIGRATION_TMP"
echo -e " ${GREEN}✅${NC}"
echo -e "       ${YELLOW}ℹ️  setup.sh + deploy.sh kept for reference${NC}"
echo -e "       ${YELLOW}ℹ️  To free space after verification: rm ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256${NC}"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deploy Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

GW_FINAL=$(openclaw gateway status 2>/dev/null || echo "unknown")
SYS_STATUS=$(systemctl --user is-active openclaw-gateway 2>/dev/null || echo "unknown")

echo -e "  🌐 Gateway status:   ${YELLOW}${GW_FINAL}${NC}"
echo -e "  ⚙️  systemd status:   ${YELLOW}${SYS_STATUS}${NC}"
echo ""

if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    echo -e "  ${GREEN}✅ All steps completed successfully!${NC}"
else
    echo -e "  ${YELLOW}⚠️  ${#FAILED_STEPS[@]} step(s) had issues:${NC}"
    for s in "${FAILED_STEPS[@]}"; do
        echo -e "    ${RED}✗${NC} ${s}"
    done
    echo ""
    echo -e "  ${YELLOW}ℹ️  Run: journalctl --user -u openclaw-gateway -n 50${NC}"
fi

echo ""
echo -e "  Next: verify Discord/Feishu connectivity, then stop old device."
echo ""

update_progress "DONE ✅ 部署完成 (${#FAILED_STEPS[@]} 个问题)"
