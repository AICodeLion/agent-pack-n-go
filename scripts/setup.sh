#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TOTAL=11

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

# ─── [1/11] Verify migration pack integrity ─────────────────────────────────
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

# ─── [2/11] Install base dependencies ───────────────────────────────────────
printf "[2/${TOTAL}] Installing base dependencies (git, curl, python3)..."
if run_with_spinner "Installing base dependencies..." sudo apt-get install -y git curl python3 python3-pip; then
    ok
else
    fail "apt-get install failed, please check network or sudo permissions"
fi

# ─── [3/11] Detect China network & set npm mirror ───────────────────────────
echo -n "[3/${TOTAL}] Detecting network environment..."
USE_MIRROR=false
if ! curl -sf --connect-timeout 5 https://registry.npmjs.org/ > /dev/null 2>&1; then
    USE_MIRROR=true
    echo -e " ${YELLOW}⚠️  China network detected, enabling npmmirror${NC}"
else
    ok
fi

# ─── [4/11] Install / verify nvm ────────────────────────────────────────────
echo -n "[4/${TOTAL}] Checking nvm..."
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
        echo -e "[4/${TOTAL}] nvm installed (official source) ${GREEN}✅${NC}"
    elif run_with_spinner "Installing nvm (Gitee mirror)..." _nvm_install_gitee 2>/dev/null; then
        echo -e "[4/${TOTAL}] nvm installed (Gitee mirror) ${GREEN}✅${NC}"
    else
        fail "nvm installation failed, please check network connectivity. You may need to configure a proxy or install nvm manually: https://github.com/nvm-sh/nvm#installing-and-updating"
    fi
    source "$NVM_DIR/nvm.sh"
fi

# ─── [5/11] Install Node.js 22 ───────────────────────────────────────────────
printf "[5/${TOTAL}] Installing Node.js 22..."
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

# ─── [6/11] Configure npm global path ───────────────────────────────────────
echo -n "[6/${TOTAL}] Configuring npm global path (~/.npm-global)..."
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

# ─── [7/11] Install Claude Code ──────────────────────────────────────────────
printf "[7/${TOTAL}] Installing Claude Code..."
if command -v claude > /dev/null 2>&1; then
    echo -e " ${GREEN}✅ Already installed ($(claude --version 2>/dev/null || echo 'unknown'))${NC}"
else
    if run_with_spinner "Installing Claude Code..." timeout 120 npm install -g @anthropic-ai/claude-code; then
        ok
    else
        echo -e " ${YELLOW}⚠️  Install timeout, trying npmmirror...${NC}"
        npm config set registry https://registry.npmmirror.com
        if run_with_spinner "Installing Claude Code (npmmirror)..." timeout 120 npm install -g @anthropic-ai/claude-code; then
            echo -e "[7/${TOTAL}] Claude Code installed (npmmirror) ${GREEN}✅${NC}"
        else
            fail "Claude Code installation failed, please check network"
        fi
    fi
fi

# ─── [8/11] Restore ~/.claude/ from migration pack ──────────────────────────
echo -n "[8/${TOTAL}] Restoring Claude Code config from migration pack..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.claude
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'claude-config/*' 2>/dev/null || true
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
        rm -rf "/tmp/setup-extract-$$"
        ok
    else
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${YELLOW}⚠️  claude-config/ not found in migration pack, skipping${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  $PACK_FILE not found, skipping${NC}"
fi

# ─── [9/11] Restore ~/.ssh/ from migration pack ─────────────────────────────
echo -n "[9/${TOTAL}] Restoring SSH keys from migration pack..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.ssh
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'ssh-keys/*' 2>/dev/null || true
    if [ -d "/tmp/setup-extract-$$/ssh-keys" ]; then
        cp -r /tmp/setup-extract-$$/ssh-keys/. ~/.ssh/
        rm -rf "/tmp/setup-extract-$$"
        # Fix permissions
        chmod 700 ~/.ssh
        find ~/.ssh -type f \( -name 'id_*' ! -name '*.pub' \) -exec chmod 600 {} \;
        find ~/.ssh -name 'config' -exec chmod 600 {} \;
        ok
    else
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${YELLOW}⚠️  ssh-keys/ not found in migration pack, skipping${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  $PACK_FILE not found, skipping${NC}"
fi

# ─── [10/11] Install basic tools ─────────────────────────────────────────────
printf "[10/${TOTAL}] Installing auxiliary tools (proxychains4)..."
if run_with_spinner "Installing proxychains4..." sudo apt-get install -y proxychains4; then
    ok
else
    echo -e " ${YELLOW}⚠️  proxychains4 installation failed (optional, can be installed manually later)${NC}"
fi

# ─── [11/11] Verify Claude Code ─────────────────────────────────────────────
echo -n "[11/${TOTAL}] Verifying Claude Code is functional..."
if claude --version > /dev/null 2>&1; then
    ok
else
    fail "claude command failed to run, please check the installation"
fi

echo ""
echo -e "${GREEN}========================================"
echo -e "  Base environment ready!"
echo -e "========================================${NC}"
echo ""
echo "Next, run the following command to let Claude Code complete the migration:"
echo ""
echo -e "  ${YELLOW}claude --dangerously-skip-permissions \"Follow ~/migration-instructions.md to complete the OpenClaw migration\"${NC}"
echo ""
