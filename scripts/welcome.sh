#!/bin/bash
# Post-install welcome message for agent-pack-n-go

cat << 'EOF'
✅ agent-pack-n-go installed successfully!

📦 This skill migrates your entire OpenClaw agent to a new Linux device:
   - Configs, memory, skills, credentials — everything transfers seamlessly
   - All sensitive data via encrypted scp (never touches GitHub)
   - SHA256 integrity verification

🚀 To start a migration, just say:
   - "帮我迁移到新设备"
   - "migrate to a new device"

📖 Full docs: https://github.com/AICodeLion/agent-pack-n-go
EOF
