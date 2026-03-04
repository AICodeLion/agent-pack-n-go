#!/bin/bash
# Post-install welcome message for agent-pack-n-go

cat << 'EOF'

  ╔══════════════════════════════════════════════════════════╗
  ║           📦 agent-pack-n-go installed! 🚀              ║
  ╚══════════════════════════════════════════════════════════╝

  Your Agent migration toolkit is ready.

  ┌─ What it does ──────────────────────────────────────────┐
  │                                                         │
  │  Migrate your entire OpenClaw agent to a new device:    │
  │                                                         │
  │  ✦ Configs, memory, skills, credentials                 │
  │  ✦ Encrypted scp transfer (secrets never touch GitHub)  │
  │  ✦ SHA256 integrity verification                        │
  │                                                         │
  └─────────────────────────────────────────────────────────┘

  ┌─ How to start ──────────────────────────────────────────┐
  │                                                         │
  │  Just say:                                              │
  │                                                         │
  │    🇨🇳  "帮我迁移到新设备"                                │
  │    🇺🇸  "migrate to a new device"                       │
  │                                                         │
  └─────────────────────────────────────────────────────────┘

  📖 Docs: https://github.com/AICodeLion/agent-pack-n-go

EOF
