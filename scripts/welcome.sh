#!/bin/bash
# Post-install welcome message for agent-pack-n-go

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "  ${GREEN}${BOLD}✔ agent-pack-n-go${NC}  installed"
echo ""
echo -e "  ${BOLD}One-click migration for your OpenClaw agent.${NC}"
echo -e "  ${DIM}Configs · Memory · Skills · Credentials — all transferred securely.${NC}"
echo ""
echo -e "  ${CYAN}What gets migrated${NC}"
echo -e "    ~/.openclaw/     configs, workspace, skills, memory"
echo -e "    ~/.claude/       Claude Code settings & OAuth"
echo -e "    ~/.ssh/          SSH keys (auto-fixed to 600)"
echo -e "    crontab          scheduled tasks (paths auto-corrected)"
echo ""
echo -e "  ${CYAN}Security${NC}"
echo -e "    🔒 Encrypted scp transfer · SHA256 integrity checks"
echo -e "    ${DIM}API keys, bot tokens, SSH keys — never touch GitHub${NC}"
echo ""
echo -e "  ${YELLOW}Get started${NC}"
echo -e "    Say ${BOLD}\"帮我迁移到新设备\"${NC} or ${BOLD}\"migrate to a new device\"${NC}"
echo ""
echo -e "  ${DIM}📖 https://github.com/AICodeLion/agent-pack-n-go${NC}"
echo ""
