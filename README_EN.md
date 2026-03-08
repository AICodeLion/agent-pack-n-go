<div align="center">
  <img src="assets/logo.png" width="140" alt="agent-pack-n-go" />
  <h1>agent-pack-n-go</h1>
  <p><strong>Clone your AI agent to a new device. One command. Everything transfers.</strong></p>
  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT" /></a>
    <a href="https://github.com/AICodeLion/agent-pack-n-go"><img src="https://img.shields.io/badge/platform-OpenClaw-orange.svg" alt="OpenClaw" /></a>
    <a href="https://github.com/AICodeLion/agent-pack-n-go"><img src="https://img.shields.io/badge/OS-Linux-green.svg" alt="Linux" /></a>
  </p>
  <p>
    <a href="#quick-start">Quick Start</a> •
    <a href="#use-cases">Use Cases</a> •
    <a href="#how-it-works">How It Works</a> •
    <a href="README.md">中文</a>
  </p>
</div>

---

## ⚡ Quick Start

**Install** — tell your agent:

> *"Install agent-pack-n-go from https://github.com/AICodeLion/agent-pack-n-go"*

Or manually:

```bash
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

**Use** — tell your agent:

> *"Clone my agent to a new device"*

The agent asks for SSH credentials, then handles everything automatically. ~25 minutes, zero manual steps after SSH key setup.

---

## 🎯 Use Cases

| Scenario | Description |
|----------|-------------|
| Clone | Move to a faster machine, or run a second copy elsewhere |
| Snapshot | Save the tarball as a point-in-time backup, restore in minutes |
| Team deploy | Clone a well-tuned agent across team members |
| Lab → Cloud | Develop locally, deploy to production with one command |

---

## ⚙️ How It Works

The agent on the old device controls everything via SSH. You just confirm.

```
Old Device (agent controls)              New Device (SSH remote)
┌────────────────────────────┐          ┌─────────────────────────┐
│  1. Pre-flight check       │          │                         │
│  2. Network diagnostics    │───────→  │  direct / proxy?        │
│  3. Pack + transfer        │───────→  │  files + SHA256 ✓       │
│  4. setup.sh               │───────→  │  nvm + Node + Claude    │
│  5. deploy.sh              │───────→  │  OpenClaw deployed      │
│  6. Guided switch          │          │  ✅ Agent is live       │
└────────────────────────────┘          └─────────────────────────┘
```

| Phase | What happens | Time | Who |
|-------|-------------|------|-----|
| Pre-flight | SSH key setup, connectivity check | ~3 min | You |
| Network | Auto-detect direct vs proxy | instant | Agent |
| Pack & Transfer | Bundle + rsync + SHA256 verify | ~5 min | Agent |
| Setup | Install nvm, Node.js 22, Claude Code | ~5 min | Agent |
| Deploy | OpenClaw + restore configs + start gateway | ~5 min | Agent |
| Verify | Guided 3-step verification | ~3 min | You |

---

## 📋 What Gets Cloned

| Item | Details |
|------|---------|
| `~/.openclaw/` | Config, workspace, skills, extensions, memory, credentials |
| `~/.claude/` | Claude Code settings and OAuth credentials |
| `~/.ssh/` | SSH keys (permissions auto-fixed to 600) |
| crontab | Scheduled tasks, paths auto-corrected for new username |
| /etc/hosts | Custom DNS entries |
| Dashboard | Optional — included if present |

---

## 🔐 Security

| Measure | Details |
|---------|---------|
| Triple SHA256 | Integrity verified at pack, transfer, and setup |
| SSH-only transport | No cloud, no third-party — credentials stay in the tunnel |
| SUDO_OK pattern | Graceful skip when no passwordless sudo available |

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| Natural language trigger | Say "clone to new device" in any language |
| Network auto-detection | Direct vs proxy, with graceful adaptation |
| Real-time progress | Live updates in your chat during each phase |
| Path auto-correction | `/home/olduser` → `/home/newuser` across all configs |
| rsync with fallback | Falls back to scp when rsync is unavailable |
| Rollback ready | Tarball preserved, restart old device anytime |

---

## 💡 Why agent-pack-n-go

```
Backup  = save files → manually install runtime → manually configure → hope it works
Clone   = data + runtime + credentials + system config → agent boots immediately
```

| Feature | agent-pack-n-go | agent-life | OpenClaw Backup | GitClaw | Official Docs |
|---------|:-:|:-:|:-:|:-:|:-:|
| Full device clone | ✅ | — | — | — | — |
| One-command trigger | ✅ | ✅ | CLI | Cron | ❌ |
| Runtime auto-install | ✅ | ❌ | ❌ | ❌ | ❌ |
| Credentials transfer | ✅ | ✅ | ❌ | ❌ | Manual |
| System config restore | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gateway auto-start | ✅ | ❌ | ❌ | ❌ | ❌ |
| Network diagnostics | ✅ | ❌ | ❌ | ❌ | ❌ |
| Zero third-party | ✅ | ❌ | ❌ | ❌ | ✅ |
| Graceful degradation | ✅ | — | ❌ | ❌ | ❌ |
| Integrity verification | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## ❓ FAQ

**Can I still use my original agent after cloning?**
Yes. Cloning creates a snapshot copy — your original device is completely unaffected.

**What if I clone to a friend?**
The same Discord Bot can't be online on two devices simultaneously. Have your friend create their own Bot — you keep yours, they use theirs, no interference.

**Will memory sync between the two after cloning?**
No. After cloning, each agent evolves independently — like parallel universes that forked.

---

## 📝 Requirements

> Currently optimized for **Linux → Linux**. macOS and Windows (WSL) support is under testing.

| | Old Device | New Device |
|---|-----------|------------|
| OS | Any Linux with OpenClaw | Ubuntu 22.04 / 24.04 |
| Hardware | — | 2-core CPU, 2GB+ RAM |
| Access | — | SSH + sudo (recommended) |

---

## 🗂️ Project Structure

```
agent-pack-n-go/
├── SKILL.md                      # Agent workflow & instructions
├── scripts/
│   ├── pack.sh                   # Pack everything (11 steps)
│   ├── transfer.sh               # rsync + SHA256 verify
│   ├── setup.sh                  # Base environment (12 steps)
│   ├── deploy.sh                 # OpenClaw deployment (13 steps)
│   ├── network-check.sh          # Connectivity diagnostics
│   ├── generate-instructions.sh  # Fallback manual guide
│   └── welcome.sh                # Post-install message
└── references/
    ├── migration-guide.md        # Complete manual reference
    └── troubleshooting.md        # Common issues & fixes
```

---

## 🔗 Related Projects

- [OpenClaw](https://github.com/openclaw/openclaw) — The AI agent framework this skill is built for
- [agent-life](https://agent-life.ai/) — Cross-framework agent migration with neutral format
- [OpenClaw Migration Guide](https://docs.openclaw.ai/install/migrating) — Official manual migration docs

---

## 📄 License

[MIT](LICENSE)
