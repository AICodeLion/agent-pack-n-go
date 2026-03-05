#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TOTAL=12
PROGRESS_FILE="/tmp/openclaw-setup-progress.txt"
echo "0/${TOTAL} 初始化..." > "$PROGRESS_FILE"

update_progress() { echo "$1" > "$PROGRESS_FILE"; }

# Check if sudo is available without password (non-interactive SSH)
SUDO_OK=false
if sudo -n true 2>/dev/null; then
    SUDO_OK=true
fi

# ─── Spinner ─────────────────────────────────────────────────────────────────
# Usage: run_with_spinner "label" cmd [args...]
# Runs cmd in background, shows spinner until done.
# Exit code of cmd is preserved.
_SPINNER_FRAMES='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
run_with_spinner() {
    local label="$1"
    shift
    local log_file
    log_file=$(mktemp)
    # Run command in background
    "$@" > "$log_file" 2>&1 &
    local pid=$!
    local i=0
    local frame
    # Trap to clean up spinner on exit
    trap 'tput cnorm 2>/dev/null; rm -f "$log_file"' RETURN
    tput civis 2>/dev/null || true  # hide cursor
    while kill -0 "$pid" 2>/dev/null; do
        frame="${_SPINNER_FRAMES:$((i % ${#_SPINNER_FRAMES})):1}"
        printf "\r  %s %s" "$frame" "$label"
        i=$((i + 1))
        sleep 0.1
    done
    wait "$pid"
    local exit_code=$?
    tput cnorm 2>/dev/null || true  # restore cursor
    printf "\r"  # clear spinner line
    rm -f "$log_file"
    return "$exit_code"
}

die() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
    exit 1
}

ok() { echo -e " ${GREEN}✅${NC}"; }
fail() { echo -e " ${RED}❌${NC}"; die "$1"; }

echo ""
echo "========================================"
echo "  OpenClaw New Device Setup"
echo "========================================"
echo ""

# ─── [1/12] Verify migration pack integrity ─────────────────────────────────
update_progress "1/${TOTAL} 校验迁移包完整性..."
echo -n "[1/${TOTAL}] Verifying migration pack integrity (SHA256)..."
if [ -f ~/openclaw-migration-pack.sha256 ]; then
    cd ~
    if sha256sum -c openclaw-migration-pack.sha256 --status 2>/dev/null; then
        echo -e " ${GREEN}✅ Pack checksum verified${NC}"
    else
        fail "Migration pack checksum failed! File may have been corrupted during transfer. Please re-run scp from the old device."
    fi
else
    echo -e " ${YELLOW}⚠️  Checksum file not found, skipping integrity verification${NC}"
fi

# ─── [2/12] Update system packages ──────────────────────────────────────────
update_progress "2/${TOTAL} 更新系统包..."
printf "[2/${TOTAL}] Updating system packages..."
if [ "$SUDO_OK" = true ]; then
    if run_with_spinner "Updating system packages..." bash -c 'sudo apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y'; then
        ok
    else
        echo -e " ${YELLOW}⚠️  System update failed (non-fatal, continuing)${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  sudo requires password, skipping (run manually: sudo apt-get update && sudo apt-get upgrade -y)${NC}"
fi

# ─── [3/12] Install base dependencies ───────────────────────────────────────
update_progress "3/${TOTAL} 安装基础依赖..."
printf "[3/${TOTAL}] Installing base dependencies (git, curl, python3)..."
if [ "$SUDO_OK" = true ]; then
    if run_with_spinner "Installing base dependencies..." sudo apt-get install -y git curl python3 python3-pip; then
        ok
    else
        fail "apt-get install failed, please check network or sudo permissions"
    fi
else
    # Check if they're already installed
    if command -v git > /dev/null 2>&1 && command -v curl > /dev/null 2>&1 && command -v python3 > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ (already installed)${NC}"
    else
        fail "sudo requires password and base dependencies are missing. Run manually: sudo apt-get install -y git curl python3 python3-pip"
    fi
fi

# ─── [4/12] Detect China network & set npm mirror ───────────────────────────
update_progress "4/${TOTAL} 检测网络环境..."
echo -n "[4/${TOTAL}] Detecting network environment..."
USE_MIRROR=false
if ! curl -sf --connect-timeout 5 https://registry.npmjs.org/ > /dev/null 2>&1; then
    USE_MIRROR=true
    echo -e " ${YELLOW}⚠️  China network detected, enabling npmmirror${NC}"
else
    ok
fi

# ─── [5/12] Install / verify nvm ────────────────────────────────────────────
update_progress "5/${TOTAL} 检查 nvm..."
echo -n "[5/${TOTAL}] Checking nvm..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    echo -e " ${GREEN}✅ Already installed ($(nvm --version))${NC}"
else
    echo -e " ${YELLOW}⚠️  Not found, installing nvm...${NC}"
    NVM_VERSION="v0.40.3"
    # Three-tier fallback: official → Gitee mirror → error
    _nvm_install_official() { curl -fsSL --connect-timeout 15 "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash; }
    _nvm_install_gitee()    { curl -fsSL --connect-timeout 15 "https://gitee.com/mirrors/nvm/raw/${NVM_VERSION}/install.sh" | bash; }
    if run_with_spinner "Installing nvm (official)..." _nvm_install_official 2>/dev/null; then
        echo -e "[5/${TOTAL}] nvm installed (official source) ${GREEN}✅${NC}"
    elif run_with_spinner "Installing nvm (Gitee mirror)..." _nvm_install_gitee 2>/dev/null; then
        echo -e "[5/${TOTAL}] nvm installed (Gitee mirror) ${GREEN}✅${NC}"
    else
        fail "nvm installation failed, please check network connectivity. You may need to configure a proxy or install nvm manually: https://github.com/nvm-sh/nvm#installing-and-updating"
    fi
    source "$NVM_DIR/nvm.sh"
fi

# ─── [6/12] Install Node.js 22 ───────────────────────────────────────────────
update_progress "6/${TOTAL} 安装 Node.js 22..."
printf "[6/${TOTAL}] Installing Node.js 22..."
if node --version 2>/dev/null | grep -q '^v22'; then
    echo -e " ${GREEN}✅ Already v22 ($(node --version))${NC}"
else
    if [ "$USE_MIRROR" = true ]; then
        if run_with_spinner "Installing Node.js 22 (npmmirror)..." bash -c 'NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node" nvm install 22'; then
            ok
        else
            fail "Node.js 22 installation failed"
        fi
    else
        if run_with_spinner "Installing Node.js 22..." nvm install 22; then
            ok
        else
            fail "Node.js 22 installation failed"
        fi
    fi
    nvm alias default 22
    nvm use 22
fi

# ─── [7/12] Configure npm global path ───────────────────────────────────────
update_progress "7/${TOTAL} 配置 npm 全局路径..."
echo -n "[7/${TOTAL}] Configuring npm global path (~/.npm-global)..."
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global

# Add to PATH in shell rc files
for RC in ~/.bashrc ~/.zshrc; do
    if [ -f "$RC" ] && ! grep -q 'npm-global' "$RC"; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$RC"
    fi
done
export PATH="$HOME/.npm-global/bin:$PATH"

if [ "$USE_MIRROR" = true ]; then
    npm config set registry https://registry.npmmirror.com
    echo -e " ${GREEN}✅ (npmmirror enabled)${NC}"
else
    ok
fi

# ─── [8/12] Install Claude Code ──────────────────────────────────────────────
update_progress "8/${TOTAL} 安装 Claude Code..."
printf "[8/${TOTAL}] Installing Claude Code..."
if command -v claude > /dev/null 2>&1; then
    echo -e " ${GREEN}✅ Already installed ($(claude --version 2>/dev/null || echo 'unknown'))${NC}"
else
    if run_with_spinner "Installing Claude Code..." timeout 120 npm install -g @anthropic-ai/claude-code; then
        ok
    else
        echo -e " ${YELLOW}⚠️  Install timeout, trying npmmirror...${NC}"
        npm config set registry https://registry.npmmirror.com
        if run_with_spinner "Installing Claude Code (npmmirror)..." timeout 120 npm install -g @anthropic-ai/claude-code; then
            echo -e "[8/${TOTAL}] Claude Code installed (npmmirror) ${GREEN}✅${NC}"
        else
            fail "Claude Code installation failed, please check network"
        fi
    fi
fi

# ─── [9/12] Restore ~/.claude/ from migration pack ──────────────────────────
update_progress "9/${TOTAL} 恢复 Claude Code 配置..."
echo -n "[9/${TOTAL}] Restoring Claude Code config from migration pack..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.claude
    mkdir -p /tmp/setup-extract-$$
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'claude-config/*' 'manifest.sha256' 2>/dev/null || true
    if [ -d "/tmp/setup-extract-$$/claude-config" ]; then
        # Verify critical file integrity
        if [ -f "/tmp/setup-extract-$$/manifest.sha256" ]; then
            cd "/tmp/setup-extract-$$"
            if sha256sum -c manifest.sha256 --status 2>/dev/null; then
                echo -ne " 🔒"
            else
                rm -rf "/tmp/setup-extract-$$"
                fail "Critical file checksum failed! Migration pack may be corrupted. Please re-pack from the old device."
            fi
            cd ~
        fi
        cp -r /tmp/setup-extract-$$/claude-config/. ~/.claude/
        CC_RESTORED=$(find /tmp/setup-extract-$$/claude-config -type f | wc -l)
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${GREEN}✅${NC} (${CC_RESTORED} 个文件已恢复)"
    else
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${YELLOW}⚠️  claude-config/ not found in migration pack, skipping${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  $PACK_FILE not found, skipping${NC}"
fi

# ─── [10/12] Restore ~/.ssh/ from migration pack ────────────────────────────
update_progress "10/${TOTAL} 恢复 SSH 密钥..."
echo -n "[10/${TOTAL}] Restoring SSH keys from migration pack..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.ssh
    mkdir -p /tmp/setup-extract-$$
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'ssh-keys/*' 2>/dev/null || true
    if [ -d "/tmp/setup-extract-$$/ssh-keys" ]; then
        cp -r /tmp/setup-extract-$$/ssh-keys/. ~/.ssh/
        SSH_RESTORED=$(find /tmp/setup-extract-$$/ssh-keys -maxdepth 1 -name 'id_*' ! -name '*.pub' 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$//')
        rm -rf "/tmp/setup-extract-$$"
        # Fix permissions
        chmod 700 ~/.ssh
        find ~/.ssh -type f \( -name 'id_*' ! -name '*.pub' \) -exec chmod 600 {} \;
        find ~/.ssh -name 'config' -exec chmod 600 {} \;
        echo -e " ${GREEN}✅${NC}"
        if [ -n "$SSH_RESTORED" ]; then
            echo -e "       密钥: ${SSH_RESTORED}"
        fi
    else
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${YELLOW}⚠️  ssh-keys/ not found in migration pack, skipping${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  $PACK_FILE not found, skipping${NC}"
fi

# ─── [11/12] Install basic tools ─────────────────────────────────────────────
update_progress "11/${TOTAL} 安装辅助工具..."
printf "[11/${TOTAL}] Installing auxiliary tools (proxychains4)..."
if [ "$SUDO_OK" = true ]; then
    if run_with_spinner "Installing proxychains4..." sudo apt-get install -y proxychains4; then
        ok
    else
        echo -e " ${YELLOW}⚠️  proxychains4 installation failed (optional, can be installed manually later)${NC}"
    fi
else
    if command -v proxychains4 > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ (already installed)${NC}"
    else
        echo -e " ${YELLOW}⚠️  sudo requires password, skipping (run manually: sudo apt-get install -y proxychains4)${NC}"
    fi
fi

# ─── [12/12] Verify Claude Code ─────────────────────────────────────────────
update_progress "12/${TOTAL} 验证 Claude Code..."
echo -n "[12/${TOTAL}] Verifying Claude Code is functional..."
if claude --version > /dev/null 2>&1; then
    ok
else
    fail "claude command failed to run, please check the installation"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Base environment ready!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  📋 已安装："
echo -e "    ${GREEN}✓${NC} Node.js $(node --version 2>/dev/null || echo 'N/A')"
echo -e "    ${GREEN}✓${NC} npm $(npm --version 2>/dev/null || echo 'N/A')"
echo -e "    ${GREEN}✓${NC} Claude Code $(claude --version 2>/dev/null || echo 'N/A')"
command -v proxychains4 >/dev/null 2>&1 && echo -e "    ${GREEN}✓${NC} proxychains4"
echo ""
echo -e "  📋 已恢复："
[ -f ~/.claude/settings.json ] && echo -e "    ${GREEN}✓${NC} Claude Code 配置"
[ -d ~/.ssh ] && echo -e "    ${GREEN}✓${NC} SSH 密钥 ($(find ~/.ssh -maxdepth 1 -name 'id_*' ! -name '*.pub' 2>/dev/null | wc -l) 个)"
echo ""
echo -e "  Next: run ${YELLOW}bash ~/deploy.sh${NC} to deploy OpenClaw on this device."
echo -e "  (Or let your agent run it remotely via SSH)"
echo ""
update_progress "DONE ✅ 基础环境就绪"
