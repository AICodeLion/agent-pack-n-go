---
name: agent-pack-n-go
description: "Migrate OpenClaw + Claude Code from one server to another with minimal user effort. Use when: (1) user wants to move/migrate/relocate their OpenClaw to a new server, (2) user says '帮我迁移', '搬到新服务器', 'migrate server', 'server move', '服务器搬家', 'pack and go'. Agent handles packing, transferring, and guiding deployment — user only runs 2 commands on the new server."
---

# agent-pack-n-go 📦🚀

Migrate OpenClaw + Claude Code to a new server. Agent packs everything, user runs 2 commands on the new server.

## Overview

```
Old Server (Agent auto)          New Server (User 2 commands)
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
1. **New server IP** + SSH user + password/key
2. **New server OS** (must be Ubuntu 22.04/24.04)
3. **Confirm**: 2-core CPU, 8GB+ RAM

Warn user:
- ⚠️ Discord Bot will be offline for ~5-10 min during switch (same token can't run on two servers)
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

#### 2.3 Transfer to new server

```bash
scp ~/openclaw-migration-pack.tar.gz ~/openclaw-migration-pack.sha256 ~/setup.sh ~/migration-instructions.md USER@NEW_IP:~/
```

#### 2.4 Stop old server

⚠️ Only after confirming scp completed successfully:

```bash
systemctl --user stop openclaw-gateway
```

Tell user: "Old server stopped. SSH to new server and run: `bash ~/setup.sh`"

### Phase 3: New Server (User runs 2 commands)

User SSHs to new server and runs:

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

If verification fails → **rollback**: restart old server's OpenClaw:
```bash
# On old server
systemctl --user start openclaw-gateway
```

### Phase 5: Cleanup

After 3-7 days of stable operation on new server:

```bash
# On new server: remove migration files
rm ~/openclaw-migration-pack.tar.gz ~/setup.sh ~/migration-instructions.md

# On old server: disable service
systemctl --user disable openclaw-gateway
```

## Troubleshooting

See `references/troubleshooting.md` for common issues and solutions.
