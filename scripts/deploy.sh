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

# Ensure .profile has NVM_DIR + npm-global PATH for future login shells (#3)
for _rc in ~/.bashrc ~/.profile; do
    touch "$_rc"
    grep -q 'npm-global' "$_rc" || echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$_rc"
    grep -q 'NVM_DIR' "$_rc" || { echo 'export NVM_DIR="$HOME/.nvm"'; echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'; } >> "$_rc"
done
unset _rc

# Check if sudo is available without password (non-interactive SSH)
SUDO_OK=false
if sudo -n true 2>/dev/null; then
    SUDO_OK=true
fi

# ─── Detect deploy mode ───────────────────────────────────────────────────────
# Priority: env var DEPLOY_MODE > /tmp/openclaw-network-result.txt > default (proxy)
if [ -z "$DEPLOY_MODE" ]; then
    if [ -f /tmp/openclaw-network-result.txt ]; then
        NET_RESULT=$(cat /tmp/openclaw-network-result.txt 2>/dev/null | tr -d '[:space:]')
        case "$NET_RESULT" in
            DIRECT) DEPLOY_MODE="direct" ;;
            *)      DEPLOY_MODE="proxy"  ;;
        esac
    else
        DEPLOY_MODE="proxy"  # default: backward compat
    fi
fi

if [ "$DEPLOY_MODE" = "direct" ]; then
    TOTAL=13  # 12 original + 1 direct mode cleanup
else
    TOTAL=12
fi

PROGRESS_FILE="/tmp/openclaw-deploy-progress.txt"
MIGRATION_TMP=~/migration-tmp

# Initialize progress file
echo "0/${TOTAL} 初始化..." > "$PROGRESS_FILE"

update_progress() {
    echo "$1" > "$PROGRESS_FILE"
}

# OLD_USER will be resolved AFTER extraction (see below)
OLD_USER=""
NEW_USER=$(whoami)

echo ""
echo "========================================"
echo "  Agent Clone Deploy"
echo "========================================"

step=0
FAILED_STEPS=()

# ─── [1/12] Extract migration pack ──────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 解压克隆包..."
echo -n "[${step}/${TOTAL}] Extracting clone pack..."
if [ -f ~/openclaw-migration-pack.tar.gz ]; then
    mkdir -p "$MIGRATION_TMP"
    if tar xzf ~/openclaw-migration-pack.tar.gz -C "$MIGRATION_TMP"; then
        EXTRACT_SIZE=$(du -sh "$MIGRATION_TMP" | cut -f1)
        echo -e " ${GREEN}✅${NC} (${EXTRACT_SIZE})"
    else
        echo -e " ${RED}❌ 解压失败${NC}"
        FAILED_STEPS+=("Step ${step}: extract clone pack")
    fi

# Resolve OLD_USER now that the pack is extracted
if [ -n "$1" ]; then
    OLD_USER="$1"
elif [ -f "$MIGRATION_TMP/old_user.txt" ]; then
    OLD_USER=$(cat "$MIGRATION_TMP/old_user.txt")
else
    OLD_USER="$NEW_USER"
    echo -e "  ${YELLOW}⚠️  old_user.txt not found in pack, assuming same user${NC}"
fi

echo -e "  Old user: ${YELLOW}${OLD_USER}${NC}  →  New user: ${YELLOW}${NEW_USER}${NC}"
else
    echo -e " ${RED}❌ ~/openclaw-migration-pack.tar.gz not found!${NC}"
    FAILED_STEPS+=("Step ${step}: clone pack missing")
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
    # Scan all .json files under ~/.openclaw/ and ~/.claude/ for old user paths
    while IFS= read -r target_file; do
        if grep -q "/home/${OLD_USER}" "$target_file" 2>/dev/null; then
            sed -i "s|/home/${OLD_USER}|/home/${NEW_USER}|g" "$target_file" || true
            echo -e "       ${GREEN}✓${NC} ${target_file} paths fixed"
        fi
    done < <(find ~/.openclaw ~/.claude -type f \( -name '*.json' -o -name '*.md' -o -name '*.sh' -o -name '*.service' -o -name '*.txt' -o -name '*.conf' -o -name '*.toml' -o -name '*.yaml' -o -name '*.yml' -o -name '*.html' -o -name '*.py' \) 2>/dev/null)
    # Also fix crontab backup
    if [ -f "$MIGRATION_TMP/crontab-backup.txt" ] && grep -q "/home/${OLD_USER}" "$MIGRATION_TMP/crontab-backup.txt" 2>/dev/null; then
        sed -i "s|/home/${OLD_USER}|/home/${NEW_USER}|g" "$MIGRATION_TMP/crontab-backup.txt" || true
        echo -e "       ${GREEN}✓${NC} crontab-backup.txt paths fixed"
    fi
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
if [ "$DEPLOY_MODE" = "direct" ]; then
    echo -e " ${YELLOW}ℹ️  Direct mode: proxychains not needed, skipping${NC}"
elif command -v proxychains4 > /dev/null 2>&1; then
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
        CLAUDE_ACTUAL=$(find ~/.nvm -name 'claude' \( -type f -o -type l \) 2>/dev/null | grep '/bin/claude$' | head -1)
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
    CLAUDE_NVM=$(find ~/.nvm -name 'claude' \( -type f -o -type l \) 2>/dev/null | grep '/bin/claude$' | head -1)
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
# Try openclaw gateway install; fallback to nohup if install fails (e.g. systemctl --user unavailable)
if openclaw gateway install > /tmp/openclaw-install.log 2>&1; then
    openclaw gateway start > /tmp/openclaw-start.log 2>&1 || true
    sleep 3
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable openclaw-gateway 2>/dev/null || true
    systemctl --user start openclaw-gateway 2>/dev/null || true
else
    echo -ne " ${YELLOW}(install failed, falling back to nohup)${NC}"
    nohup openclaw gateway run > /tmp/openclaw-gateway.log 2>&1 &
    sleep 5
    pgrep -f 'openclaw.*gateway' > /dev/null 2>&1 && echo -ne " ${GREEN}(process running)${NC}"
fi
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
    # chmod to fix read-only .git objects from previous installs
    chmod -R u+w ~/openclaw-dashboard 2>/dev/null || true
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

# ─── [13/13] Direct mode config cleanup (direct mode only) ───────────────────
if [ "$DEPLOY_MODE" = "direct" ]; then
    step=$((step+1))
    update_progress "${step}/${TOTAL} 直连模式配置清理..."
    echo ""
    echo -e "${YELLOW}[${step}/${TOTAL}] Direct mode config cleanup${NC}"
    CLEANUP_DONE=()

    # 1. Remove proxy env vars from ~/.openclaw/openclaw.json
    OC_JSON=~/.openclaw/openclaw.json
    if [ -f "$OC_JSON" ]; then
        python3 << 'PYEOF'
import json, os
path = os.path.expanduser("~/.openclaw/openclaw.json")
try:
    with open(path) as f:
        data = json.load(f)
    removed = []
    for sec in ("env", "environment", "envVars"):
        if sec in data and isinstance(data[sec], dict):
            keys = [k for k in data[sec] if any(p in k.lower() for p in ("proxy", "socks"))]
            for k in keys:
                del data[sec][k]
                removed.append(f"{sec}.{k}")
    top_proxy = [k for k in data if any(p in k.lower() for p in ("proxy", "socks"))
                 and k not in ("env", "environment", "envVars")]
    for k in top_proxy:
        del data[k]
        removed.append(k)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    if removed:
        print("  Removed proxy keys: " + ", ".join(removed))
    else:
        print("  No proxy keys found in openclaw.json")
except Exception as e:
    print(f"  Warning: could not clean openclaw.json: {e}")
PYEOF
        echo -e "  ${GREEN}✅${NC} openclaw.json checked"
        CLEANUP_DONE+=("openclaw.json")
    else
        echo -e "  ${YELLOW}ℹ️${NC}  ~/.openclaw/openclaw.json not found, skipping"
    fi

    # 2. Remove CDN hack lines added by Step 5 from /etc/hosts
    if [ "$SUDO_OK" = true ]; then
        CDN_COUNT=$(grep -cE 'cdn\.discordapp\.com|media\.discordapp\.net' /etc/hosts 2>/dev/null || echo 0)
        if [ "$CDN_COUNT" -gt 0 ]; then
            sudo sed -i '/cdn\.discordapp\.com/d;/media\.discordapp\.net/d' /etc/hosts
            echo -e "  ${GREEN}✅${NC} /etc/hosts: removed ${CDN_COUNT} CDN hack line(s)"
            CLEANUP_DONE+=("/etc/hosts CDN lines")
        else
            echo -e "  ${YELLOW}ℹ️${NC}  /etc/hosts: no CDN hack lines found"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC}  sudo not available, /etc/hosts CDN lines not removed"
        echo -e "       Manual fix: sudo sed -i '/cdn\\.discordapp\\.com/d;/media\\.discordapp\\.net/d' /etc/hosts"
    fi

    # 3. Remove HTTP_PROXY / HTTPS_PROXY from ~/.claude/settings.json
    CLAUDE_SETTINGS=~/.claude/settings.json
    if [ -f "$CLAUDE_SETTINGS" ] && grep -qiE 'http_proxy|https_proxy' "$CLAUDE_SETTINGS" 2>/dev/null; then
        python3 << 'PYEOF'
import json, os
path = os.path.expanduser("~/.claude/settings.json")
try:
    with open(path) as f:
        data = json.load(f)
    removed = []
    for sec in ("env", "environment"):
        if sec in data and isinstance(data[sec], dict):
            keys = [k for k in data[sec] if "proxy" in k.lower()]
            for k in keys:
                del data[sec][k]
                removed.append(f"{sec}.{k}")
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    if removed:
        print("  Removed proxy keys: " + ", ".join(removed))
    else:
        print("  No proxy keys found in settings.json")
except Exception as e:
    print(f"  Warning: could not clean settings.json: {e}")
PYEOF
        echo -e "  ${GREEN}✅${NC} ~/.claude/settings.json proxy config cleaned"
        CLEANUP_DONE+=("settings.json")
    else
        echo -e "  ${YELLOW}ℹ️${NC}  ~/.claude/settings.json: no proxy config found or file missing"
    fi

    # Cleanup summary
    echo ""
    if [ ${#CLEANUP_DONE[@]} -gt 0 ]; then
        echo -e "  ${GREEN}✅ Direct mode cleanup: ${#CLEANUP_DONE[@]} file(s) processed${NC}"
    else
        echo -e "  ${YELLOW}ℹ️  Direct mode cleanup: nothing to remove (already clean)${NC}"
    fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Clone Deploy Summary${NC}"
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
if ! command -v qmd > /dev/null 2>&1; then
    echo -e "  ${YELLOW}ℹ️  qmd (memory search) 未安装。可选安装: npm install -g @tobilu/qmd${NC}"
fi
echo -e "  Next: verify Discord/Feishu connectivity on new device."
echo ""

update_progress "DONE ✅ 部署完成 (${#FAILED_STEPS[@]} 个问题)"
