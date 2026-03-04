# agent-pack-n-go 📦🚀

**OpenClaw Migration — Package Your Agent and Go**

Your Agent isn't just a bundle of code — it's your companion. Months of fine-tuning, evolving memory, learned preferences, and carefully crafted capabilities make it uniquely yours. Moving to a new machine shouldn't mean starting over.

你的 Agent 不只是一堆代码——它是你的伙伴。几个月的调教配置、积累的记忆、学会的偏好、精心安装的技能，让它成为独一无二的存在。换台新设备，不应该意味着和这个伙伴说再见。

**agent-pack-n-go** lets you take your companion with you. One command to package, one command to deploy. Configurations, tools, state, memory, and keys migrate seamlessly — exactly as you left them. **Package → Deploy → Done.**

[English](#english) | [中文](#中文)

---

<a id="english"></a>

## How It Works

```
Old Device (Agent auto)           New Device (One-click deploy)
┌──────────────────────┐          ┌──────────────────────┐
│ 1. Check Claude Code │          │ 3. bash setup.sh     │
│ 2. Pack + scp ───────┼─────────→│ 4. claude "migrate"  │
│                      │   🔒     │    (auto completes)  │
└──────────────────────┘  SHA256  └──────────────────────┘
                                           ↓
                                  Verify & done ✅
```

1. 🔍 **Pre-flight** — Agent asks for new device SSH info and verifies requirements
2. 📦 **Package** — Agent bundles configs, credentials, workspace, skills, memory, SSH keys, crontab into an integrity-verified migration pack
3. 📡 **Transfer** — Encrypted `scp` to the new device (secrets never touch GitHub)
4. 🚀 **Deploy** — Run `bash ~/setup.sh` on the new device — environment installs, integrity checks pass, Claude Code auto-completes the rest

> ⚠️ **Discord Bot note**: Same Bot Token can't run on two devices simultaneously. The agent stops the old device right before the new one starts (~5 min downtime).

## 🎯 Use Cases

- 🖥️ **Upgrade** — Moving to a faster machine without rebuilding from scratch
- 🔄 **Clone** — Replicate a well-tuned agent to another device
- 💾 **Disaster recovery** — Device died? Restore from backup in minutes
- 🏠 **Lab → Production** — Tested locally, deploy to the cloud with one command

## 🔒 Security

All sensitive data transferred via encrypted `scp` with SHA256 integrity verification:

- API keys & model provider credentials
- Discord bot tokens & Feishu AppSecret
- SSH private keys & OAuth credentials
- Agent memory & workspace data

**Your secrets never touch GitHub.** Checksums verify both the full pack and each critical file individually.

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

- 📦 **One-click migration** — Pack on old device, deploy on new device, done
- 🔒 **Secure by design** — Encrypted transfer + SHA256 checksums, never GitHub
- 🌐 **Network-resilient** — Official source → Gitee mirror → error with clear guidance
- ⏱️ **Smart fallback** — npm timeout auto-switches to npmmirror
- ♻️ **Rollback ready** — Old device untouched, restart anytime

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
| Pre-flight check | 2 min | 👤 Answer questions |
| Pack + transfer | 5 min | 🦁 Agent (auto) |
| `bash setup.sh` | 5 min | 👤 One command |
| Claude Code migration | 10-15 min | 🤖 Auto |
| Verify | 5 min | 👤 |
| **Total** | **~30 min** | |

## Project Structure

```
agent-pack-n-go/
├── SKILL.md                      # Skill definition & agent workflow
├── scripts/
│   ├── pack.sh                   # Old device: package everything (10 steps)
│   ├── setup.sh                  # New device: environment setup (11 steps)
│   └── generate-instructions.sh  # Generate Claude Code migration instructions
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

**agent-pack-n-go** 让你带着伙伴一起走——一键打包、一键部署。配置、工具、状态、记忆、密钥，全部无缝迁移。**打包 → 部署 → 搞定。**

### 🎯 什么时候用

- 🖥️ **升级设备** — 换更快的机器，不用从头配置
- 🔄 **克隆 Agent** — 把调教好的 Agent 复制到另一台设备
- 💾 **灾难恢复** — 设备挂了？有备份就能分钟级恢复
- 🏠 **本地 → 云端** — 本地测试好了，一键部署到云服务器

### 🔒 安全第一

所有敏感数据通过加密 `scp` 传输，SHA256 完整性校验：

- API Key 与模型服务凭证
- Discord Bot Token、飞书 AppSecret
- SSH 私钥、OAuth 凭证
- Agent 记忆与工作区数据

**密钥永远不经过 GitHub。** 同时校验整包和每个关键文件。

### 迁移流程

```
旧设备（Agent 自动）              新设备（一键部署）
┌──────────────────────┐          ┌──────────────────────┐
│ 1. 检查 Claude Code  │          │ 3. bash setup.sh     │
│ 2. 打包 + scp ───────┼─────────→│ 4. claude "迁移"     │
│                      │   🔒     │    (自动完成)        │
└──────────────────────┘  SHA256  └──────────────────────┘
                                           ↓
                                  验证通过 ✅
```

1. 🔍 **迁移前检查** — Agent 询问新设备 SSH 信息，确认环境要求
2. 📦 **打包** — 配置、凭证、工作区、技能、记忆、SSH 密钥、定时任务，打成带 SHA256 校验的迁移包
3. 📡 **传输** — `scp` 加密传输到新设备（密钥不经过 GitHub）
4. 🚀 **部署** — SSH 登录新设备，运行 `bash ~/setup.sh` — 自动安装环境、校验完整性，Claude Code 完成全部迁移

> ⚠️ **Discord Bot 注意**：同一个 Bot Token 不能在两台设备同时运行。Agent 会在新设备启动前停止旧设备（约 5 分钟离线）。

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

- 📦 **一键迁移** — 旧设备打包，新设备部署，搞定
- 🔒 **安全至上** — 加密传输 + SHA256 校验，密钥不经过 GitHub
- 🌐 **网络自适应** — 官方源 → Gitee 镜像 → 报错 + 排查指引
- ⏱️ **智能降级** — npm 超时自动切换 npmmirror
- ♻️ **随时回滚** — 旧设备数据完整保留，随时可回退

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
| 迁移前检查 | 2 分钟 | 👤 回答问题 |
| 打包 + 传输 | 5 分钟 | 🦁 Agent 自动 |
| `bash setup.sh` | 5 分钟 | 👤 一条命令 |
| Claude Code 迁移 | 10-15 分钟 | 🤖 自动 |
| 验证 | 5 分钟 | 👤 |
| **总计** | **约 30 分钟** | |

### 项目结构

```
agent-pack-n-go/
├── SKILL.md                      # Skill 定义与 Agent 工作流
├── scripts/
│   ├── pack.sh                   # 旧设备：打包一切（10 步）
│   ├── setup.sh                  # 新设备：环境安装（11 步）
│   └── generate-instructions.sh  # 生成 Claude Code 迁移指令
└── references/
    ├── migration-guide.md        # 完整迁移手册
    └── troubleshooting.md        # 常见问题排查
```

### 许可证

MIT
