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
echo -n "[${step}/${TOTAL}] Packing ~/.openclaw/ config..."
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
    echo -e " ${YELLOW}⚠️  ~/.openclaw/ not found, skipping${NC}"
fi

# ─── [2/8] Pack ~/.claude/ ───────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Packing ~/.claude/ (Claude Code config)..."
if [ -d ~/.claude ]; then
    cp -r ~/.claude/. "$TMP_DIR/claude-config/"
    echo -e " ${GREEN}✅${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/.claude/ not found, skipping${NC}"
fi

# ─── [3/8] Pack ~/.ssh/ ──────────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Packing ~/.ssh/ (SSH keys)..."
if [ -d ~/.ssh ]; then
    cp -r ~/.ssh/. "$TMP_DIR/ssh-keys/"
    echo -e " ${GREEN}✅${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/.ssh/ not found, skipping${NC}"
fi

# ─── [4/8] Export crontab ────────────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Exporting crontab..."
if crontab -l > "$TMP_DIR/crontab-backup.txt" 2>/dev/null; then
    echo -e " ${GREEN}✅${NC}"
else
    echo "# no crontab" > "$TMP_DIR/crontab-backup.txt"
    echo -e " ${YELLOW}⚠️  crontab is empty, created empty file${NC}"
fi

# ─── [5/8] Export /etc/hosts custom entries ──────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Exporting /etc/hosts custom entries (discord|cdn)..."
grep -Ei 'discord|cdn' /etc/hosts > "$TMP_DIR/hosts-custom.txt" 2>/dev/null || true
if [ -s "$TMP_DIR/hosts-custom.txt" ]; then
    echo -e " ${GREEN}✅${NC}"
else
    echo "# no custom entries" > "$TMP_DIR/hosts-custom.txt"
    echo -e " ${YELLOW}⚠️  No discord/cdn entries found, created empty file${NC}"
fi

# ─── [6/8] Pack Dashboard (optional) ────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Checking ~/openclaw-dashboard/..."
if [ -d ~/openclaw-dashboard ]; then
    cp -r ~/openclaw-dashboard "$TMP_DIR/dashboard"
    echo -e " ${GREEN}✅ Packed${NC}"
else
    echo -e " ${YELLOW}⚠️  ~/openclaw-dashboard/ not found, skipping${NC}"
fi

# ─── [7/8] Record old username ───────────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Recording old device username..."
whoami > "$TMP_DIR/old_user.txt"
echo -e " ${GREEN}✅ ($(cat "$TMP_DIR/old_user.txt"))${NC}"

# ─── [8/10] Generate manifest checksum ───────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Generating critical file checksums (manifest.sha256)..."
cd "$TMP_DIR"
MANIFEST_FILES=""
for f in openclaw-config/openclaw.json claude-config/settings.json ssh-keys/id_ed25519 crontab-backup.txt; do
    if [ -f "$f" ]; then
        MANIFEST_FILES="$MANIFEST_FILES $f"
    fi
done
if [ -n "$MANIFEST_FILES" ]; then
    sha256sum $MANIFEST_FILES > manifest.sha256
    echo -e " ${GREEN}✅ ($(wc -l < manifest.sha256) files)${NC}"
else
    echo "# no critical files found" > manifest.sha256
    echo -e " ${YELLOW}⚠️  No critical files found${NC}"
fi
cd ~

# ─── [9/10] Create tarball ───────────────────────────────────────────────────
step=$((step+1))
TAR_START=$(date +%s)
if command -v pv > /dev/null 2>&1; then
    echo "[${step}/${TOTAL}] Creating openclaw-migration-pack.tar.gz (pv)..."
    tar cz -C "$TMP_DIR" . | pv -s "$(du -sb "$TMP_DIR" | cut -f1)" > "$PACK_FILE"
else
    echo -n "[${step}/${TOTAL}] Creating openclaw-migration-pack.tar.gz (packing...)..."
    tar czf "$PACK_FILE" -C "$TMP_DIR" .
fi
TAR_END=$(date +%s)
echo -e "[${step}/${TOTAL}] Packed in $((TAR_END - TAR_START))s ${GREEN}✅${NC}"

# Clean up tmp
rm -rf "$TMP_DIR"

# ─── [10/10] Generate pack checksum ─────────────────────────────────────────
step=$((step+1))
echo -n "[${step}/${TOTAL}] Generating pack SHA256 checksum..."
sha256sum "$PACK_FILE" > ~/openclaw-migration-pack.sha256
echo -e " ${GREEN}✅${NC}"

PACK_SIZE=$(du -sh "$PACK_FILE" | cut -f1)

# Copy scripts to home for transfer
cp "$(dirname "$0")/setup.sh" ~/setup.sh
chmod +x ~/setup.sh

# Generate migration instructions
echo -n "Generating migration-instructions.md..."
OLD_USER=$(whoami)
bash "$(dirname "$0")/generate-instructions.sh" "$OLD_USER"
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
echo -e "    3. ${YELLOW}setup.sh${NC}                        ${SETUP_SIZE}  ← 新设备一键部署脚本"
echo -e "    4. ${YELLOW}migration-instructions.md${NC}       ${INSTR_SIZE}  ← Claude Code 迁移指令"
echo ""
echo -e "  🚀 下一步：传输到新设备"
echo -e "    ${YELLOW}bash $(dirname "$0")/transfer.sh USER@NEW_IP${NC}"
echo ""
echo -e "  或手动 scp:"
echo -e "    scp ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256 ~/setup.sh ~/migration-instructions.md USER@NEW_IP:~/"
echo ""
