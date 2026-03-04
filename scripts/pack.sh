#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TMP_DIR=~/openclaw-migration-tmp
TOTAL=10

echo ""
echo "========================================"
echo "  OpenClaw Migration Pack Builder"
echo "========================================"
echo ""

# Clean up any previous tmp dir
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"/{openclaw-config,claude-config,ssh-keys}

step=0

# ─── [1/8] Pack ~/.openclaw/ ─────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 打包 ~/.openclaw/ 配置..."
OPENCLAW_DIR=~/.openclaw
if [ -d "$OPENCLAW_DIR" ]; then
    for item in openclaw.json credentials skills extensions memory feishu \
                workspace workspace-coder workspace-paper-tracker \
                CLAUDE.md exec-approvals.json; do
        src="$OPENCLAW_DIR/$item"
        if [ -e "$src" ]; then
            cp -r "$src" "$TMP_DIR/openclaw-config/"
        fi
    done
    echo -e " ${GREEN}✅${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/.openclaw/ 不存在，跳过${NC}"
fi

# ─── [2/8] Pack ~/.claude/ ───────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 打包 ~/.claude/ (Claude Code 配置)..."
if [ -d ~/.claude ]; then
    cp -r ~/.claude/. "$TMP_DIR/claude-config/"
    echo -e " ${GREEN}✅${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/.claude/ 不存在，跳过${NC}"
fi

# ─── [3/8] Pack ~/.ssh/ ──────────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 打包 ~/.ssh/ (SSH 密钥)..."
if [ -d ~/.ssh ]; then
    cp -r ~/.ssh/. "$TMP_DIR/ssh-keys/"
    echo -e " ${GREEN}✅${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/.ssh/ 不存在，跳过${NC}"
fi

# ─── [4/8] Export crontab ────────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 导出 crontab..."
if crontab -l > "$TMP_DIR/crontab-backup.txt" 2>/dev/null; then
    echo -e " ${GREEN}✅${NC}"
else
    echo "# no crontab" > "$TMP_DIR/crontab-backup.txt"
    echo -e " ${YELLOW}⚠️  crontab 为空，已创建空文件${NC}"
fi

# ─── [5/8] Export /etc/hosts custom entries ──────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 导出 /etc/hosts 自定义条目 (discord|cdn)..."
grep -Ei 'discord|cdn' /etc/hosts > "$TMP_DIR/hosts-custom.txt" 2>/dev/null || true
if [ -s "$TMP_DIR/hosts-custom.txt" ]; then
    echo -e " ${GREEN}✅${NC}"
else
    echo "# no custom entries" > "$TMP_DIR/hosts-custom.txt"
    echo -e " ${YELLOW}⚠️  未找到 discord/cdn 相关条目，已创建空文件${NC}"
fi

# ─── [6/8] Pack Dashboard (optional) ────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 检查 ~/openclaw-dashboard/..."
if [ -d ~/openclaw-dashboard ]; then
    cp -r ~/openclaw-dashboard "$TMP_DIR/dashboard"
    echo -e " ${GREEN}✅ 已打包${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/openclaw-dashboard/ 不存在，跳过${NC}"
fi

# ─── [7/8] Record old username ───────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 记录旧服务器用户名..."
whoami > "$TMP_DIR/old_user.txt"
echo -e " ${GREEN}✅ ($(cat "$TMP_DIR/old_user.txt"))${NC}"

# ─── [8/10] Generate manifest checksum ───────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 生成关键文件校验清单 (manifest.sha256)..."
cd "$TMP_DIR"
MANIFEST_FILES=""
for f in openclaw-config/openclaw.json claude-config/settings.json ssh-keys/id_ed25519 crontab-backup.txt; do
    if [ -f "$f" ]; then
        MANIFEST_FILES="$MANIFEST_FILES $f"
    fi
done
if [ -n "$MANIFEST_FILES" ]; then
    sha256sum $MANIFEST_FILES > manifest.sha256
    echo -e " ${GREEN}✅ ($(wc -l < manifest.sha256) 个文件)${NC}"
else
    echo "# no critical files found" > manifest.sha256
    echo -e " ${YELLOW}⚠️  未找到关键文件${NC}"
fi
cd ~

# ─── [9/10] Create tarball ───────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 打包成 openclaw-migration-pack.tar.gz..."
tar czf "$PACK_FILE" -C "$TMP_DIR" .
echo -e " ${GREEN}✅${NC}"

# Clean up tmp
rm -rf "$TMP_DIR"

# ─── [10/10] Generate pack checksum ─────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] 生成整包 SHA256 校验..."
sha256sum "$PACK_FILE" > ~/openclaw-migration-pack.sha256
echo -e " ${GREEN}✅${NC}"

PACK_SIZE=$(du -sh "$PACK_FILE" | cut -f1)
echo ""
echo -e "${GREEN}========================================"
echo -e "  打包完成！"
echo -e "========================================${NC}"
echo ""
echo "  文件：$PACK_FILE"
echo "  大小：$PACK_SIZE"
echo "  校验：~/openclaw-migration-pack.sha256"
echo ""

# Copy scripts to home for transfer
cp "$(dirname "$0")/setup.sh" ~/setup.sh
chmod +x ~/setup.sh
echo -e "${GREEN}✅ setup.sh 已复制到 ~/setup.sh${NC}"

# Generate migration instructions
echo ""
echo -n "生成 migration-instructions.md..."
OLD_USER=$(whoami)
bash "$(dirname "$0")/generate-instructions.sh" "$OLD_USER"
echo -e " ${GREEN}✅${NC}"

echo ""
echo -e "${GREEN}下一步：将以下文件 scp 到新服务器：${NC}"
echo "  scp ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256 ~/setup.sh ~/migration-instructions.md USER@NEW_IP:~/"
echo ""
