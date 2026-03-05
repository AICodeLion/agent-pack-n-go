# agent-pack-n-go 📦🚀 — Clone Your AI Agent to a New Device

**OpenClaw Clone — Package Your Agent and Go**

Your Agent isn't just a bundle of code — it's your companion. Months of fine-tuning, evolving memory, learned preferences, and carefully crafted capabilities make it uniquely yours. Cloning to a new machine keeps your companion intact — on a second device, as a backup, or for your whole team.

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。把它克隆到新设备，完整保留一切。

**agent-pack-n-go** clones your agent anywhere. Just tell your agent where the new device is — it handles everything via SSH. Configurations, tools, state, memory, and keys cloned seamlessly. **Tell Agent → Watch It Go → Done.**

[English](#english) | [中文](#中文)

---

<a id="english"></a>

## How It Works

```
Old Device (Agent controls everything)    New Device (SSH remote)
┌──────────────────────────────────┐      ┌─────────────────────────┐
│ 1. Pre-flight: ask IP + SSH user │      │                         │
│ 2. pack.sh (pack configs)        │      │                         │
│ 3. transfer.sh USER@HOST ────────┼─────→│ files arrive            │
│ 4. ssh USER@HOST "bash setup.sh" │─────→│ (base env + Claude)     │
│ 5. ssh USER@HOST "bash deploy.sh"│─────→│ (openclaw deployed)     │
│ 6. Verify + celebrate!            │      │ ✅ New device running   │
└──────────────────────────────────┘      └─────────────────────────┘
```

1. 🔍 **Pre-flight** — Agent asks for SSH info, you run `ssh-copy-id` once (one password input), agent verifies connectivity
2. 🌐 **Network check** — Auto-detect if new device needs proxy or can connect directly
3. 📦 **Package** — `pack.sh` (11 steps) bundles everything with SHA256 checksums
4. 📡 **Transfer** — `transfer.sh` uses rsync with progress (scp fallback), remote SHA256 verification
5. 🔧 **Setup** — Agent SSH runs `setup.sh` (12 steps): apt update, nvm, node 22, Claude Code, restore configs
6. 🚀 **Deploy** — Agent SSH runs `deploy.sh` (13 steps): extract, install OpenClaw, restore configs/hosts/crontab, start gateway, direct-mode cleanup
7. 🔄 **Switch & Verify** — Agent guides you through device switch, three-step verification (messaging, memory, tools)
8. 🎉 **Celebrate!** — Clone summary + cleanup tips

> ℹ️ **Discord Bot note**: If using the same Bot Token, it can't run on two devices simultaneously. Plan a brief switchover (~5 min downtime). If using different tokens, both devices can run in parallel.

## 🎯 Use Cases

- 🔄 **Clone to new device** — Moving to a faster machine, or want a copy running elsewhere
- 💾 **Backup** — Pack your agent and save the tarball; restore anytime in minutes
- 👥 **Team deploy** — Clone a well-tuned agent config to multiple team members
- 🏠 **Lab → Production** — Tested locally, deploy to the cloud with one command

## 🔒 Security

All sensitive data transferred via rsync over SSH with triple SHA256 integrity verification:

- API keys & model provider credentials
- Discord bot tokens & Feishu AppSecret
- SSH private keys & OAuth credentials
- Agent memory & workspace data

**Your secrets never touch GitHub.** Checksums verify the full pack at pack time, transfer time, and setup time.

## 🏆 Why agent-pack-n-go?

Most tools back up your agent's *data*. We clone the **entire agent** — it wakes up on the new machine and just works.

| | agent-pack-n-go | Alternatives |
|---|---|---|
| 🔐 **Zero trust** | Pure SSH point-to-point. Your secrets never touch any cloud. | Cloud relay (TiDB Zero), or manual copy |
| 🧬 **True clone, not backup** | Data + runtime (nvm/Node/Claude) + system config (/etc/hosts, crontab, proxy) — agent boots and works immediately | Data only — you still need to set up the environment manually |
| 🤖 **Agent-driven** | Say "clone me", agent handles everything via SSH. No manual steps. | Follow a migration guide, or configure a cloud sync service |
| 🛡️ **Works anywhere** | No sudo? Skips gracefully. No rsync? Falls back to scp. Needs proxy? Auto-detected. Always completes. | Assumes ideal environment |

**Your data never passes through any third-party cloud.** Direct device-to-device transfer over SSH — the way it should be.

## What Gets Cloned

| Item | Description |
|------|-------------|
| `~/.openclaw/` | Config, workspace, skills, extensions, memory, credentials |
| `~/.claude/` | Claude Code settings and OAuth credentials |
| `~/.ssh/` | SSH keys (permissions auto-fixed to 600) |
| crontab | All scheduled tasks (paths auto-corrected for new username) |
| /etc/hosts | Custom DNS entries (e.g. Discord CDN fix for China) |
| Dashboard | Optional, included if present |

## ✨ Features

- 📦 **Agent handles everything** — Just provide SSH info; agent controls the full flow remotely
- 🔒 **Triple SHA256 verification** — pack → transfer → setup, integrity checked at every stage
- 🌐 **Network auto-detection** — Checks if new device can reach Discord/Anthropic directly or needs proxy
- 📊 **Real-time progress** — Agent polls `/tmp` progress files and shows live updates in chat
- 🌏 **China network auto-detection** — npmmirror, Gitee mirror, auto-selected based on region
- 🔄 **rsync with progress** — scp fallback if rsync unavailable
- ♻️ **Rollback ready** — tarball preserved after deploy, restart old device anytime
- 🛡️ **sudo safety** — SUDO_OK detection, graceful skip when no passwordless sudo

## Requirements

> 🐧 **Linux → Linux clone.** Both devices must be Linux (Ubuntu recommended).
>
> 🧪 macOS and Windows (WSL) support is currently in testing.

| | Old Device | New Device |
|---|-----------|------------|
| **OS** | Any Linux with OpenClaw running | Ubuntu 22.04 / 24.04 (Debian-based OK) |
| **Hardware** | — | 2-core CPU, 2GB+ RAM |
| **Access** | — | SSH + sudo |

## Installation

```bash
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

Or tell your agent: *"Install agent-pack-n-go from https://github.com/AICodeLion/agent-pack-n-go"*

Once installed, just say: **"帮我克隆到新设备"** or **"clone to a new device"** to start.

## ⏱️ Time Estimate

| Step | Duration | Who |
|------|----------|-----|
| Pre-flight (SSH setup) | 3 min | 👤 ssh-copy-id + confirm |
| Pack + transfer | 5 min | 🦁 Agent (auto) |
| Setup (base env) | 5-8 min | 🦁 Agent via SSH (auto) |
| Deploy (OpenClaw) | 3-5 min | 🦁 Agent via SSH (auto) |
| Switch & verify | 3 min | 👤 Guided by Agent |
| **Total** | **~25 min** | |

## Project Structure

```
agent-pack-n-go/
├── SKILL.md                      # Skill definition & agent workflow
├── scripts/
│   ├── pack.sh                   # Old device: package everything (11 steps)
│   ├── transfer.sh               # Old device: rsync to new device + SHA256 verify
│   ├── setup.sh                  # New device: base environment (12 steps)
│   ├── deploy.sh                 # New device: OpenClaw deployment (13 steps)
│   ├── network-check.sh          # New device: test direct connectivity
│   ├── generate-instructions.sh  # Generate fallback clone doc
│   └── welcome.sh                # Post-install welcome message
└── references/
    ├── migration-guide.md        # Complete migration manual
    └── troubleshooting.md        # Common issues & solutions
```

## License

MIT

---

<a id="中文"></a>

## 中文说明

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。把它克隆到新设备，完整保留一切。

**agent-pack-n-go** 把 Agent 克隆到任何地方。只要告诉 Agent 新设备在哪，剩下的它全搞定——通过 SSH 远程控制全部流程。配置、工具、状态、记忆、密钥，全部无缝克隆。**告诉 Agent → 看着它干 → 搞定。**

### 克隆流程

```
旧设备（Agent 全程控制）                  新设备（SSH 远程）
┌──────────────────────────────────┐      ┌─────────────────────────┐
│ 1. 克隆前检查：询问 IP + 用户名  │      │                         │
│ 2. pack.sh（打包配置）           │      │                         │
│ 3. transfer.sh USER@HOST ────────┼─────→│ 文件到达                │
│ 4. ssh USER@HOST "bash setup.sh" │─────→│（基础环境 + Claude）    │
│ 5. ssh USER@HOST "bash deploy.sh"│─────→│（OpenClaw 部署完毕）    │
│ 6. 验证 + 庆祝！                 │      │ ✅ 新设备运行中         │
└──────────────────────────────────┘      └─────────────────────────┘
```

1. 🔍 **克隆前检查** — Agent 询问 SSH 信息，你跑一次 `ssh-copy-id`（只需输一次密码），Agent 验证连通性
2. 🌐 **网络诊断** — 自动检测新设备能否直连 Discord/Anthropic，还是需要代理
3. 📦 **打包** — `pack.sh`（11 步）打包所有内容，生成 SHA256 校验值
4. 📡 **传输** — `transfer.sh` 使用 rsync 带进度条传输（scp 兜底），远端 SHA256 验证
5. 🔧 **安装环境** — Agent SSH 运行 `setup.sh`（12 步）：apt update、nvm、node 22、Claude Code、恢复配置
6. 🚀 **部署** — Agent SSH 运行 `deploy.sh`（13 步）：解压、安装 OpenClaw、恢复配置/hosts/定时任务、启动网关、直连模式清理
7. 🔄 **切换与验证** — Agent 引导你切换设备，三步验证（消息/记忆/工具）
8. 🎉 **庆祝！** — 克隆总结 + 清理提醒

> ℹ️ **Discord Bot 注意**：同一个 Bot Token 不能在两台设备同时运行。如需完全切换，停止旧设备约需 5 分钟。如使用不同 Token，两台设备可同时运行。

### 🎯 什么时候用

- 🔄 **克隆到新设备** — 换更快的机器，或者想在另一台设备跑一份
- 💾 **备份** — 打包后保存 tarball，随时可恢复
- 👥 **团队部署** — 把调教好的配置克隆给多个团队成员
- 🏠 **本地 → 云端** — 本地测试好了，一键部署到云服务器

### 🔒 安全第一

所有敏感数据通过 SSH 加密的 rsync 传输，三重 SHA256 完整性校验：

- API Key 与模型服务凭证
- Discord Bot Token、飞书 AppSecret
- SSH 私钥、OAuth 凭证
- Agent 记忆与工作区数据

**密钥永远不经过 GitHub。** 打包、传输、安装三个阶段分别校验。

### 🏆 为什么选 agent-pack-n-go？

大多数工具只备份 Agent 的*数据*。我们克隆的是**整个 Agent**——在新设备上直接活过来，开机即用。

| | agent-pack-n-go | 其他方案 |
|---|---|---|
| 🔐 **零信任** | 纯 SSH 点对点传输，密钥不经过任何云服务 | 云端中转（TiDB Zero），或手动复制 |
| 🧬 **真正的克隆，不只是备份** | 数据 + 运行时环境（nvm/Node/Claude）+ 系统配置（/etc/hosts、crontab、代理）— Agent 到了就能跑 | 只备份数据——环境还得自己搭 |
| 🤖 **Agent 全程代劳** | 说句"帮我克隆"，Agent 通过 SSH 搞定一切，无需手动操作 | 照着迁移文档操作，或配置云同步服务 |
| 🛡️ **到哪都能跑** | 没 sudo？优雅跳过。没 rsync？降级为 scp。需要代理？自动检测。永远能跑完。 | 假设理想环境 |

**你的数据不经过任何第三方云服务。** 设备到设备，SSH 直连传输——安全本该如此。

### 克隆内容

| 内容 | 说明 |
|------|------|
| `~/.openclaw/` | 配置、工作区、技能、插件、记忆、凭证 |
| `~/.claude/` | Claude Code 设置和 OAuth 凭证 |
| `~/.ssh/` | SSH 密钥（权限自动修正为 600） |
| crontab | 所有定时任务（路径自动修正） |
| /etc/hosts | 自定义 DNS 条目（如 Discord CDN） |
| Dashboard | 可选，如果存在则打包 |

### ✨ 特性

- 📦 **Agent 全程代劳** — 只需提供 SSH 信息，Agent 远程控制全部流程
- 🔒 **三重 SHA256 校验** — 打包→传输→安装，每个阶段都验证完整性
- 🌐 **网络自动检测** — 检测新设备能否直连 Discord/Anthropic，自动选择直连或代理模式
- 📊 **实时进度反馈** — Agent 轮询 `/tmp` 进度文件，在对话中实时显示进度
- 🌏 **中国网络自适应** — 自动检测并切换 npmmirror、Gitee 镜像
- 🔄 **rsync 带进度条** — rsync 不可用时自动降级为 scp
- ♻️ **随时回滚** — 部署后压缩包保留，随时可重新部署或回退旧设备
- 🛡️ **sudo 安全机制** — SUDO_OK 检测，无免密 sudo 时优雅跳过

### 设备要求

> 🐧 **支持 Linux → Linux 克隆。** 新旧设备均需为 Linux 系统（推荐 Ubuntu）。
>
> 🧪 macOS 和 Windows (WSL) 版本正在测试中。

| | 旧设备 | 新设备 |
|---|-------|-------|
| **系统** | 任何运行 OpenClaw 的 Linux | Ubuntu 22.04 / 24.04（Debian 系兼容） |
| **硬件** | — | 2 核 CPU，2GB+ 内存 |
| **访问** | — | SSH + sudo 权限 |

### 安装

```bash
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

或者告诉你的 Agent：*"帮我安装 agent-pack-n-go skill，地址 https://github.com/AICodeLion/agent-pack-n-go"*

安装完成后，对 Agent 说：**"帮我克隆到新设备"** 即可启动克隆。

### ⏱️ 时间估算

| 步骤 | 耗时 | 执行者 |
|------|------|--------|
| 克隆前检查（SSH 配置） | 3 分钟 | 👤 ssh-copy-id + 确认 |
| 打包 + 传输 | 5 分钟 | 🦁 Agent 自动 |
| 安装环境（基础环境） | 5-8 分钟 | 🦁 Agent 远程自动 |
| 部署（OpenClaw） | 3-5 分钟 | 🦁 Agent 远程自动 |
| 切换与验证 | 3 分钟 | 👤 Agent 引导 |
| **总计** | **约 25 分钟** | |

### 项目结构

```
agent-pack-n-go/
├── SKILL.md                      # Skill 定义与 Agent 工作流
├── scripts/
│   ├── pack.sh                   # 旧设备：打包一切（11 步）
│   ├── transfer.sh               # 旧设备：rsync 传输 + SHA256 验证
│   ├── setup.sh                  # 新设备：基础环境安装（12 步）
│   ├── deploy.sh                 # 新设备：OpenClaw 部署（13 步）
│   ├── network-check.sh          # 新设备：网络直连检测
│   ├── generate-instructions.sh  # 生成备用克隆文档
│   └── welcome.sh                # 安装后欢迎信息
└── references/
    ├── migration-guide.md        # 完整迁移手册
    └── troubleshooting.md        # 常见问题排查
```

### 许可证

MIT
