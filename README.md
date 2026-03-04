# agent-pack-n-go 📦🚀

**OpenClaw Migration — Package Your Agent and Go**

Seamlessly migrate your Agent with just two commands: one to package everything (configs, tools, state, dependencies), and one to deploy and fully restore the environment anywhere. No manual exports or complex setup—just **Package → Deploy → Done**.

All sensitive data (API keys, Discord bot tokens, Feishu AppSecret, SSH private keys, OAuth credentials) transferred via encrypted `scp` with SHA256 integrity verification. Your secrets never touch GitHub.

[中文版](#中文) | [English](#english)

---

<a id="english"></a>

## What It Does

An OpenClaw Skill that automates full agent migration. Your agent packs everything on the old device, you run **2 commands** on the new device, and your agent is back online — configs, memory, skills, credentials, all intact.

```
Old Device (Agent auto)           New Device (You: 2 commands)
┌──────────────────────┐          ┌──────────────────────┐
│ 1. Check Claude Code │          │ 3. bash setup.sh     │
│ 2. Pack + scp ───────┼─────────→│ 4. claude "migrate"  │
│                      │   🔒     │    (auto completes)  │
└──────────────────────┘  SHA256  └──────────────────────┘
                                           ↓
                                  Verify & done ✅
```

## Features

- 📦 **Two commands, full migration** — Pack on old device, deploy on new device, done
- 🔒 **Secure by design** — API keys, bot tokens, SSH keys, OAuth credentials — all via encrypted `scp`, never GitHub. SHA256 checksums catch any corruption.
- 🌐 **Network-resilient** — Official source → Gitee mirror → error with guidance
- ⏱️ **npm timeout detection** — Auto-switches to npmmirror if npm is slow
- ♻️ **Rollback ready** — Old device untouched, restart anytime if something fails

## What Gets Migrated

| Item | Description |
|------|-------------|
| `~/.openclaw/` | Config, workspace, skills, extensions, memory, credentials |
| `~/.claude/` | Claude Code settings and OAuth credentials |
| `~/.ssh/` | SSH keys (permissions auto-fixed to 600) |
| crontab | All scheduled tasks (paths auto-corrected) |
| /etc/hosts | Custom DNS entries (e.g. Discord CDN fix) |
| Dashboard | Optional, if present |

## Requirements

**New device:**
- Ubuntu 22.04 / 24.04
- 2-core CPU, 2GB+ RAM
- SSH access with sudo

**Old device:**
- Running OpenClaw installation

## Installation

```bash
# In your OpenClaw workspace
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

Or tell your agent: *"install the agent-pack-n-go skill from GitHub"*

## Usage

Tell your OpenClaw agent:

> "帮我迁移到新设备" / "migrate to a new device"

The agent will:
1. Ask for new device SSH info
2. Run `pack.sh` to bundle everything
3. `scp` the pack to the new device
4. Guide you through 2 commands on the new device

> ⚠️ **Discord Bot note**: The same Bot Token can't run on two devices simultaneously. The agent will stop the old device right before the new one starts, causing ~5 min downtime.

## Time Estimate

| Step | Duration | Who |
|------|----------|-----|
| Pre-flight check | 2 min | 👤 Answer questions |
| Agent packs + transfers | 5 min | 🦁 Auto |
| `bash setup.sh` | 5 min | 👤 1 command |
| Claude Code auto-migrate | 10-15 min | 🤖 Auto |
| Verify | 5 min | 👤 |
| **Total** | **~30 min** | |

## File Structure

```
agent-pack-n-go/
├── SKILL.md                    # Skill definition & workflow
├── README.md                   # This file
├── scripts/
│   ├── pack.sh                 # Old device: pack everything (10 steps)
│   ├── setup.sh                # New device: install environment (11 steps)
│   └── generate-instructions.sh # Generate Claude Code migration instructions
└── references/
    ├── migration-guide.md      # Complete migration manual
    └── troubleshooting.md      # Common issues & solutions
```

## License

MIT

---

<a id="中文"></a>

## 中文说明

### 这是什么

OpenClaw 一键迁移工具。两条命令，把你的 Agent 完整搬到任何新设备上——配置、工具、状态、记忆、密钥，全部自动恢复。

所有敏感数据（API Key、Discord Bot Token、飞书 AppSecret、SSH 私钥、OAuth 凭证）通过加密 `scp` 传输，SHA256 完整性校验，密钥永远不经过 GitHub。

```
旧设备（Agent 自动）              新设备（你：2 条命令）
┌──────────────────────┐          ┌──────────────────────┐
│ 1. 检查 Claude Code  │          │ 3. bash setup.sh     │
│ 2. 打包 + scp ───────┼─────────→│ 4. claude "迁移"     │
│                      │   🔒     │    (自动完成)        │
└──────────────────────┘  SHA256  └──────────────────────┘
                                           ↓
                                  验证通过 ✅
```

### 特性

- 📦 **两条命令，完整迁移** — 旧设备打包，新设备部署，搞定
- 🔒 **安全至上** — API Key、Bot Token、SSH 私钥、OAuth 凭证，全部走加密 scp，不经过 GitHub。SHA256 校验防损坏。
- 🌐 **网络自适应** — 官方源 → Gitee 镜像 → 报错 + 排查指引
- ⏱️ **npm 超时检测** — 自动切换 npmmirror 国内镜像
- ♻️ **随时回滚** — 旧设备数据完整保留，失败可立即回滚

### 迁移内容

| 内容 | 说明 |
|------|------|
| `~/.openclaw/` | 配置、工作区、技能、插件、记忆、凭证 |
| `~/.claude/` | Claude Code 设置和 OAuth 凭证 |
| `~/.ssh/` | SSH 密钥（权限自动修正为 600） |
| crontab | 所有定时任务（路径自动修正） |
| /etc/hosts | 自定义 DNS 条目（如 Discord CDN） |
| Dashboard | 可选，如果存在则打包 |

### 新设备要求

- Ubuntu 22.04 / 24.04
- 2 核 CPU，2GB+ 内存
- SSH 登录 + sudo 权限

### 安装

```bash
# 在 OpenClaw 工作区
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git
```

或者告诉你的 Agent：*"帮我安装 agent-pack-n-go skill"*

### 使用

对你的 OpenClaw Agent 说：

> "帮我迁移到新设备"

Agent 会：
1. 询问新设备 SSH 信息
2. 运行 `pack.sh` 打包一切
3. `scp` 传输到新设备
4. 指导你在新设备执行 2 条命令

> ⚠️ **Discord Bot 注意**：同一个 Bot Token 不能在两台设备同时运行。Agent 会在新设备启动前停止旧设备，期间约 5 分钟离线。

### 时间估算

| 步骤 | 耗时 | 执行者 |
|------|------|--------|
| 迁移前检查 | 2 分钟 | 👤 回答问题 |
| Agent 打包 + 传输 | 5 分钟 | 🦁 自动 |
| `bash setup.sh` | 5 分钟 | 👤 1 条命令 |
| Claude Code 自动迁移 | 10-15 分钟 | 🤖 自动 |
| 验证 | 5 分钟 | 👤 |
| **总计** | **约 30 分钟** | |

### 许可证

MIT
