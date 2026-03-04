#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TOTAL=11

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

# ─── [1/11] Verify migration pack integrity ─────────────────────────────────
echo -n "[1/${TOTAL}] 校验迁移包完整性 (SHA256)..."
if [ -f ~/openclaw-migration-pack.sha256 ]; then
    cd ~
    if sha256sum -c openclaw-migration-pack.sha256 --status 2>/dev/null; then
        echo -e " ${GREEN}✅ 整包校验通过${NC}"
    else
        fail "迁移包校验失败！文件可能在传输中损坏，请在旧服务器重新执行 scp"
    fi
else
    echo -e " ${YELLOW}⚠️  未找到校验文件，跳过完整性验证${NC}"
fi

# ─── [2/11] Install base dependencies ───────────────────────────────────────
echo -n "[2/${TOTAL}] 安装基础依赖 (git, curl, python3)..."
if sudo apt-get install -y git curl python3 python3-pip > /dev/null 2>&1; then
    ok
else
    fail "apt-get install 失败，请检查网络或 sudo 权限"
fi

# ─── [3/11] Detect China network & set npm mirror ───────────────────────────
echo -n "[3/${TOTAL}] 检测网络环境..."
USE_MIRROR=false
if ! curl -sf --connect-timeout 5 https://registry.npmjs.org/ > /dev/null 2>&1; then
    USE_MIRROR=true
    echo -e " ${YELLOW}⚠️  检测到国内网络，启用 npmmirror 加速${NC}"
else
    ok
fi

# ─── [4/11] Install / verify nvm ────────────────────────────────────────────
echo -n "[4/${TOTAL}] 检查 nvm..."
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    echo -e " ${GREEN}✅ 已安装 ($(nvm --version))${NC}"
else
    echo -e " ${YELLOW}⚠️  未找到，正在安装 nvm...${NC}"
    NVM_VERSION="v0.40.3"
    # 三级降级：官方源 → Gitee 镜像 → 报错
    if curl -fsSL --connect-timeout 15 "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash 2>/dev/null; then
        echo -e "[4/${TOTAL}] nvm 安装完成（官方源） ${GREEN}✅${NC}"
    elif curl -fsSL --connect-timeout 15 "https://gitee.com/mirrors/nvm/raw/${NVM_VERSION}/install.sh" | bash 2>/dev/null; then
        echo -e "[4/${TOTAL}] nvm 安装完成（Gitee 镜像） ${GREEN}✅${NC}"
    else
        fail "nvm 安装失败，请检查网络连接。可能需要配置代理或手动安装 nvm: https://github.com/nvm-sh/nvm#installing-and-updating"
    fi
    source "$NVM_DIR/nvm.sh"
fi

# ─── [5/11] Install Node.js 22 ───────────────────────────────────────────────
echo -n "[5/${TOTAL}] 安装 Node.js 22..."
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

# ─── [6/11] Configure npm global path ───────────────────────────────────────
echo -n "[6/${TOTAL}] 配置 npm 全局路径 (~/.npm-global)..."
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

# ─── [7/11] Install Claude Code ──────────────────────────────────────────────
echo -n "[7/${TOTAL}] 安装 Claude Code..."
if command -v claude > /dev/null 2>&1; then
    echo -e " ${GREEN}✅ 已安装 ($(claude --version 2>/dev/null || echo 'unknown'))${NC}"
else
    if timeout 120 npm install -g @anthropic-ai/claude-code > /dev/null 2>&1; then
        ok
    else
        echo -e " ${YELLOW}⚠️  安装超时，尝试 npmmirror...${NC}"
        npm config set registry https://registry.npmmirror.com
        if timeout 120 npm install -g @anthropic-ai/claude-code > /dev/null 2>&1; then
            echo -e "[7/${TOTAL}] Claude Code 安装成功（npmmirror） ${GREEN}✅${NC}"
        else
            fail "Claude Code 安装失败，请检查网络"
        fi
    fi
fi

# ─── [8/11] Restore ~/.claude/ from migration pack ──────────────────────────
echo -n "[8/${TOTAL}] 从迁移包恢复 Claude Code 配置..."
if [ -f "$PACK_FILE" ]; then
    mkdir -p ~/.claude
    tar xzf "$PACK_FILE" -C /tmp/setup-extract-$$ --wildcards 'claude-config/*' 2>/dev/null || true
    if [ -d "/tmp/setup-extract-$$/claude-config" ]; then
        # 验证关键文件完整性
        if [ -f "/tmp/setup-extract-$$/manifest.sha256" ]; then
            cd "/tmp/setup-extract-$$"
            if sha256sum -c manifest.sha256 --status 2>/dev/null; then
                echo -ne " 🔒"
            else
                rm -rf "/tmp/setup-extract-$$"
                fail "关键文件校验失败！迁移包可能损坏，请在旧服务器重新打包"
            fi
            cd ~
        fi
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

# ─── [9/11] Restore ~/.ssh/ from migration pack ─────────────────────────────
echo -n "[9/${TOTAL}] 从迁移包恢复 SSH 密钥..."
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

# ─── [10/11] Install basic tools ─────────────────────────────────────────────
echo -n "[10/${TOTAL}] 安装辅助工具 (proxychains4)..."
if sudo apt-get install -y proxychains4 > /dev/null 2>&1; then
    ok
else
    echo -e " ${YELLOW}⚠️  proxychains4 安装失败（非必须，可后续手动安装）${NC}"
fi

# ─── [11/11] Verify Claude Code ─────────────────────────────────────────────
echo -n "[11/${TOTAL}] 验证 Claude Code 可用..."
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
