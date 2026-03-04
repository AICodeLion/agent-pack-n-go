# OpenClaw Server Migration Operations Manual (Full Version)

> **Goal**: Fully migrate OpenClaw + Claude Code from an old server to a new Ubuntu server
> **Principle**: User performs minimal manual operations; everything else is handled by the Agent
> **Prerequisite**: Old server already has a running OpenClaw instance

---

## Overview: Full Migration Flow

```
Phase 1: Pre-migration checks
Phase 2: Old server preparation (Agent handles)
Phase 3: New server deployment (User: 2 commands + Claude Code auto)
Phase 4: Verification + switchover
Phase 5: Cleanup
```

### Who does what

| Step | Executor | User action |
|------|----------|-------------|
| Pre-migration checks | 🦁 Agent | Answer a few questions |
| Check/install Claude Code | 🦁 Agent | Provide API info (if needed) |
| Pack + transfer | 🦁 Agent | Provide new server SSH info |
| New server setup | 👤 User | Run 1 command: `bash ~/setup.sh` |
| Install OpenClaw + restore | 🤖 Claude Code | Run 1 command to start Claude Code |
| Verification | 👤 User | Send test messages |
| Cleanup | 👤 User | Shut down old server after confirmation |

---

## Phase 1: Pre-migration Checks

> Purpose: Confirm migration conditions are met, avoid getting stuck midway

### 1.1 New server requirements

- [ ] **Operating system**: Ubuntu 22.04 / 24.04 (recommended)
- [ ] **Resources**: 2-core CPU, 2GB+ RAM
- [ ] **SSH access**: User with root or sudo privileges
- [ ] **Network**:
  - Can access npm registry (npmmirror available for China networks)
  - Can access your AI API provider (third-party proxies don't need VPN)
  - If using Discord: proxy/VPN required

### 1.2 Information to prepare

| Info | Description | Example |
|------|-------------|---------|
| New server IP | For SSH login | 1.2.3.4 |
| SSH username | User on new server | admin / root / ubuntu |
| SSH password or key | Login credentials | Password or .pem file |
| API info (if needed) | Claude Code API proxy URL + Key | Only needed if old server lacks Claude Code |

### 1.3 Important notices

⚠️ **Discord Bot cannot run on two servers simultaneously**
- The same Bot Token can only have one active instance
- You must stop the old server before starting the new one
- There will be a brief offline period (~5-10 minutes)

⚠️ **Sensitive data security**
- The migration pack contains API Keys, Bot Tokens, and other sensitive data
- Transfer uses scp (encrypted channel), not public channels
- Clean up migration pack files on the new server after migration

---

## Phase 2: Old Server Preparation (🦁 Agent handles)

> User tells Agent: "Help me prepare for migration", Agent automatically completes all steps below

### 2.1 Check/install Claude Code

Agent automatically checks whether Claude Code is installed:

**✅ Installed** → Verify it works, proceed to 2.2

**❌ Not installed** → Agent automatically runs:

```bash
# 1. Install
npm install -g @anthropic-ai/claude-code

# 2. Agent asks user for API info:
#    - API proxy URL (e.g. https://api.fluxnode.org)
#    - API Key
#    User replies via Discord/Feishu

# 3. Agent writes config
# ~/.claude/settings.json

# 4. Agent tests
claude "hello test"
# → Success: tells user "Claude Code is ready ✅"
# → Failure: troubleshoot and ask user again
```

> 👤 User action: Only need to provide API info (if Claude Code is not installed)

### 2.2 Pack migration files

Agent automatically creates a migration pack containing:

```
~/openclaw-migration-pack.tar.gz
│
├── openclaw-config/                → Restored to ~/.openclaw/
│   ├── openclaw.json               ← Core config (API Keys, channel tokens, model settings, etc.)
│   ├── credentials/                ← Discord/Feishu auth files
│   ├── skills/                     ← Installed Agent Skills
│   │   ├── agent-reach/
│   │   ├── capability-evolver/
│   │   └── skill-vetter/
│   ├── extensions/                 ← Installed plugins
│   │   └── openclaw-tavily/
│   ├── memory/                     ← Memory database (main.sqlite, etc.)
│   ├── feishu/                     ← Feishu-related files
│   ├── workspace/                  ← Workspace (notes, memory, scripts, tasks, etc.)
│   ├── workspace-coder/            ← Sub-agent workspace
│   ├── workspace-paper-tracker/    ← Sub-agent workspace
│   ├── CLAUDE.md                   ← Agent instruction file
│   └── exec-approvals.json         ← Approved execution permissions
│
├── claude-config/                  → Restored to ~/.claude/
│   ├── settings.json               ← API config
│   ├── projects/                   ← Project configs
│   └── ...
│
├── ssh-keys/                       → Restored to ~/.ssh/
│   ├── id_ed25519                  ← Private key (for git push, etc.)
│   ├── id_ed25519.pub
│   ├── config
│   └── known_hosts
│
├── crontab-backup.txt              ← Scheduled task backup
├── hosts-custom.txt                ← /etc/hosts custom entries
│
└── dashboard/                      → Restored to ~/openclaw-dashboard/ (optional)
    ├── backend/
    ├── frontend/
    └── ...
```

### 2.3 Generate auxiliary files

Agent automatically generates two key files:

**① `setup.sh` — One-click install script for new server**

Functions:
- Install nvm + Node.js 22
- Configure npm global path `~/.npm-global`
- Install Claude Code
- Restore `~/.claude/` config from migration pack
- Restore `~/.ssh/` keys from migration pack (permissions set to 600)
- Verify Claude Code is functional
- Install base dependencies (git, curl, python3, etc.)

**② `migration-instructions.md` — Migration instructions for Claude Code**

Contents: All migration steps Claude Code needs to execute (see Phase 3)

### 2.4 Transfer to new server

After user provides new server SSH info, Agent runs:

```bash
scp ~/openclaw-migration-pack.tar.gz \
    ~/setup.sh \
    ~/migration-instructions.md \
    username@new-server-ip:~/
```

> 👤 User action: Provide new server IP + SSH username + password/key

### 2.5 Stop old server OpenClaw

⚠️ **Important**: Stop the old server before starting the new one to avoid Discord Bot conflicts

```bash
# Agent runs this after confirming file transfer is complete
systemctl --user stop openclaw-gateway
```

Agent will tell user: "Old server stopped. Please run setup.sh on the new server."


---

## Phase 3: New Server Deployment

### Step 1: Run setup script 👤

SSH to the new server and run one command:

```bash
bash ~/setup.sh
```

Script execution (fully automatic, ~5 minutes):

```
[1/7] Installing nvm...                    ✅
[2/7] Installing Node.js 22...             ✅
[3/7] Configuring npm global path...       ✅
[4/7] Installing Claude Code...            ✅
[5/7] Restoring Claude Code config...      ✅
[6/7] Restoring SSH keys...                ✅
[7/7] Verifying Claude Code...             ✅

✅ Base environment ready! Run next step:
claude --dangerously-skip-permissions "Follow ~/migration-instructions.md to complete the OpenClaw migration"
```

> If a step fails, the script will stop and display an error message.
> Common issue: npm download slow → set China mirror (script auto-detects and prompts)

### Step 2: Let Claude Code complete the migration 👤

```bash
claude --dangerously-skip-permissions "Follow ~/migration-instructions.md to complete the OpenClaw migration"
```

Claude Code will automatically complete all the following steps based on `migration-instructions.md`:

#### 3.1 Install OpenClaw and tools

```bash
npm install -g openclaw
npm install -g mcporter
# Verify
which openclaw  # ~/.npm-global/bin/openclaw
```

#### 3.2 Restore OpenClaw config

```bash
# Extract migration pack
tar xzf ~/openclaw-migration-pack.tar.gz -C ~/migration-tmp/

# Restore ~/.openclaw/ directory
cp -r ~/migration-tmp/openclaw-config/* ~/.openclaw/
# Note: do not overwrite newly installed OpenClaw program files (node_modules, etc.)
```

#### 3.3 Fix paths

Check new server username; if different from old server:

```bash
OLD_USER="admin"  # Old server username
NEW_USER=$(whoami)

if [ "$OLD_USER" != "$NEW_USER" ]; then
    # Bulk-replace paths in openclaw.json
    sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/openclaw.json
    
    # Replace paths in crontab
    sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/migration-tmp/crontab-backup.txt
fi
```

#### 3.4 Restore system config

```bash
# /etc/hosts — Discord CDN resolution (needed for China servers)
sudo tee -a /etc/hosts < ~/migration-tmp/hosts-custom.txt

# crontab — restore scheduled tasks
crontab ~/migration-tmp/crontab-backup.txt

# Install proxychains4
sudo apt install -y proxychains4
# Configure /etc/proxychains4.conf
```

#### 3.5 Deploy proxy service

> For services that need a proxy (Discord, etc.)
> Claude Code will deploy the same proxy setup as the old server based on its config

```bash
# Install proxy software
# Configure proxy rules
# Start proxy service
# Verify 127.0.0.1:10808 is available
```

#### 3.6 Check Claude Code nvm wrapper

```bash
# Check if ~/.npm-global/bin/claude is an nvm wrapper
# If npm install overwrote it with a direct link, rebuild it
# The wrapper ensures Node 22 from nvm is used instead of the system's old version
```

#### 3.7 Start OpenClaw

```bash
# Start
openclaw gateway start

# Configure systemd autostart
# (use openclaw's bundled service file, or restore from migration pack)
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway
systemctl --user start openclaw-gateway

# Prevent service from being killed after SSH logout
sudo loginctl enable-linger $USER
```

#### 3.8 Restore Dashboard (optional)

```bash
# If migration pack contains dashboard
cp -r ~/migration-tmp/dashboard/ ~/openclaw-dashboard/
pip3 install -r ~/openclaw-dashboard/backend/requirements.txt
# Configure systemd service
```

#### 3.9 Check logs

```bash
# Check OpenClaw logs
journalctl --user -u openclaw-gateway --no-pager -n 50

# Confirm channel connection status
# - Discord: look for "discord connected" or similar in logs
# - Feishu: look for Feishu long-connection established in logs
```

#### 3.10 Clean up migration files

```bash
# Clean up sensitive files after migration
rm -rf ~/migration-tmp/
rm ~/openclaw-migration-pack.tar.gz
rm ~/setup.sh
# migration-instructions.md can be kept for reference
```


---

## Phase 4: Verification 👤

### 4.1 Basic verification

| Check | Method | Expected result |
|-------|--------|-----------------|
| OpenClaw running | `openclaw gateway status` | Shows running |
| Discord send/receive | Send message in Discord | Agent replies normally |
| Feishu send/receive | Send message in Feishu | Agent replies normally |
| Memory intact | Ask Agent "do you remember who I am" | Agent recalls user info |
| Scheduled tasks | `crontab -l` | Shows all scheduled tasks |
| Claude Code | `claude "test"` | Normal conversation |
| Git push | `cd ~/.openclaw/workspace && git push` | Push succeeds |

### 4.2 Advanced verification (optional)

- [ ] Heartbeat working (wait one heartbeat cycle, check if triggered)
- [ ] Dashboard accessible (if applicable)
- [ ] Sub-agents functional (trigger a task requiring Claude Code in Discord)
- [ ] Auto git commits working (wait one cycle or trigger script manually)

### 4.3 What to do if verification fails

**Rollback plan**: Restart OpenClaw on the old server

```bash
# On old server
systemctl --user start openclaw-gateway
```

The old server's data is completely untouched and can be rolled back at any time.

---

## Phase 5: Cleanup

### 5.1 Observation period

- Run new server for **3-7 days** to confirm stability
- Watch for:
  - Occasional channel message loss
  - All scheduled tasks triggering correctly
  - Normal memory/CPU usage
  - Any unusual errors in logs

### 5.2 Shut down old server

After confirming stability:

```bash
# On old server
systemctl --user stop openclaw-gateway
systemctl --user disable openclaw-gateway

# Optional: clean up migration pack from old server
rm ~/openclaw-migration-pack.tar.gz
```

### 5.3 Update records

- Update MEMORY.md to record the migration event
- Update server info in TOOLS.md (new IP, etc.)
- If Dashboard is present, update security group/firewall rules

---

## ⚠️ Known Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Anthropic API 403 | Anthropic blocks direct China IP connections | Use a third-party API proxy (change baseUrl) |
| Claude Code fails to start | npm install overwrote the nvm wrapper | Rebuild the bash wrapper script |
| Discord images fail to load | CDN DNS resolution failure | Add Discord CDN static entries to /etc/hosts |
| workspace path errors | Different username on old/new server | Use sed to bulk-replace paths in openclaw.json |
| git push fails | SSH key permissions wrong | `chmod 600 ~/.ssh/id_ed25519` |
| Service dies after SSH logout | systemd user session terminated | `sudo loginctl enable-linger $USER` |
| OpenClaw port already in use | Old process not cleaned up | Kill old process or change port in openclaw.json |
| Discord Bot offline | Same token running on two servers | Ensure old server is stopped before starting new one |
| npm install timeout | China network access to npm is slow | Set npmmirror: `npm config set registry https://registry.npmmirror.com` |
| Wrong Node.js version | System's old version used instead of nvm's | Confirm `nvm use 22`, check `node -v` |
| setup.sh permission denied | Script lacks execute permission | Use `chmod +x ~/setup.sh` or run with `bash ~/setup.sh` |
| Feishu not connecting | App not published or permissions expired | Check Feishu Open Platform app status |

---

## Time Estimates

| Step | Duration | Executor |
|------|----------|----------|
| Pre-migration checks | 2 min | 👤 Answer questions |
| Agent check/install Claude Code | 0-5 min | 🦁 Automatic |
| Agent pack + scp | 5 min | 🦁 Automatic |
| New server `bash setup.sh` | 5 min | 👤 1 command |
| Claude Code auto migration | 10-15 min | 🤖 Automatic |
| Verification | 5 min | 👤 |
| **Total** | **~30 minutes** | |

---

## Appendix: Key Files Involved in Migration

| File/Directory | Purpose | Importance |
|----------------|---------|------------|
| `~/.openclaw/openclaw.json` | Core config (API Keys, channels, models, etc.) | ⭐⭐⭐ Required |
| `~/.openclaw/credentials/` | Channel auth files | ⭐⭐⭐ Required |
| `~/.openclaw/workspace/` | Workspace (memory, notes, scripts) | ⭐⭐⭐ Required |
| `~/.openclaw/skills/` | Installed Skills | ⭐⭐ Important |
| `~/.openclaw/extensions/` | Installed plugins | ⭐⭐ Important |
| `~/.openclaw/memory/` | Memory database | ⭐⭐ Important |
| `~/.claude/` | Claude Code config | ⭐⭐ Important |
| `~/.ssh/` | SSH keys (for git, etc.) | ⭐⭐ Important |
| crontab | Scheduled tasks | ⭐⭐ Important |
| /etc/hosts | DNS resolution | ⭐ Optional (needed for China) |
| Dashboard | Monitoring panel | ⭐ Optional |
