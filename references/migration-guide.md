# OpenClaw 服务器迁移操作手册（完整版）

> **目标**：把旧服务器的 OpenClaw + Claude Code 完整迁移到新 Ubuntu 服务器
> **原则**：用户只做最少的手动操作，其余全交给 Agent
> **前提**：旧服务器已有运行中的 OpenClaw

---

## 总览：迁移全流程

```
阶段一：迁移前检查
阶段二：旧服务器准备（Agent 执行）
阶段三：新服务器部署（用户 2 条命令 + Claude Code 自动）
阶段四：验证 + 切换
阶段五：善后
```

### 谁做什么

| 步骤 | 执行者 | 用户操作 |
|------|--------|----------|
| 迁移前检查 | 🦁 Agent | 回答几个问题 |
| 检查/安装 Claude Code | 🦁 Agent | 提供 API 信息（如需） |
| 打包 + 传输 | 🦁 Agent | 提供新服务器 SSH 信息 |
| 新服务器装环境 | 👤 用户 | 跑 1 条命令：`bash ~/setup.sh` |
| 安装 OpenClaw + 恢复 | 🤖 Claude Code | 跑 1 条命令启动 Claude Code |
| 验证 | 👤 用户 | 发消息测试 |
| 善后 | 👤 用户 | 确认后关旧服务器 |

---

## 阶段一：迁移前检查

> 目的：确认迁移条件满足，避免中途卡住

### 1.1 新服务器要求

- [ ] **操作系统**：Ubuntu 22.04 / 24.04（推荐）
- [ ] **配置**：2 核 CPU，8G 内存以上
- [ ] **SSH 可登录**：有 root 或 sudo 权限的用户
- [ ] **网络**：
  - 能访问 npm 仓库（国内可用 npmmirror 加速）
  - 能访问你的 AI API 提供商（第三方代理无需翻墙）
  - 如需 Discord：需要代理/VPN

### 1.2 需要准备的信息

| 信息 | 说明 | 示例 |
|------|------|------|
| 新服务器 IP | SSH 登录用 | 1.2.3.4 |
| SSH 用户名 | 新服务器的用户 | admin / root / ubuntu |
| SSH 密码或密钥 | 登录认证 | 密码或 .pem 文件 |
| API 信息（如需） | Claude Code 的 API 代理地址 + Key | 仅旧服务器没有 Claude Code 时需要 |

### 1.3 重要提醒

⚠️ **Discord Bot 不能同时在两台服务器运行**
- 同一个 Bot Token 只能一个实例在线
- 迁移时需要先停旧服务器，再启新服务器
- 会有短暂离线时间（约 5-10 分钟）

⚠️ **敏感信息安全**
- 迁移包里包含 API Key、Bot Token 等敏感信息
- 传输走 scp（加密通道），不走公开渠道
- 迁移完成后清理新服务器上的迁移包文件

---

## 阶段二：旧服务器准备（🦁 Agent 执行）

> 用户对 Agent 说："帮我准备迁移"，Agent 自动完成以下所有步骤

### 2.1 检查/安装 Claude Code

Agent 自动检查 Claude Code 是否已安装：

**✅ 已安装** → 验证能用，跳到 2.2

**❌ 未安装** → Agent 自动执行：

```bash
# 1. 安装
npm install -g @anthropic-ai/claude-code

# 2. Agent 向用户询问 API 信息：
#    - API 代理地址（如 https://api.fluxnode.org）
#    - API Key
#    用户通过 Discord/飞书 回复即可

# 3. Agent 写入配置
# ~/.claude/settings.json

# 4. Agent 测试
claude "hello test"
# → 成功：告诉用户 "Claude Code 已就绪 ✅"
# → 失败：排查问题，再次询问用户
```

> 👤 用户操作：仅需提供 API 信息（如果没有 Claude Code 的话）

### 2.2 打包迁移文件

Agent 自动创建迁移包，包含：

```
~/openclaw-migration-pack.tar.gz
│
├── openclaw-config/                → 恢复到 ~/.openclaw/
│   ├── openclaw.json               ← 核心配置（API Key、频道 Token、模型设置等）
│   ├── credentials/                ← Discord/飞书认证文件
│   ├── skills/                     ← 已安装的 Agent Skill
│   │   ├── agent-reach/
│   │   ├── capability-evolver/
│   │   └── skill-vetter/
│   ├── extensions/                 ← 已安装的插件
│   │   └── openclaw-tavily/
│   ├── memory/                     ← 记忆数据库（main.sqlite 等）
│   ├── feishu/                     ← 飞书相关文件
│   ├── workspace/                  ← 工作区（笔记、记忆、脚本、任务等）
│   ├── workspace-coder/            ← 子代理 workspace
│   ├── workspace-paper-tracker/    ← 子代理 workspace
│   ├── CLAUDE.md                   ← Agent 指令文件
│   └── exec-approvals.json         ← 已批准的执行权限
│
├── claude-config/                  → 恢复到 ~/.claude/
│   ├── settings.json               ← API 配置
│   ├── projects/                   ← 项目配置
│   └── ...
│
├── ssh-keys/                       → 恢复到 ~/.ssh/
│   ├── id_ed25519                  ← 私钥（用于 git push 等）
│   ├── id_ed25519.pub
│   ├── config
│   └── known_hosts
│
├── crontab-backup.txt              ← 定时任务备份
├── hosts-custom.txt                ← /etc/hosts 自定义条目
│
└── dashboard/                      → 恢复到 ~/openclaw-dashboard/（可选）
    ├── backend/
    ├── frontend/
    └── ...
```

### 2.3 生成辅助文件

Agent 自动生成两个关键文件：

**① `setup.sh` — 新服务器一键安装脚本**

功能：
- 安装 nvm + Node.js 22
- 配置 npm 全局路径 `~/.npm-global`
- 安装 Claude Code
- 从迁移包恢复 `~/.claude/` 配置
- 从迁移包恢复 `~/.ssh/` 密钥（权限设为 600）
- 验证 Claude Code 可用
- 安装基础依赖（git, curl, python3 等）

**② `migration-instructions.md` — 给 Claude Code 的迁移指令**

内容：Claude Code 需要执行的所有迁移步骤（详见阶段三）

### 2.4 传输到新服务器

用户提供新服务器 SSH 信息后，Agent 执行：

```bash
scp ~/openclaw-migration-pack.tar.gz \
    ~/setup.sh \
    ~/migration-instructions.md \
    用户名@新服务器IP:~/
```

> 👤 用户操作：提供新服务器 IP + SSH 用户名 + 密码/密钥

### 2.5 停止旧服务器 OpenClaw

⚠️ **重要**：在新服务器启动前停止旧服务器，避免 Discord Bot 冲突

```bash
# Agent 在确认新服务器文件传输完毕后执行
systemctl --user stop openclaw-gateway
```

Agent 会告诉用户："旧服务器已停止，请到新服务器执行 setup.sh"


---

## 阶段三：新服务器部署

### Step 1：跑安装脚本 👤

SSH 登录新服务器，执行一条命令：

```bash
bash ~/setup.sh
```

脚本执行过程（全自动，约 5 分钟）：

```
[1/7] 安装 nvm...                    ✅
[2/7] 安装 Node.js 22...             ✅
[3/7] 配置 npm 全局路径...            ✅
[4/7] 安装 Claude Code...            ✅
[5/7] 恢复 Claude Code 配置...       ✅
[6/7] 恢复 SSH 密钥...               ✅
[7/7] 验证 Claude Code...            ✅

✅ 基础环境就绪！请执行下一步：
claude --dangerously-skip-permissions "按照 ~/migration-instructions.md 完成 OpenClaw 迁移"
```

> 如果某步失败，脚本会停下来并显示错误信息。
> 常见问题：npm 下载慢 → 设置国内镜像（脚本会自动检测并提示）

### Step 2：让 Claude Code 完成迁移 👤

```bash
claude --dangerously-skip-permissions "按照 ~/migration-instructions.md 完成 OpenClaw 迁移"
```

Claude Code 会根据 `migration-instructions.md` 自动完成以下所有步骤：

#### 3.1 安装 OpenClaw 及工具

```bash
npm install -g openclaw
npm install -g mcporter
# 验证
which openclaw  # ~/.npm-global/bin/openclaw
```

#### 3.2 恢复 OpenClaw 配置

```bash
# 解压迁移包
tar xzf ~/openclaw-migration-pack.tar.gz -C ~/migration-tmp/

# 恢复 ~/.openclaw/ 目录
cp -r ~/migration-tmp/openclaw-config/* ~/.openclaw/
# 注意：不覆盖刚安装的 OpenClaw 程序文件（node_modules 等）
```

#### 3.3 路径修正

检查新服务器用户名，如果与旧服务器不同：

```bash
OLD_USER="admin"  # 旧服务器用户名
NEW_USER=$(whoami)

if [ "$OLD_USER" != "$NEW_USER" ]; then
    # 批量替换 openclaw.json 中的路径
    sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/openclaw.json
    
    # 替换 crontab 中的路径
    sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/migration-tmp/crontab-backup.txt
fi
```

#### 3.4 系统配置恢复

```bash
# /etc/hosts — Discord CDN 解析（国内服务器需要）
sudo tee -a /etc/hosts < ~/migration-tmp/hosts-custom.txt

# crontab — 恢复定时任务
crontab ~/migration-tmp/crontab-backup.txt

# 安装 proxychains4
sudo apt install -y proxychains4
# 配置 /etc/proxychains4.conf
```

#### 3.5 代理服务部署

> 给 Discord 等需要翻墙的服务使用
> Claude Code 会根据旧服务器的代理配置，在新服务器上部署相同方案

```bash
# 安装代理软件
# 配置代理规则
# 启动代理服务
# 验证 127.0.0.1:10808 可用
```

#### 3.6 Claude Code nvm Wrapper 检查

```bash
# 检查 ~/.npm-global/bin/claude 是否是 nvm wrapper
# 如果被 npm install 覆盖成了直接链接，需要重建
# wrapper 确保使用 nvm 的 Node 22 而不是系统自带的旧版本
```

#### 3.7 启动 OpenClaw

```bash
# 启动
openclaw gateway start

# 配置 systemd 开机自启
# （使用 openclaw 自带的 service 文件，或从迁移包恢复）
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway
systemctl --user start openclaw-gateway

# 防止退出 SSH 后服务被杀
sudo loginctl enable-linger $USER
```

#### 3.8 恢复 Dashboard（可选）

```bash
# 如果迁移包里有 dashboard
cp -r ~/migration-tmp/dashboard/ ~/openclaw-dashboard/
pip3 install -r ~/openclaw-dashboard/backend/requirements.txt
# 配置 systemd service
```

#### 3.9 日志检查

```bash
# 检查 OpenClaw 日志
journalctl --user -u openclaw-gateway --no-pager -n 50

# 确认频道连接状态
# - Discord: 看日志里是否有 "discord connected" 类似信息
# - 飞书: 看日志里是否有 feishu 长连接建立信息
```

#### 3.10 清理迁移文件

```bash
# 迁移完成后清理敏感文件
rm -rf ~/migration-tmp/
rm ~/openclaw-migration-pack.tar.gz
rm ~/setup.sh
# migration-instructions.md 可以保留作为参考
```


---

## 阶段四：验证 👤

### 4.1 基础验证

| 检查项 | 方法 | 预期结果 |
|--------|------|----------|
| OpenClaw 运行 | `openclaw gateway status` | 显示运行中 |
| Discord 收发 | 在 Discord 发消息 | Agent 正常回复 |
| 飞书收发 | 在飞书发消息 | Agent 正常回复 |
| 记忆完整 | 问 Agent "你记得我是谁吗" | 能回忆用户信息 |
| 定时任务 | `crontab -l` | 显示所有定时任务 |
| Claude Code | `claude "test"` | 正常对话 |
| Git 推送 | `cd ~/.openclaw/workspace && git push` | 推送成功 |

### 4.2 进阶验证（可选）

- [ ] 心跳正常（等一个心跳周期，检查是否触发）
- [ ] Dashboard 可访问（如果有）
- [ ] 子代理可用（在 Discord 触发一个需要 Claude Code 的任务）
- [ ] 自动 git 提交正常（等一个周期或手动触发脚本）

### 4.3 验证不通过怎么办

**回滚方案**：重新启动旧服务器的 OpenClaw

```bash
# 在旧服务器上
systemctl --user start openclaw-gateway
```

旧服务器的数据完全没动过，随时可以回滚。

---

## 阶段五：善后

### 5.1 观察期

- 新服务器运行 **3-7 天**，确认稳定
- 期间留意：
  - 频道消息是否偶尔丢失
  - 定时任务是否都正常触发
  - 内存/CPU 使用是否正常
  - 日志里是否有异常错误

### 5.2 关停旧服务器

确认稳定后：

```bash
# 旧服务器上
systemctl --user stop openclaw-gateway
systemctl --user disable openclaw-gateway

# 可选：清理旧服务器上的迁移包
rm ~/openclaw-migration-pack.tar.gz
```

### 5.3 更新记录

- 更新 MEMORY.md 记录迁移事件
- 更新 TOOLS.md 里的服务器信息（新 IP 等）
- 如果有 Dashboard，更新安全组/防火墙规则

---

## ⚠️ 踩坑备忘

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Anthropic API 403 | 国内 IP 被 Anthropic 封锁 | 使用第三方 API 代理（改 baseUrl） |
| Claude Code 启动失败 | npm install 覆盖了 nvm wrapper | 重建 bash wrapper 脚本 |
| Discord 图片无法加载 | CDN DNS 解析失败 | /etc/hosts 加 Discord CDN 静态解析 |
| workspace 路径报错 | 新旧服务器用户名不同 | sed 批量替换 openclaw.json 中的路径 |
| git push 失败 | SSH 密钥权限不对 | `chmod 600 ~/.ssh/id_ed25519` |
| 退出 SSH 后服务挂了 | systemd user session 被终止 | `sudo loginctl enable-linger $USER` |
| OpenClaw 端口占用 | 旧进程没清理干净 | kill 旧进程或在 openclaw.json 换端口 |
| Discord Bot 离线 | 两台服务器同时用同一个 Token | 确保旧服务器已停止再启动新的 |
| npm install 超时 | 国内网络访问 npm 慢 | 设置 npmmirror：`npm config set registry https://registry.npmmirror.com` |
| Node.js 版本不对 | 用了系统自带的旧版本 | 确认 `nvm use 22`，检查 `node -v` |
| setup.sh 权限不足 | 脚本没有执行权限 | `chmod +x ~/setup.sh` 或用 `bash ~/setup.sh` |
| 飞书连不上 | 应用未发布或权限过期 | 检查飞书开放平台应用状态 |

---

## 时间估算

| 步骤 | 耗时 | 执行者 |
|------|------|--------|
| 迁移前检查 | 2 分钟 | 👤 回答问题 |
| Agent 检查/安装 Claude Code | 0-5 分钟 | 🦁 自动 |
| Agent 打包 + scp | 5 分钟 | 🦁 自动 |
| 新服务器 `bash setup.sh` | 5 分钟 | 👤 1 条命令 |
| Claude Code 自动迁移 | 10-15 分钟 | 🤖 自动 |
| 验证 | 5 分钟 | 👤 |
| **总计** | **约 30 分钟** | |

---

## 附录：迁移涉及的关键文件

| 文件/目录 | 作用 | 重要程度 |
|-----------|------|----------|
| `~/.openclaw/openclaw.json` | 核心配置（API Key、频道、模型等） | ⭐⭐⭐ 必须 |
| `~/.openclaw/credentials/` | 频道认证文件 | ⭐⭐⭐ 必须 |
| `~/.openclaw/workspace/` | 工作区（记忆、笔记、脚本） | ⭐⭐⭐ 必须 |
| `~/.openclaw/skills/` | 已安装的 Skill | ⭐⭐ 重要 |
| `~/.openclaw/extensions/` | 已安装的插件 | ⭐⭐ 重要 |
| `~/.openclaw/memory/` | 记忆数据库 | ⭐⭐ 重要 |
| `~/.claude/` | Claude Code 配置 | ⭐⭐ 重要 |
| `~/.ssh/` | SSH 密钥（git 等） | ⭐⭐ 重要 |
| crontab | 定时任务 | ⭐⭐ 重要 |
| /etc/hosts | DNS 解析 | ⭐ 可选（国内需要） |
| Dashboard | 监控面板 | ⭐ 可选 |
