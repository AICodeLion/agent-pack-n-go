---
name: agent-pack-n-go
description: >
  Migrate OpenClaw + Claude Code from one Linux device to another.
  Triggers: '帮我迁移', '搬到新设备', 'migrate device', 'device move', '设备搬家', 'pack and go'.
  Agent packs configs, memory, skills, credentials on old device, transfers via encrypted scp, and auto-deploys on new device via SSH remote control.
  POST-INSTALL: After installing, tell the user: "✅ agent-pack-n-go 安装成功！这个 Skill 可以把你的 OpenClaw Agent 一键迁移到新的 Linux 设备，包括配置、记忆、技能、密钥等全部自动恢复。使用方法：对我说「帮我迁移到新设备」即可开始。"
---

# agent-pack-n-go 📦🚀

Migrate OpenClaw + Claude Code to a new device. Agent handles everything via SSH remote control — user only needs to confirm steps.

## Post-Install

The `description` field above contains the post-install message. Show it to the user after installation.

Fallback: if unsure what to say, run `bash scripts/welcome.sh` in the skill directory.

## Overview

```
Old Device (Agent controls everything)    New Device (SSH remote)
┌──────────────────────────────────┐      ┌─────────────────────────┐
│ 1. Pre-flight: ask IP + SSH user │      │                         │
│ 2. pack.sh (pack configs)        │      │                         │
│ 3. transfer.sh USER@HOST ────────┼─────→│ files arrive            │
│ 4. ssh USER@HOST 'bash setup.sh' │─────→│ (base env + Claude)     │
│ 5. ssh USER@HOST 'bash deploy.sh'│─────→│ (openclaw deployed)     │
│ 6. Verify → stop old OpenClaw    │      │ ✅ New device running   │
└──────────────────────────────────┘      └─────────────────────────┘
```

## Execution Flow

### Real-time Progress Feedback

All scripts write progress to `/tmp/openclaw-{pack,transfer,deploy}-progress.txt`.
When running scripts (locally or remotely), poll the progress file and send updates to the user:

```bash
# Example: run pack.sh in background, poll progress every 3s
bash <SKILL_DIR>/scripts/pack.sh &
while true; do
    progress=$(cat /tmp/openclaw-pack-progress.txt 2>/dev/null)
    # Send to user if changed
    [[ "$progress" == DONE* ]] && break
    sleep 3
done

# Example: poll deploy progress on remote host
while true; do
    progress=$(ssh USER@HOST 'cat /tmp/openclaw-deploy-progress.txt 2>/dev/null')
    [[ "$progress" == DONE* ]] && break
    sleep 3
done
```

This way the user sees step-by-step updates in the chat (Discord/Feishu/etc.) instead of silence.

---

### Phase 1: Pre-flight Check

Ask user for:
1. **New device IP** + SSH user
2. **New device password** (only used once for SSH key setup)
3. **New device OS** (must be Ubuntu 22.04/24.04)
4. **Confirm**: 2-core CPU, 2GB+ RAM

Warn user:
- ⚠️ Discord Bot will be offline for ~5-10 min during switch (same token can't run on two devices)
- ⚠️ Migration pack contains sensitive data (API keys, tokens) — transferred via scp (encrypted)

#### 1.1 Set up SSH key auth (user action required)

Ask user to run this command **in their own terminal** on the old device:

```bash
ssh-copy-id USER@NEW_IP
```

This will prompt for the new device password **once**. After that, all SSH operations are password-free.

> **Why user must do this manually:** `ssh-copy-id` requires interactive password input. The agent cannot safely handle passwords in automated scripts.

#### 1.2 Verify SSH connectivity

```bash
ssh USER@HOST 'echo ok'
```

If this prompts for a password → `ssh-copy-id` didn't work, ask user to retry.
If this fails entirely → stop and ask user to check SSH access, keys, and firewall.

#### 1.3 Set up passwordless sudo (recommended)

Several migration steps need `sudo` (system packages, /etc/hosts, proxychains4, systemd linger). Without passwordless sudo, these steps will be **skipped** and require manual fix later.

Ask user to run:

```bash
ssh USER@NEW_IP 'echo "USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/migration'
```

(Replace `USERNAME` with the actual SSH user. This will prompt for password one last time.)

> **Security note:** After migration is verified (Phase 4), user can remove this with:
> `ssh USER@NEW_IP 'sudo rm /etc/sudoers.d/migration'`

---

### Phase 2: Prepare Old Server

#### 2.1 Run pack script

```bash
bash <SKILL_DIR>/scripts/pack.sh
```

This creates: `~/openclaw-migration-pack.tar.gz`, `~/setup.sh`, `~/deploy.sh`, `~/migration-instructions.md`

See `scripts/pack.sh` for details.

#### 2.2 Transfer to new device

```bash
bash <SKILL_DIR>/scripts/transfer.sh USER@HOST
```

Transfers all files (pack + scripts) to new device home directory. Verifies SHA256 checksum after transfer.

---

### Phase 3: Remote Deploy

**This phase is fully automated — agent runs everything via SSH.**

#### 3.1 Install base environment + Claude Code

```bash
ssh USER@HOST 'bash ~/setup.sh'
```

`setup.sh` installs: nvm, Node.js 22, npm globals, Claude Code. Has spinner + progress output.

Poll remote progress during execution:
```bash
ssh USER@HOST 'cat /tmp/openclaw-setup-progress.txt 2>/dev/null'
```

Check exit code — if non-zero, report failure to user and stop.

#### 3.2 Deploy OpenClaw

```bash
ssh USER@HOST 'bash ~/deploy.sh'
```

`deploy.sh` handles all 12 deployment steps:
1. Extract migration pack
2. npm install openclaw + mcporter
3. Restore ~/.openclaw/ config
4. Fix paths (if username changed)
5. Restore /etc/hosts
6. Restore crontab
7. Configure proxychains4
8. Check/fix Claude Code nvm wrapper
9. Start OpenClaw Gateway + systemd + linger
10. Restore Dashboard (optional)
11. Check logs for connectivity
12. Cleanup temp files

Poll remote progress during execution:
```bash
ssh USER@HOST 'cat /tmp/openclaw-deploy-progress.txt 2>/dev/null'
```

Check exit code and FAILED_STEPS in output — report any issues to user.

#### 3.3 Verify OpenClaw is running

```bash
ssh USER@HOST 'openclaw gateway status'
```

If status shows running/active → proceed to Phase 4.
If not running → skip to **Phase 5: Fallback**.

---

### Phase 4: Verify & Switch

#### 4.1 Check logs on new device

```bash
ssh USER@HOST 'journalctl --user -u openclaw-gateway --no-pager -n 50'
```

Look for Discord/Feishu connection confirmation.

#### 4.2 Confirm connectivity

Ask user to:
1. Send a message in Discord → should get reply
2. Send a message in Feishu → should get reply
3. Check memory: ask agent "do you remember who I am"

#### 4.3 Stop old device OpenClaw

⚠️ Only after user confirms new device is working:

```bash
systemctl --user stop openclaw-gateway
```

Tell user: "✅ Migration complete! New device is now running OpenClaw."

---

### Phase 5: Fallback

If new device OpenClaw did not start correctly:

1. Ask user to SSH to new device and run Claude Code for diagnosis:
   ```bash
   ssh USER@HOST
   claude '帮我排查 OpenClaw 为什么没起来，检查日志和配置'
   ```

2. If diagnosis fails or user wants to roll back → restart old device:
   ```bash
   # On old device
   systemctl --user start openclaw-gateway
   ```

3. Tell user: "Old device restored. New device deployment failed — please check logs and retry."

> **Note**: `scripts/generate-instructions.sh` generates `~/migration-instructions.md` as a fallback manual guide.
> If full automation fails, user can SSH to new device and follow the document manually.

---

### Phase 6: Cleanup

After 3-7 days of stable operation on new device:

```bash
# On new device: remove migration files
rm ~/openclaw-migration-pack.tar.gz ~/setup.sh ~/deploy.sh ~/migration-instructions.md

# On old device: disable service
systemctl --user disable openclaw-gateway
```

---

## Troubleshooting

See `references/troubleshooting.md` for common issues and solutions.
