#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TOTAL=9

die() {
    echo -e "${RED}❌ 错误：$1${NC}" >&2
    exit 1
}

ok() { echo -e " ${GREEN}✅${NC}"; }
fail() { echo -e " ${RED}❌${NC}"; die "$1"; }

echo ""
echo "========================================"
echo "  OpenClaw New Server Setup"
echo "========================================"
echo ""

# ─── [1/9] Install base dependencies ────────────────────────────────────────
echo -n "[1/${TOTAL}] 安装基础依赖 (git, curl, python3)..."
if sudo apt-get install -y git curl python3 python3-pip > /dev/null 2>&1; then
    ok
else
    fail "apt-get install 失败，请检查网络或 sudo 权限"
fi

# ─── [2/9] Detect China network & set npm mirror ─────────────────────────────
echo -n "[2/${TOTAL}] 检测网络环境..."
USE_MIRROR=false
if ! curl -sf --connect-timeout 5 https://registry.npmjs.org/ > /dev/null 2>&1; then
    USE_MIRROR=true
    echo -e " ${YELLOW}⚠️  检测到国内网络，启用 npmmirror 加速${NC}"
else
    ok
fi

# ─── [3/9] Install / verify nvm ─────────────────────────────────────────────
echo -n "[3/${TOTAL}] 检查 nvm..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    echo -e " ${GREEN}✅ 已安装 ($(nvm --version))${NC}"
else
    echo -e " ${YELLOW}⚠️  未找到，正在安装 nvm...${NC}"
    if [ "$USE_MIRROR" = true ]; then
        # Use China mirror for nvm install script
        NVM_INSTALL_URL="https://gitee.com/mirrors/nvm/raw/v0.39.7/install.sh"
    else
        NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
    fi
    curl -sf "$NVM_INSTALL_URL" | bash || fail "nvm 安装失败"
    source "$NVM_DIR/nvm.sh"
    echo -e "[3/${TOTAL}] nvm 安装完成 ${GREEN}✅${NC}"
fi

# ─── [4/9] Install Node.js 22 ────────────────────────────────────────────────
echo -n "[4/${TOTAL}] 安装 Node.js 22..."
if node --version 2>/dev/null | grep -q '^v22'; then
    echo -e " ${GREEN}✅ 已是 v22 ($(node --version))${NC}"
else
    if [ "$USE_MIRROR" = true ]; then
        NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node" nvm install 22 > /dev/null 2>&1 || fail "Node.js 22 安装失败"
    else
        nvm install 22 > /dev/null 2>&1 || fail "Node.js 22 安装失败"
    fi
    nvm alias default 22
    nvm use 22
    ok
fi

# ─── [5/9] Configure npm global path ────────────────────────────────────────
echo -n "[5/${TOTAL}] 配置 npm 全局路径 (~/.npm-global)..."
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
    echo -e " ${GREEN}✅ (已启用 npmmirror)${NC}"
else
    ok
fi

# ─── [6/9] Install Claude Code ───────────────────────────────────────────────
echo -n "[6/${TOTAL}] 安装 Claude Code..."
if command -v claude > /dev/null 2>&1; then
    echo -e " ${GREEN}✅ 已安装 ($(claude --version 2>/dev/null || echo 'unknown'))${NC}"
else
    npm install -g @anthropic-ai/claude-code > /dev/null 2>&1 || fail "Claude Code 安装失败，请检查网络"
    ok
fi

# ─── [7/9] Restore ~/.claude/ from migration pack ───────────────────────────
echo -n "[7/${TOTAL}] 从迁移包恢复 Claude Code 配置..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.claude
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'claude-config/*' 2>/dev/null || true
    if [ -d "/tmp/setup-extract-$$/claude-config" ]; then
        cp -r /tmp/setup-extract-$$/claude-config/. ~/.claude/
        rm -rf "/tmp/setup-extract-$$"
        ok
    else
        rm -rf "/tmp/setup-extract-$$"
        echo -e " ${YELLOW}⚠️  迁移包中未找到 claude-config/，跳过${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  未找到 $PACK_FILE，跳过${NC}"
fi

# ─── [8/9] Restore ~/.ssh/ from migration pack ──────────────────────────────
echo -n "[8/${TOTAL}] 从迁移包恢复 SSH 密钥..."
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
        echo -e " ${YELLOW}⚠️  迁移包中未找到 ssh-keys/，跳过${NC}"
    fi
else
    echo -e " ${YELLOW}⚠️  未找到 $PACK_FILE，跳过${NC}"
fi

# ─── [9/9] Verify Claude Code ────────────────────────────────────────────────
echo -n "[9/${TOTAL}] 验证 Claude Code 可用..."
if claude --version > /dev/null 2>&1; then
    ok
else
    fail "claude 命令无法运行，请检查安装是否成功"
fi

echo ""
echo -e "${GREEN}========================================"
echo -e "  基础环境就绪！"
echo -e "========================================${NC}"
echo ""
echo "下一步，运行以下命令让 Claude Code 完成迁移："
echo ""
echo -e "  ${YELLOW}claude --dangerously-skip-permissions \"按照 ~/migration-instructions.md 完成 OpenClaw 迁移\"${NC}"
echo ""
