#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PACK_FILE=~/openclaw-migration-pack.tar.gz
TMP_DIR=~/openclaw-migration-tmp
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL=11
PROGRESS_FILE="/tmp/openclaw-pack-progress.txt"

# Initialize progress file for external monitoring (e.g., agent polling)
echo "0/${TOTAL} 初始化..." > "$PROGRESS_FILE"

# Helper: update progress file
update_progress() {
    echo "$1" > "$PROGRESS_FILE"
}

echo ""
echo "========================================"
echo "  OpenClaw Migration Pack Builder"
echo "========================================"
echo ""

# Clean up any previous tmp dir
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"/{openclaw-config,claude-config,ssh-keys}

step=0

# ─── [1/11] Pack ~/.openclaw/ ────────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 打包 OpenClaw 配置..."
echo -n "[${step}/${TOTAL}] Packing ~/.openclaw/ config..."
OPENCLAW_DIR=~/.openclaw
if [ -d "$OPENCLAW_DIR" ]; then
    PACKED_ITEMS=()
    for item in openclaw.json credentials skills extensions memory feishu \
                workspace workspace-coder workspace-paper-tracker \
                CLAUDE.md exec-approvals.json; do
        src="$OPENCLAW_DIR/$item"
        if [ -e "$src" ]; then
            cp -r "$src" "$TMP_DIR/openclaw-config/"
            PACKED_ITEMS+=("$item")
        fi
    done
    OC_SIZE=$(du -sh "$TMP_DIR/openclaw-config" | cut -f1)
    echo -e " ${GREEN}✅${NC} (${#PACKED_ITEMS[@]} 项, ${OC_SIZE})"
    for item in "${PACKED_ITEMS[@]}"; do
        echo -e "       ${GREEN}✓${NC} $item"
    done
else
    echo -e " ${YELLOW}⚠️  ~/.openclaw/ not found, skipping${NC}"
fi

# ─── [2/11] Pack ~/.claude/ ──────────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 打包 Claude Code 配置..."
echo -n "[${step}/${TOTAL}] Packing ~/.claude/ (Claude Code config)..."
if [ -d ~/.claude ]; then
    cp -r ~/.claude/. "$TMP_DIR/claude-config/"
    CC_FILES=$(find "$TMP_DIR/claude-config" -type f | wc -l)
    CC_SIZE=$(du -sh "$TMP_DIR/claude-config" | cut -f1)
    echo -e " ${GREEN}✅${NC} (${CC_FILES} 个文件, ${CC_SIZE})"
else
    echo -e " ${YELLOW}⚠️  ~/.claude/ not found, skipping${NC}"
fi

# ─── [3/11] Pack ~/.ssh/ ─────────────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 打包 SSH 密钥..."
echo -n "[${step}/${TOTAL}] Packing ~/.ssh/ (SSH keys)..."
if [ -d ~/.ssh ]; then
    cp -r ~/.ssh/. "$TMP_DIR/ssh-keys/"
    SSH_KEYS=$(find "$TMP_DIR/ssh-keys" -maxdepth 1 -name 'id_*' ! -name '*.pub' 2>/dev/null | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$//')
    echo -e " ${GREEN}✅${NC}"
    if [ -n "$SSH_KEYS" ]; then
        echo -e "       密钥: ${SSH_KEYS}"
    fi
else
    echo -e " ${YELLOW}⚠️  ~/.ssh/ not found, skipping${NC}"
fi

# ─── [4/11] Export crontab ───────────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 导出 crontab..."
echo -n "[${step}/${TOTAL}] Exporting crontab..."
if crontab -l > "$TMP_DIR/crontab-backup.txt" 2>/dev/null; then
    CRON_COUNT=$(grep -v "^#" "$TMP_DIR/crontab-backup.txt" 2>/dev/null | grep -c "[^[:space:]]" || echo 0)
    echo -e " ${GREEN}✅${NC} (${CRON_COUNT} 条任务)"
else
    echo "# no crontab" > "$TMP_DIR/crontab-backup.txt"
    echo -e " ${YELLOW}⚠️  crontab is empty, created empty file${NC}"
fi

# ─── [5/11] Export /etc/hosts custom entries ─────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 导出 hosts 配置..."
echo -n "[${step}/${TOTAL}] Exporting /etc/hosts custom entries (discord|cdn)..."
grep -Ei 'discord|cdn' /etc/hosts > "$TMP_DIR/hosts-custom.txt" 2>/dev/null || true
if [ -s "$TMP_DIR/hosts-custom.txt" ]; then
    HOSTS_COUNT=$(wc -l < "$TMP_DIR/hosts-custom.txt")
    echo -e " ${GREEN}✅${NC} (${HOSTS_COUNT} 条)"
    while IFS= read -r line; do
        echo -e "       ${line}"
    done < "$TMP_DIR/hosts-custom.txt"
else
    echo "# no custom entries" > "$TMP_DIR/hosts-custom.txt"
    echo -e " ${YELLOW}⚠️  No discord/cdn entries found, created empty file${NC}"
fi

# ─── [6/11] Pack Dashboard (optional) ───────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 检查 Dashboard..."
echo -n "[${step}/${TOTAL}] Checking ~/openclaw-dashboard/..."
if [ -d ~/openclaw-dashboard ]; then
    cp -r ~/openclaw-dashboard "$TMP_DIR/dashboard"
    echo -e " ${GREEN}✅ Packed${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/openclaw-dashboard/ not found, skipping${NC}"
fi

# ─── [7/11] Record old username ──────────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 记录用户名..."
echo -n "[${step}/${TOTAL}] Recording old device username..."
whoami > "$TMP_DIR/old_user.txt"
echo -e " ${GREEN}✅ ($(cat "$TMP_DIR/old_user.txt"))${NC}"

# ─── [8/11] Generate manifest checksum ──────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 生成校验文件..."
echo -n "[${step}/${TOTAL}] Generating critical file checksums (manifest.sha256)..."
cd "$TMP_DIR"
MANIFEST_FILES=""
for f in openclaw-config/openclaw.json claude-config/settings.json crontab-backup.txt; do
    if [ -f "$f" ]; then
        MANIFEST_FILES="$MANIFEST_FILES $f"
    fi
done
for key in ssh-keys/id_*; do
    [[ -f "$key" && "$key" != *.pub ]] && MANIFEST_FILES="$MANIFEST_FILES $key"
done
if [ -n "$MANIFEST_FILES" ]; then
    sha256sum $MANIFEST_FILES > manifest.sha256
    echo -e " ${GREEN}✅ ($(wc -l < manifest.sha256) files)${NC}"
else
    echo "# no critical files found" > manifest.sha256
    echo -e " ${YELLOW}⚠️  No critical files found${NC}"
fi
cd ~

# ─── [9/11] Create tarball ───────────────────────────────────────────────────
step=$((step+1))
TAR_START=$(date +%s)
if command -v pv > /dev/null 2>&1; then
    update_progress "${step}/${TOTAL} 创建迁移包..."
    echo "[${step}/${TOTAL}] Creating openclaw-migration-pack.tar.gz (pv)..."
    tar cz -C "$TMP_DIR" . | pv -s "$(du -sb "$TMP_DIR" | cut -f1)" > "$PACK_FILE"
else
    update_progress "${step}/${TOTAL} 创建迁移包..."
    echo -n "[${step}/${TOTAL}] Creating openclaw-migration-pack.tar.gz (packing...)..."
    tar czf "$PACK_FILE" -C "$TMP_DIR" .
fi
TAR_END=$(date +%s)
echo -e "[${step}/${TOTAL}] Packed in $((TAR_END - TAR_START))s ${GREEN}✅${NC}"

# Clean up tmp
rm -rf "$TMP_DIR"

# ─── [10/11] Generate pack checksum ─────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 生成 SHA256..."
echo -n "[${step}/${TOTAL}] Generating pack SHA256 checksum..."
(cd ~ && sha256sum openclaw-migration-pack.tar.gz > openclaw-migration-pack.sha256)
echo -e " ${GREEN}✅${NC}"

PACK_SIZE=$(du -sh "$PACK_FILE" | cut -f1)

# Copy scripts to home for transfer
cp "$SCRIPT_DIR/setup.sh" ~/setup.sh
chmod +x ~/setup.sh

# ─── [11/11] Copy deploy.sh to home ─────────────────────────────────────────
step=$((step+1))
update_progress "${step}/${TOTAL} 复制 deploy.sh..."
echo -n "[${step}/${TOTAL}] Copying deploy.sh to ~/..."
cp "$SCRIPT_DIR/deploy.sh" ~/deploy.sh
chmod +x ~/deploy.sh
DEPLOY_SIZE=$(du -sh ~/deploy.sh | cut -f1)
echo -e " ${GREEN}✅${NC} (${DEPLOY_SIZE})"

# Generate migration instructions (fallback doc)
echo -n "Generating migration-instructions.md (fallback doc)..."
OLD_USER=$(whoami)
bash "$SCRIPT_DIR/generate-instructions.sh" "$OLD_USER"
echo -e " ${GREEN}✅${NC}"

# ─── Summary ─────────────────────────────────────────────────────────────────
SETUP_SIZE=$(du -sh ~/setup.sh | cut -f1)
INSTR_SIZE=$(du -sh ~/migration-instructions.md 2>/dev/null | cut -f1 || echo "N/A")
CHKSUM_SIZE=$(du -sh ~/openclaw-migration-pack.sha256 | cut -f1)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ Packing complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  📦 产出文件（全部在 ${YELLOW}$HOME/${NC}）:"
echo ""
echo -e "    1. ${YELLOW}openclaw-migration-pack.tar.gz${NC}  ${PACK_SIZE}  ← 主迁移包"
echo -e "    2. ${YELLOW}openclaw-migration-pack.sha256${NC}  ${CHKSUM_SIZE}  ← 校验文件"
echo -e "    3. ${YELLOW}setup.sh${NC}                        ${SETUP_SIZE}  ← 新设备基础环境脚本"
echo -e "    4. ${YELLOW}deploy.sh${NC}                       ${DEPLOY_SIZE}  ← OpenClaw 部署脚本"
echo -e "    5. ${YELLOW}migration-instructions.md${NC}       ${INSTR_SIZE}  ← 手动迁移备用文档"
echo ""
echo -e "  🚀 下一步：传输到新设备"
echo -e "    ${YELLOW}bash $SCRIPT_DIR/transfer.sh USER@NEW_IP${NC}"
echo ""
echo -e "  或手动 scp:"
echo -e "    scp ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256 ~/setup.sh ~/deploy.sh ~/migration-instructions.md USER@NEW_IP:~/"
echo ""

# Mark completion in progress file
update_progress "DONE ✅ 打包完成 (${PACK_SIZE})"
