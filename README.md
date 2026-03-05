# agent-pack-n-go 📦🚀

**Clone your AI agent to a new device in one command. Fully automated. Zero cloud dependency.**

Your agent isn't just code — it's months of memory, tuned preferences, installed skills, and wired credentials. agent-pack-n-go clones the **entire agent** to a new machine via SSH. It arrives ready to run.

[English](#quick-start) · [中文](#中文)

---

## Quick Start

### Install

```bash
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

Or tell your agent:

> *"Install agent-pack-n-go from https://github.com/AICodeLion/agent-pack-n-go"*

### Use

Just say to your agent:

> **"Clone to a new device"**

The agent will ask for SSH credentials, then handle everything automatically. ~25 minutes, zero manual steps after the initial SSH setup.

---

## Why agent-pack-n-go?

Most tools **back up** your agent's files. We **clone** the entire agent — it wakes up on the new machine and just works.

```
Backup  = save files → manually install runtime → manually configure → hope it works
Clone   = data + runtime + credentials + system config → agent boots immediately
```

### Feature Comparison

| Feature | agent-pack-n-go | agent-life | OpenClaw Backup | GitClaw | Official Docs |
|---|:---:|:---:|:---:|:---:|:---:|
| Full device clone | ✅ | — | — | — | — |
| One-command trigger | ✅ | ✅ | CLI | Cron | ❌ |
| Runtime auto-install | ✅ | ❌ | ❌ | ❌ | ❌ |
| Credentials (encrypted) | ✅ | ✅ | ❌ | ❌ | Manual |
| System config | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gateway auto-start | ✅ | ❌ | ❌ | ❌ | ❌ |
| Network diagnostics | ✅ | ❌ | ❌ | ❌ | ❌ |
| Zero third-party | ✅ | ❌ | ❌ | ❌ | ✅ |
| Graceful degradation | ✅ | — | ❌ | ❌ | ❌ |
| Cross-framework | 🔧 | ✅ | ❌ | ❌ | ❌ |
| Integrity verification | ✅ | ✅ | ❌ | ❌ | ❌ |

> **Runtime auto-install** = nvm, Node.js, Claude Code, npm globals — all set up automatically on the new machine.
>
> **System config** = /etc/hosts, crontab, proxy settings — restored and adapted for the new environment.
>
> **Graceful degradation** = No sudo? Skips gracefully. No rsync? Falls back to scp. Needs proxy? Auto-detected.

---

## How It Works

```
Old Device                              New Device
┌────────────────────────────┐          ┌─────────────────────┐
│  1. Pre-flight check       │          │                     │
│  2. Network diagnostics    │          │                     │
│  3. pack.sh ──────────────────────→   │  files arrive       │
│  4. ssh  "bash setup.sh"  ─────────→  │  runtime ready      │
│  5. ssh  "bash deploy.sh" ─────────→  │  openclaw deployed  │
│  6. Guided verify + 🎉    │          │  ✅ agent is live    │
└────────────────────────────┘          └─────────────────────┘
```

| Step | What happens | Duration |
|------|-------------|----------|
| 🔍 Pre-flight | SSH key setup, connectivity check | 3 min (user) |
| 🌐 Network check | Auto-detect direct / proxy needed | instant |
| 📦 Pack + Transfer | Bundle everything, rsync + SHA256 verify | 5 min |
| 🔧 Setup | Install nvm, Node 22, Claude Code | 5–8 min |
| 🚀 Deploy | Install OpenClaw, restore configs, start gateway | 3–5 min |
| 🔄 Switch & Verify | Guided device switch, 3-step verification | 3 min (user) |
| 🎉 Done | Clone summary + cleanup tips | — |

---

## What Gets Cloned

| Item | Description |
|------|-------------|
| `~/.openclaw/` | Config, workspace, skills, extensions, memory, credentials |
| `~/.claude/` | Claude Code settings and OAuth credentials |
| `~/.ssh/` | SSH keys (permissions auto-fixed to 600) |
| crontab | Scheduled tasks (paths auto-corrected for new username) |
| /etc/hosts | Custom DNS entries |
| Dashboard | Optional, included if present |

---

## Use Cases

- 🔄 **Clone** — Move to a faster machine, or run a copy elsewhere
- 💾 **Backup** — Save the tarball; restore anytime in minutes
- 👥 **Team deploy** — Clone a well-tuned agent to multiple team members
- 🏠 **Lab → Cloud** — Test locally, deploy to production with one command

---

## Security

All data transferred via rsync over SSH. No third-party cloud, no intermediate storage.

- 🔒 **Triple SHA256** — integrity verified at pack, transfer, and setup
- 🔐 **SSH-only transport** — credentials never leave the encrypted tunnel
- 🛡️ **SUDO_OK pattern** — graceful skip when no passwordless sudo

---

## Features

- 📦 **Agent-driven** — provide SSH info, agent handles the rest remotely
- 🌐 **Network auto-detection** — direct vs. proxy, npm mirror selection
- 📊 **Real-time progress** — live updates in chat during each phase
- 🔄 **rsync with fallback** — scp when rsync is unavailable
- ♻️ **Rollback ready** — tarball preserved, restart old device anytime
- 🔧 **Cross-framework ready** — swap `deploy.sh` to target other agent runtimes

---

## Requirements

> 🐧 **Linux → Linux.** Both devices must be Linux (Ubuntu recommended).

| | Old Device | New Device |
|---|-----------|------------|
| **OS** | Any Linux with OpenClaw | Ubuntu 22.04 / 24.04 |
| **Hardware** | — | 2-core CPU, 2GB+ RAM |
| **Access** | — | SSH + sudo |

---

## Project Structure

```
agent-pack-n-go/
├── SKILL.md                      # Skill definition & agent workflow
├── scripts/
│   ├── pack.sh                   # Pack everything (11 steps)
│   ├── transfer.sh               # rsync + SHA256 verify
│   ├── setup.sh                  # Base environment (12 steps)
│   ├── deploy.sh                 # OpenClaw deployment (13 steps)
│   ├── network-check.sh          # Direct connectivity test
│   ├── generate-instructions.sh  # Fallback manual guide
│   └── welcome.sh                # Post-install message
└── references/
    ├── migration-guide.md        # Complete manual
    └── troubleshooting.md        # Common issues & fixes
```

---

## License

MIT

---

## References

- [agent-life](https://agent-life.ai/) — Cross-framework agent migration with neutral format and zero-knowledge encryption
- [OpenClaw Backup](https://lobehub.com/skills/liuzln-openclaw-skills-openclaw-backup) — Python-based backup and restore for OpenClaw configurations
- [GitClaw](https://github.com/openclaw/openclaw/discussions/5809) — Auto-commit workspace to GitHub
- [OpenClaw Migration Guide](https://docs.openclaw.ai/install/migrating) — Official manual migration steps

---

<a id="中文"></a>

## 中文

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。

**agent-pack-n-go** 把 Agent 克隆到任何地方。只要告诉 Agent 新设备在哪，剩下的它全搞定。**告诉 Agent → 看着它干 → 搞定。**

### 快速开始

```bash
# 安装
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git

# 使用：对 Agent 说
"帮我克隆到新设备"
```

### 克隆流程

```
旧设备（Agent 全程控制）                  新设备（SSH 远程）
┌──────────────────────────────────┐      ┌─────────────────────────┐
│ 1. 克隆前检查：询问 IP + 用户名  │      │                         │
│ 2. 网络诊断                      │      │                         │
│ 3. 打包 + 传输 ──────────────────┼─────→│ 文件到达                │
│ 4. ssh "bash setup.sh" ──────────┼─────→│ 运行时就绪              │
│ 5. ssh "bash deploy.sh" ─────────┼─────→│ OpenClaw 部署完毕       │
│ 6. 引导验证 + 🎉                │      │ ✅ Agent 上线           │
└──────────────────────────────────┘      └─────────────────────────┘
```

| 步骤 | 耗时 | 执行者 |
|------|------|--------|
| 克隆前检查（SSH 配置） | 3 分钟 | 👤 用户 |
| 打包 + 传输 | 5 分钟 | 🤖 Agent |
| 安装环境 | 5-8 分钟 | 🤖 Agent |
| 部署 OpenClaw | 3-5 分钟 | 🤖 Agent |
| 切换与验证 | 3 分钟 | 👤 Agent 引导 |
| **总计** | **约 25 分钟** | |

### 为什么选 agent-pack-n-go？

> **备份** = 存文件 → 手动装环境 → 手动配置 → 祈祷能跑
>
> **克隆** = 数据 + 运行时 + 凭证 + 系统配置 → Agent 到了就能跑

| 功能 | agent-pack-n-go | agent-life | OpenClaw Backup | GitClaw | 官方文档 |
|---|:---:|:---:|:---:|:---:|:---:|
| 完整设备克隆 | ✅ | — | — | — | — |
| 一句话触发 | ✅ | ✅ | CLI | Cron | ❌ |
| 运行时自动安装 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 凭证加密传输 | ✅ | ✅ | ❌ | ❌ | 手动 |
| 系统配置 | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gateway 自启 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 网络诊断 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 零第三方 | ✅ | ❌ | ❌ | ❌ | ✅ |
| 优雅降级 | ✅ | — | ❌ | ❌ | ❌ |
| 跨框架 | 🔧 | ✅ | ❌ | ❌ | ❌ |
| 完整性校验 | ✅ | ✅ | ❌ | ❌ | ❌ |

### 克隆内容

| 内容 | 说明 |
|------|------|
| `~/.openclaw/` | 配置、工作区、技能、插件、记忆、凭证 |
| `~/.claude/` | Claude Code 设置和 OAuth 凭证 |
| `~/.ssh/` | SSH 密钥（权限自动修正为 600） |
| crontab | 所有定时任务（路径自动修正） |
| /etc/hosts | 自定义 DNS 条目 |
| Dashboard | 可选，如果存在则打包 |

### 安全

- 🔒 **三重 SHA256 校验** — 打包、传输、安装每个阶段验证
- 🔐 **纯 SSH 传输** — 凭证不经过任何第三方
- 🛡️ **优雅降级** — 没 sudo/rsync 也能跑完

### 设备要求

| | 旧设备 | 新设备 |
|---|-------|-------|
| **系统** | 任何运行 OpenClaw 的 Linux | Ubuntu 22.04 / 24.04 |
| **硬件** | — | 2 核 CPU，2GB+ 内存 |
| **访问** | — | SSH + sudo 权限 |

### 许可证

MIT
