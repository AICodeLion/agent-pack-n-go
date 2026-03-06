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
    <a href="#中文">中文</a>
  </p>
</div>

---

## ⚡ Quick Start

```bash
# Install
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git

# Use — just tell your agent:
"Clone my agent to a new device"
```

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

## 📝 Requirements

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

---

<a id="中文"></a>

<div align="center">
  <h1>agent-pack-n-go</h1>
  <p><strong>一句话克隆你的 AI Agent 到新设备。全自动，零云依赖。</strong></p>
  <p>
    <a href="#quick-start">English</a> •
    <a href="#快速开始">快速开始</a> •
    <a href="#使用场景">使用场景</a> •
    <a href="#工作流程">工作流程</a>
  </p>
</div>

---

## 快速开始

```bash
# 安装
cd ~/.openclaw/skills
git clone https://github.com/AICodeLion/agent-pack-n-go.git

# 使用 — 对你的 Agent 说：
"帮我克隆到新设备"
```

Agent 会询问 SSH 信息，然后全自动完成。总耗时约 25 分钟，SSH 配置后无需手动操作。

---

## 使用场景

| 场景 | 说明 |
|------|------|
| 克隆 | 迁移到更快的机器，或在另一台设备运行副本 |
| 快照 | 保存 tarball 作为时间点备份，随时分钟级恢复 |
| 团队部署 | 将调教好的 Agent 克隆给多个团队成员 |
| 本地 → 云端 | 本地开发，一条命令部署到生产环境 |

---

## 工作流程

Agent 在旧设备上通过 SSH 控制一切，你只需确认。

```
旧设备（Agent 全程控制）                  新设备（SSH 远程）
┌──────────────────────────────┐        ┌───────────────────────┐
│  1. 克隆前检查                │        │                       │
│  2. 网络诊断                  │────→   │  直连 / 需代理？       │
│  3. 打包 + 传输               │────→   │  文件 + SHA256 ✓      │
│  4. setup.sh                  │────→   │  nvm + Node + Claude  │
│  5. deploy.sh                 │────→   │  OpenClaw 部署完毕     │
│  6. 引导切换                  │        │  ✅ Agent 上线         │
└──────────────────────────────┘        └───────────────────────┘
```

| 阶段 | 内容 | 耗时 | 执行者 |
|------|------|------|--------|
| 克隆前检查 | SSH 密钥配置、连通性验证 | ~3 分钟 | 用户 |
| 网络诊断 | 自动识别直连 / 代理环境 | 即时 | Agent |
| 打包与传输 | 打包 + rsync + SHA256 校验 | ~5 分钟 | Agent |
| 环境安装 | 安装 nvm、Node.js 22、Claude Code | ~5 分钟 | Agent |
| 部署 | OpenClaw + 恢复配置 + 启动 Gateway | ~5 分钟 | Agent |
| 验证 | 引导式三步验证 | ~3 分钟 | 用户 |

---

## 克隆内容

| 内容 | 说明 |
|------|------|
| `~/.openclaw/` | 配置、工作区、技能、插件、记忆、凭证 |
| `~/.claude/` | Claude Code 设置和 OAuth 凭证 |
| `~/.ssh/` | SSH 密钥（权限自动修正为 600） |
| crontab | 定时任务，路径自动修正为新用户名 |
| /etc/hosts | 自定义 DNS 条目 |
| Dashboard | 可选 — 存在则打包 |

---

## 安全性

| 措施 | 说明 |
|------|------|
| 三重 SHA256 校验 | 打包、传输、安装每个阶段验证完整性 |
| 纯 SSH 传输 | 不经过任何云或第三方，凭证始终在加密通道中 |
| SUDO_OK 模式 | 没有免密 sudo 时优雅跳过，不中断流程 |

---

## 核心特性

| 特性 | 说明 |
|------|------|
| 自然语言触发 | 任何语言说"克隆到新设备"即可 |
| 网络自动识别 | 直连 / 代理环境自适应 |
| 实时进度反馈 | 每个阶段在聊天中推送进度 |
| 路径自动修正 | `/home/旧用户` → `/home/新用户` 全局替换 |
| rsync + 降级 | rsync 不可用时自动回退到 scp |
| 随时回滚 | tarball 保留，随时重启旧设备恢复 |

---

## 为什么选 agent-pack-n-go

```
备份 = 存文件 → 手动装环境 → 手动配置 → 祈祷能跑
克隆 = 数据 + 运行时 + 凭证 + 系统配置 → Agent 落地即运行
```

| 功能 | agent-pack-n-go | agent-life | OpenClaw Backup | GitClaw | 官方文档 |
|------|:-:|:-:|:-:|:-:|:-:|
| 完整设备克隆 | ✅ | — | — | — | — |
| 一句话触发 | ✅ | ✅ | CLI | Cron | ❌ |
| 运行时自动安装 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 凭证传输 | ✅ | ✅ | ❌ | ❌ | 手动 |
| 系统配置恢复 | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gateway 自启 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 网络诊断 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 零第三方依赖 | ✅ | ❌ | ❌ | ❌ | ✅ |
| 优雅降级 | ✅ | — | ❌ | ❌ | ❌ |
| 完整性校验 | ✅ | ✅ | ❌ | ❌ | ❌ |

---

## 设备要求

| | 旧设备 | 新设备 |
|---|-------|--------|
| 系统 | 任何运行 OpenClaw 的 Linux | Ubuntu 22.04 / 24.04 |
| 硬件 | — | 2 核 CPU，2GB+ 内存 |
| 访问 | — | SSH + sudo（推荐） |

---

## 项目结构

```
agent-pack-n-go/
├── SKILL.md                      # Agent 工作流与指令定义
├── scripts/
│   ├── pack.sh                   # 打包（11 步）
│   ├── transfer.sh               # rsync + SHA256 校验
│   ├── setup.sh                  # 基础环境安装（12 步）
│   ├── deploy.sh                 # OpenClaw 部署（13 步）
│   ├── network-check.sh          # 网络连通性诊断
│   ├── generate-instructions.sh  # 备用手动指南生成
│   └── welcome.sh                # 安装后欢迎信息
└── references/
    ├── migration-guide.md        # 完整手动参考
    └── troubleshooting.md        # 常见问题与修复
```

---

## 相关项目

- [OpenClaw](https://github.com/openclaw/openclaw) — 本 Skill 所基于的 AI Agent 框架
- [agent-life](https://agent-life.ai/) — 跨框架 Agent 迁移方案
- [OpenClaw 迁移指南](https://docs.openclaw.ai/install/migrating) — 官方手动迁移文档

---

## 许可证

[MIT](LICENSE)
