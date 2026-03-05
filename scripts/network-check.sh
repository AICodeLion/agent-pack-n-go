#!/bin/bash
# network-check.sh - Remote network diagnostics for OpenClaw migration
# Run on target device: ssh USER@HOST 'bash -s' < <SKILL_DIR>/scripts/network-check.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RESULT_FILE="/tmp/openclaw-network-result.txt"

echo ""
echo "========================================"
echo "  OpenClaw Network Diagnostics"
echo "========================================"
echo ""

check_url() {
    local label="$1"
    local url="$2"
    if curl -sS --connect-timeout 5 --max-time 5 "$url" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} ${label}"
        return 0
    else
        echo -e "  ${RED}❌${NC} ${label}"
        return 1
    fi
}

INTERNET_OK=false
ANTHROPIC_OK=false
DISCORD_OK=false
NPM_OK=false

check_url "基础互联网  (curl google.com)"          "https://google.com"                   && INTERNET_OK=true
check_url "Anthropic API (api.anthropic.com)"      "https://api.anthropic.com"            && ANTHROPIC_OK=true
check_url "Discord API  (discord.com)"             "https://discord.com/api/v10/gateway"  && DISCORD_OK=true
check_url "npm registry  (registry.npmjs.org)"     "https://registry.npmjs.org"           && NPM_OK=true

echo ""
echo "========================================"

if $INTERNET_OK && $ANTHROPIC_OK && $DISCORD_OK && $NPM_OK; then
    CONCLUSION="DIRECT"
    echo -e "  ${GREEN}▶ DIRECT: 直连模式，无需代理${NC}"
elif $INTERNET_OK; then
    CONCLUSION="PROXY_NEEDED"
    echo -e "  ${YELLOW}▶ PROXY_NEEDED: 建议配置代理后再部署${NC}"
else
    CONCLUSION="NO_INTERNET"
    echo -e "  ${RED}▶ NO_INTERNET: 无法继续，请检查网络${NC}"
fi

echo "========================================"
echo ""

echo "$CONCLUSION" > "$RESULT_FILE"
echo -e "  结果已写入 ${RESULT_FILE}"
echo ""
