---
name: agent-pack-n-go
description: >
  Migrate OpenClaw + Claude Code from one Linux device to another.
  Triggers: '帮我迁移', '搬到新设备', 'migrate device', 'device move', '设备搬家', 'pack and go'.
  Agent packs configs, memory, skills, credentials on old device, transfers via encrypted scp, and auto-deploys on new device.
  POST-INSTALL: After installing this skill, tell the user —
  "✅ agent-pack-n-go installed! To start a migration, say: 帮我迁移到新设备 or migrate to a new device. I'll handle packing, secure transfer, and one-click deployment."
---

# agent-pack-n-go 📦🚀

Migrate OpenClaw + Claude Code to a new device. Agent packs everything, user runs one command on the new device.

## Post-Install

After installing this skill, **run the welcome script** to show the user what it does and how to use it:

```bash
bash ~/.openclaw/skills/agent-pack-n-go/scripts/welcome.sh
```

Always run this script after installation — it provides the user with a brief introduction and trigger commands.

## Overview

```
Old Device (Agent auto)          New Device (One-click deploy)
┌─────────────────────┐          ┌─────────────────────┐
│ 1. Check Claude Code│          │ 3. bash setup.sh    │
│ 2. Pack + scp ──────┼─────────→│ 4. claude "migrate" │
│    (stop old)       │          │    (auto completes) │
└─────────────────────┘          └─────────────────────┘
                                          ↓
                                 User verifies ✅
```

## Execution Flow

### Phase 1: Pre-flight Check

Ask user for:
1. **New device IP** + SSH user + password/key
2. **New device OS** (must be Ubuntu 22.04/24.04)
3. **Confirm**: 2-core CPU, 2GB+ RAM

Warn user:
- ⚠️ Discord Bot will be offline for ~5-10 min during switch (same token can't run on two devices)
- ⚠️ Migration pack contains sensitive data (API keys, tokens) — transferred via scp (encrypted)

### Phase 2: Prepare Old Server

#### 2.1 Ensure Claude Code is available

```bash
# Check if Claude Code exists
which claude
```

- **Found** → verify it works: `claude --version` → proceed to 2.2
- **Not found** → install it:

```bash
npm install -g @anthropic-ai/claude-code
```

Then ask user for API config (provider URL + API key), write to `~/.claude/settings.json`, and test:

```bash
claude "hello test"
```

#### 2.2 Run pack script

```bash
bash <SKILL_DIR>/scripts/pack.sh
```

This creates `~/openclaw-migration-pack.tar.gz` + `~/setup.sh` + `~/migration-instructions.md`

See `scripts/pack.sh` for details.

#### 2.3 Transfer to new device

```bash
scp ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256 ~/setup.sh ~/migration-instructions.md USER@NEW_IP:~/
```

#### 2.4 Stop old device

⚠️ Only after confirming scp completed successfully:

```bash
systemctl --user stop openclaw-gateway
```

Tell user: "Old device stopped. SSH to new device and run: `bash ~/setup.sh`"

### Phase 3: New Device (One-click deploy)

User SSHs to new device and runs:

```bash
# Command 1: Install base environment + restore Claude Code config
bash ~/setup.sh

# Command 2: Let Claude Code handle the rest
claude --dangerously-skip-permissions "Read ~/migration-instructions.md and follow every step to complete the OpenClaw migration. Report progress as you go."
```

### Phase 4: Verification

After Claude Code finishes, tell user to verify:

1. Send a message in Discord → should get reply
2. Send a message in Feishu → should get reply
3. Check memory: ask agent "do you remember who I am"
4. Check crontab: `crontab -l`

If verification fails → **rollback**: restart old device's OpenClaw:
```bash
# On old device
systemctl --user start openclaw-gateway
```

### Phase 5: Cleanup

After 3-7 days of stable operation on new device:

```bash
# On new device: remove migration files
rm ~/openclaw-migration-pack.tar.gz ~/setup.sh ~/migration-instructions.md

# On old device: disable service
systemctl --user disable openclaw-gateway
```

## Troubleshooting

See `references/troubleshooting.md` for common issues and solutions.
