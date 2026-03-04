# agent-pack-n-go 📦🚀

**Migrate your OpenClaw + Claude Code to a new server in minutes, not hours.**

[中文版](#中文) | [English](#english)

---

<a id="english"></a>

## What It Does

An OpenClaw Skill that automates server migration. Your agent packs everything on the old server, you run **2 commands** on the new server, and you're done.

```
Old Server (Agent auto)           New Server (You: 2 commands)
┌──────────────────────┐          ┌──────────────────────┐
│ 1. Check Claude Code │          │ 3. bash setup.sh     │
│ 2. Pack + scp ───────┼─────────→│ 4. claude "migrate"  │
│    (stop old)        │          │    (auto completes)  │
└──────────────────────┘          └──────────────────────┘
                                           ↓
                                  Verify & done ✅
```

## Features

- **Minimal manual steps** — Agent handles packing, you run 2 commands
- **SHA256 integrity verification** — Both whole-pack and per-file checksums
- **Network fallback** — Official source → Gitee mirror → error with guidance
- **npm timeout detection** — Auto-switches to npmmirror if npm is slow
- **Safe transfer** — All sensitive data (API keys, tokens, SSH keys) via scp, never GitHub
- **Rollback ready** — Old server untouched, restart anytime if something fails

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

**New server:**
- Ubuntu 22.04 / 24.04
- 2-core CPU, 8GB+ RAM
- SSH access with sudo

**Old server:**
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

> "帮我迁移到新服务器" / "migrate to a new server"

The agent will:
1. Ask for new server SSH info
2. Run `pack.sh` to bundle everything
3. `scp` the pack to the new server
4. Stop the old server
5. Guide you through 2 commands on the new server

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
│   ├── pack.sh                 # Old server: pack everything (10 steps)
│   ├── setup.sh                # New server: install environment (11 steps)
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

一个 OpenClaw Skill，自动化服务器迁移。Agent 在旧服务器打包一切，你在新服务器跑 **2 条命令**，搞定。

```
旧服务器（Agent 自动）              新服务器（你：2 条命令）
┌──────────────────────┐          ┌──────────────────────┐
│ 1. 检查 Claude Code  │          │ 3. bash setup.sh     │
│ 2. 打包 + scp ───────┼─────────→│ 4. claude "迁移"     │
│    (停旧服务)        │          │    (自动完成)        │
└──────────────────────┘          └──────────────────────┘
                                           ↓
                                  验证通过 ✅
```

### 特性

- **最少手动操作** — Agent 处理打包，你只跑 2 条命令
- **SHA256 完整性校验** — 整包校验 + 关键文件逐一校验
- **网络三级降级** — 官方源 → Gitee 镜像 → 报错 + 排查指引
- **npm 超时检测** — 自动切换 npmmirror 国内镜像
- **安全传输** — 所有敏感数据（API Key、Token、SSH 密钥）走 scp，不经过 GitHub
- **随时回滚** — 旧服务器数据完整保留，失败可立即回滚

### 迁移内容

| 内容 | 说明 |
|------|------|
| `~/.openclaw/` | 配置、工作区、技能、插件、记忆、凭证 |
| `~/.claude/` | Claude Code 设置和 OAuth 凭证 |
| `~/.ssh/` | SSH 密钥（权限自动修正为 600） |
| crontab | 所有定时任务（路径自动修正） |
| /etc/hosts | 自定义 DNS 条目（如 Discord CDN） |
| Dashboard | 可选，如果存在则打包 |

### 新服务器要求

- Ubuntu 22.04 / 24.04
- 2 核 CPU，8GB+ 内存
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

> "帮我迁移到新服务器"

Agent 会：
1. 询问新服务器 SSH 信息
2. 运行 `pack.sh` 打包一切
3. `scp` 传输到新服务器
4. 停止旧服务器
5. 指导你在新服务器执行 2 条命令

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
