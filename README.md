# agent-pack-n-go 📦🚀

**OpenClaw Migration — Package Your Agent and Go**

Your Agent isn't just a bundle of code — it's your companion. Months of fine-tuning, evolving memory, learned preferences, and carefully crafted capabilities make it uniquely yours. Moving to a new machine shouldn't mean starting over.

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。换台新设备，不应该意味着和这个伙伴说再见。

**agent-pack-n-go** lets your companion follow you anywhere. Just tell your agent where the new device is — it handles everything via SSH. Configurations, tools, state, memory, and keys migrate seamlessly. **Tell Agent → Watch It Go → Done.**

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
│ 6. Verify → stop old OpenClaw    │      │ ✅ New device running   │
└──────────────────────────────────┘      └─────────────────────────┘
```

1. 🔍 **Pre-flight** — Agent asks for SSH info, you run `ssh-copy-id` once (one password input), agent verifies connectivity
2. 📦 **Package** — `pack.sh` (11 steps) bundles everything with SHA256 checksums
3. 📡 **Transfer** — `transfer.sh` uses rsync with progress (scp fallback), remote SHA256 verification
4. 🔧 **Setup** — Agent SSH runs `setup.sh` (12 steps): apt update, nvm, node 22, Claude Code, restore configs
5. 🚀 **Deploy** — Agent SSH runs `deploy.sh` (12 steps): extract, install OpenClaw, restore configs/hosts/crontab, start gateway
6. ✅ **Verify** — Check connectivity, you confirm, agent stops old device

> ⚠️ **Discord Bot note**: Same Bot Token can't run on two devices simultaneously. The agent stops the old device right before the new one starts (~5 min downtime).

## 🎯 Use Cases

- 🖥️ **Upgrade** — Moving to a faster machine without rebuilding from scratch
- 🔄 **Clone** — Replicate a well-tuned agent to another device
- 💾 **Disaster recovery** — Device died? Restore from backup in minutes
- 🏠 **Lab → Production** — Tested locally, deploy to the cloud with one command

## 🔒 Security

All sensitive data transferred via rsync over SSH with triple SHA256 integrity verification:

- API keys & model provider credentials
- Discord bot tokens & Feishu AppSecret
- SSH private keys & OAuth credentials
- Agent memory & workspace data

**Your secrets never touch GitHub.** Checksums verify the full pack at pack time, transfer time, and setup time.

## What Gets Migrated

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
- 📊 **Real-time progress** — Agent polls `/tmp` progress files and shows live updates in chat
- 🌐 **China network auto-detection** — npmmirror, Gitee mirror, auto-selected based on region
- 🔄 **rsync with progress** — scp fallback if rsync unavailable
- ♻️ **Rollback ready** — tarball preserved after deploy, restart old device anytime
- 🛡️ **sudo safety** — SUDO_OK detection, graceful skip when no passwordless sudo

## Requirements

> 🐧 **Linux → Linux migration.** Both devices must be Linux (Ubuntu recommended).
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

Once installed, just say: **"帮我迁移到新设备"** or **"migrate to a new device"** to start.

## ⏱️ Time Estimate

| Step | Duration | Who |
|------|----------|-----|
| Pre-flight (SSH setup) | 3 min | 👤 ssh-copy-id + confirm |
| Pack + transfer | 5 min | 🦁 Agent (auto) |
| Setup (base env) | 5-8 min | 🦁 Agent via SSH (auto) |
| Deploy (OpenClaw) | 3-5 min | 🦁 Agent via SSH (auto) |
| Verify & switch | 5 min | 👤 Confirm |
| **Total** | **~25 min** | |

## Project Structure

```
agent-pack-n-go/
├── SKILL.md                      # Skill definition & 6-phase agent workflow
├── scripts/
│   ├── pack.sh                   # Old device: package everything (11 steps)
│   ├── transfer.sh               # Old device: rsync to new device + SHA256 verify
│   ├── setup.sh                  # New device: base environment (12 steps)
│   ├── deploy.sh                 # New device: OpenClaw deployment (12 steps)
│   ├── generate-instructions.sh  # Generate fallback migration doc
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

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。换台新设备，不应该意味着和这个伙伴说再见。

**agent-pack-n-go** 让伙伴随你一起走。只要告诉 Agent 新设备在哪，剩下的它全搞定——通过 SSH 远程控制全部流程。配置、工具、状态、记忆、密钥，全部无缝迁移。**告诉 Agent → 看着它干 → 搞定。**

### 迁移流程

```
旧设备（Agent 全程控制）                  新设备（SSH 远程）
┌──────────────────────────────────┐      ┌─────────────────────────┐
│ 1. 迁移前检查：询问 IP + 用户名  │      │                         │
│ 2. pack.sh（打包配置）           │      │                         │
│ 3. transfer.sh USER@HOST ────────┼─────→│ 文件到达                │
│ 4. ssh USER@HOST "bash setup.sh" │─────→│（基础环境 + Claude）    │
│ 5. ssh USER@HOST "bash deploy.sh"│─────→│（OpenClaw 部署完毕）    │
│ 6. 验证 → 停止旧 OpenClaw        │      │ ✅ 新设备运行中         │
└──────────────────────────────────┘      └─────────────────────────┘
```

1. 🔍 **迁移前检查** — Agent 询问 SSH 信息，你跑一次 `ssh-copy-id`（只需输一次密码），Agent 验证连通性
2. 📦 **打包** — `pack.sh`（11 步）打包所有内容，生成 SHA256 校验值
3. 📡 **传输** — `transfer.sh` 使用 rsync 带进度条传输（scp 兜底），远端 SHA256 验证
4. 🔧 **安装环境** — Agent SSH 运行 `setup.sh`（12 步）：apt update、nvm、node 22、Claude Code、恢复配置
5. 🚀 **部署** — Agent SSH 运行 `deploy.sh`（12 步）：解压、安装 OpenClaw、恢复配置/hosts/定时任务、启动网关
6. ✅ **验证切换** — 检查连通性，你确认，Agent 停止旧设备

> ⚠️ **Discord Bot 注意**：同一个 Bot Token 不能在两台设备同时运行。Agent 会在新设备启动前停止旧设备（约 5 分钟离线）。

### 🎯 什么时候用

- 🖥️ **升级设备** — 换更快的机器，不用从头配置
- 🔄 **克隆 Agent** — 把调教好的 Agent 复制到另一台设备
- 💾 **灾难恢复** — 设备挂了？有备份就能分钟级恢复
- 🏠 **本地 → 云端** — 本地测试好了，一键部署到云服务器

### 🔒 安全第一

所有敏感数据通过 SSH 加密的 rsync 传输，三重 SHA256 完整性校验：

- API Key 与模型服务凭证
- Discord Bot Token、飞书 AppSecret
- SSH 私钥、OAuth 凭证
- Agent 记忆与工作区数据

**密钥永远不经过 GitHub。** 打包、传输、安装三个阶段分别校验。

### 迁移内容

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
- 📊 **实时进度反馈** — Agent 轮询 `/tmp` 进度文件，在对话中实时显示进度
- 🌐 **中国网络自适应** — 自动检测并切换 npmmirror、Gitee 镜像
- 🔄 **rsync 带进度条** — rsync 不可用时自动降级为 scp
- ♻️ **随时回滚** — 部署后压缩包保留，随时可重新部署或回退旧设备
- 🛡️ **sudo 安全机制** — SUDO_OK 检测，无免密 sudo 时优雅跳过

### 设备要求

> 🐧 **支持 Linux → Linux 迁移。** 新旧设备均需为 Linux 系统（推荐 Ubuntu）。
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

安装完成后，对 Agent 说：**"帮我迁移到新设备"** 即可启动迁移。

### ⏱️ 时间估算

| 步骤 | 耗时 | 执行者 |
|------|------|--------|
| 迁移前检查（SSH 配置） | 3 分钟 | 👤 ssh-copy-id + 确认 |
| 打包 + 传输 | 5 分钟 | 🦁 Agent 自动 |
| 安装环境（基础环境） | 5-8 分钟 | 🦁 Agent 远程自动 |
| 部署（OpenClaw） | 3-5 分钟 | 🦁 Agent 远程自动 |
| 验证切换 | 5 分钟 | 👤 确认 |
| **总计** | **约 25 分钟** | |

### 项目结构

```
agent-pack-n-go/
├── SKILL.md                      # Skill 定义与 Agent 六阶段工作流
├── scripts/
│   ├── pack.sh                   # 旧设备：打包一切（11 步）
│   ├── transfer.sh               # 旧设备：rsync 传输 + SHA256 验证
│   ├── setup.sh                  # 新设备：基础环境安装（12 步）
│   ├── deploy.sh                 # 新设备：OpenClaw 部署（12 步）
│   ├── generate-instructions.sh  # 生成备用迁移文档
│   └── welcome.sh                # 安装后欢迎信息
└── references/
    ├── migration-guide.md        # 完整迁移手册
    └── troubleshooting.md        # 常见问题排查
```

### 许可证

MIT
