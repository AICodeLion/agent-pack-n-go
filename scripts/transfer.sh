#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default files to transfer
FILES=(
    ~/openclaw-migration-pack.tar.gz
    ~/openclaw-migration-pack.sha256
    ~/setup.sh
    ~/deploy.sh
    ~/migration-instructions.md
)

usage() {
    echo "Usage: $0 USER@HOST [file1 file2 ...]"
    echo "  Default files: ${FILES[*]}"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

TARGET="$1"
shift

PROGRESS_FILE="/tmp/openclaw-transfer-progress.txt"
update_progress() { echo "$1" > "$PROGRESS_FILE"; }

# Override file list if provided
if [ $# -gt 0 ]; then
    FILES=("$@")
fi

# Expand ~ in file paths
EXPANDED_FILES=()
for f in "${FILES[@]}"; do
    expanded="${f/#\~/$HOME}"
    EXPANDED_FILES+=("$expanded")
done

echo ""
echo "========================================"
echo "  Agent Clone Transfer"
echo "========================================"
echo ""

# Check files exist & build file list display
MISSING=0
echo -e "  📂 源文件："
for f in "${EXPANDED_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo -e "    ${RED}✗ $(basename "$f")  ← 不存在!${NC}"
        MISSING=$((MISSING + 1))
    else
        fsize=$(du -sh "$f" | cut -f1)
        echo -e "    ${GREEN}✓${NC} $(basename "$f")  (${fsize})"
    fi
done
echo ""
if [ "$MISSING" -gt 0 ]; then
    echo -e "${RED}❌ $MISSING 个文件缺失，中止传输。${NC}"
    exit 1
fi

# Show total size & destination
TOTAL_SIZE=$(du -shc "${EXPANDED_FILES[@]}" 2>/dev/null | tail -1 | cut -f1)
echo -e "  📦 总大小: ${YELLOW}${TOTAL_SIZE}${NC}"
echo -e "  🎯 目标:   ${YELLOW}${TARGET}:~/${NC}"
echo ""

update_progress "传输中 → ${TARGET} (${TOTAL_SIZE})..."

# ─── Transfer ────────────────────────────────────────────────────────────────
T_START=$(date +%s)

if command -v rsync > /dev/null 2>&1; then
    echo -e "${GREEN}Using rsync (with progress)...${NC}"
    echo ""
    rsync -avz --progress "${EXPANDED_FILES[@]}" "${TARGET}:~/"
    TRANSFER_METHOD="rsync"
else
    echo -e "${YELLOW}rsync not found, using scp...${NC}"
    echo ""
    scp "${EXPANDED_FILES[@]}" "${TARGET}:~/"
    TRANSFER_METHOD="scp"
fi

T_END=$(date +%s)
ELAPSED=$((T_END - T_START))

echo ""
echo -e "${GREEN}✅ Transfer complete (${TRANSFER_METHOD}, ${ELAPSED}s)${NC}"
echo ""

update_progress "校验中..."

# ─── SHA256 verification on remote ──────────────────────────────────────────
echo -n "Verifying SHA256 on remote..."

REMOTE_USER="${TARGET%%@*}"
REMOTE_HOST="${TARGET##*@}"

VERIFY_OUTPUT=$(ssh "${TARGET}" "cd ~ && sha256sum -c openclaw-migration-pack.sha256 --status 2>/dev/null && echo OK || echo FAIL" 2>/dev/null || echo "SSH_FAIL")

if [ "$VERIFY_OUTPUT" = "OK" ]; then
    echo -e " ${GREEN}✅ Checksum verified${NC}"
elif [ "$VERIFY_OUTPUT" = "SSH_FAIL" ]; then
    echo -e " ${YELLOW}⚠️  Could not verify via SSH (check manually: sha256sum -c ~/openclaw-migration-pack.sha256)${NC}"
else
    echo -e " ${RED}❌ Checksum mismatch! Transfer may be corrupted. Re-run this script.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================"
echo -e "  Transfer complete!"
echo -e "========================================${NC}"
echo ""
echo "  Next: agent will run remotely:"
echo -e "    ${YELLOW}ssh ${TARGET} 'bash ~/setup.sh'${NC}"
echo -e "    ${YELLOW}ssh ${TARGET} 'bash ~/deploy.sh'${NC}"
echo ""

update_progress "DONE ✅ 传输完成 (${TRANSFER_METHOD}, ${ELAPSED}s)"
