# 常见问题排查表

## 1. Anthropic API 返回 403

**现象**：`claude` 命令报错 403 Forbidden，或消息无响应

**原因**：Anthropic 封锁了国内 IP 直连

**解决方案**：
```bash
# 使用第三方 API 代理，修改 ~/.claude/settings.json
# 将 apiBaseUrl 改为代理地址
{
  "apiBaseUrl": "https://your-api-proxy.example.com",
  "apiKey": "sk-..."
}
```
不要直连 `api.anthropic.com`，换用支持国内访问的代理服务。

---

## 2. Claude Code 启动失败（nvm wrapper 被覆盖）

**现象**：`claude` 命令报错 `node: not found` 或 `bad interpreter`，或使用了系统旧版 Node

**原因**：`npm install -g` 重新安装 Claude Code 时覆盖了 nvm wrapper，导致 claude 直接调用系统 node 而非 nvm 管理的 Node 22

**解决方案**：
```bash
# 重建 nvm wrapper
cat > ~/.npm-global/bin/claude << 'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true
exec "$(dirname "$(readlink -f "$0")")/../../lib/node_modules/@anthropic-ai/claude-code/cli.js" "$@"
EOF
chmod +x ~/.npm-global/bin/claude

# 验证
claude --version
node --version  # 应为 v22.x.x
```

---

## 3. Discord 图片无法加载

**现象**：Discord 文字消息正常，但图片/附件无法加载或显示失败

**原因**：Discord CDN 域名（`cdn.discordapp.com` 等）在国内 DNS 解析失败或被污染

**解决方案**：
```bash
# 在 /etc/hosts 中添加 Discord CDN 静态解析
# 先用 nslookup 在境外查到正确 IP，然后：
sudo tee -a /etc/hosts << 'EOF'
162.159.128.233 cdn.discordapp.com
162.159.128.233 media.discordapp.net
EOF

# 验证
ping cdn.discordapp.com
```

---

## 4. workspace 路径报错（用户名不同）

**现象**：OpenClaw 报错 `ENOENT: no such file or directory /home/olduser/...`

**原因**：新旧服务器用户名不同，`openclaw.json` 中的绝对路径仍指向旧用户目录

**解决方案**：
```bash
OLD_USER="旧用户名"
NEW_USER=$(whoami)

# 批量替换 openclaw.json 中的路径
sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/openclaw.json

# 同时修正 CLAUDE.md
sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/CLAUDE.md

# 验证
grep "/home/" ~/.openclaw/openclaw.json | head -5
```

---

## 5. git push 失败（SSH 密钥权限）

**现象**：`git push` 报错 `WARNING: UNPROTECTED PRIVATE KEY FILE!` 或 `Permission denied (publickey)`

**原因**：SSH 私钥权限过宽（不能是 644，必须是 600）

**解决方案**：
```bash
# 修正私钥权限
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_rsa  # 如果有 rsa 密钥
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

# 验证
ls -la ~/.ssh/
# 私钥应显示 -rw-------

# 测试 SSH 连接
ssh -T git@github.com
```

---

## 6. 退出 SSH 后服务停止（systemd session 被杀）

**现象**：SSH 断开后，OpenClaw 自动停止；journalctl 显示 `session closed`

**原因**：用户 systemd session 在 SSH 断开时被终止，所有用户级服务随之停止

**解决方案**：
```bash
# 允许用户 session 在退出后继续运行
sudo loginctl enable-linger $USER

# 验证
loginctl show-user $USER | grep Linger
# 应显示 Linger=yes

# 重新启动服务
systemctl --user start openclaw-gateway
```

---

## 7. OpenClaw 端口占用

**现象**：`openclaw gateway start` 报错 `EADDRINUSE: address already in use :::端口号`

**原因**：上次进程未正常退出，或有僵尸进程占用端口

**解决方案**：
```bash
# 查找占用端口的进程（默认端口通常是 3000 或 8080）
PORT=$(grep -o '"port":[0-9]*' ~/.openclaw/openclaw.json | grep -o '[0-9]*' | head -1)
lsof -i :$PORT

# 杀掉占用进程
kill -9 $(lsof -ti :$PORT)

# 或者修改 openclaw.json 换用其他端口
# 重新启动
openclaw gateway start
```

---

## 8. Discord Bot 离线（两台同时运行）

**现象**：Bot 在 Discord 显示离线，或消息延迟极高、经常断线重连

**原因**：同一个 Bot Token 在两台服务器同时运行，Discord 会强制踢掉旧连接，导致频繁重连

**解决方案**：
```bash
# 在旧服务器上停止 OpenClaw
systemctl --user stop openclaw-gateway

# 确认旧服务器已停止后，在新服务器重启
systemctl --user restart openclaw-gateway

# 验证只有一个实例运行
# 检查旧服务器
# systemctl --user status openclaw-gateway  # 应显示 inactive
```
迁移期间必须保证同一时间只有一台服务器运行。

---

## 9. npm install 超时（国内网络）

**现象**：`npm install` 卡住，最终报错 `ETIMEDOUT` 或 `ECONNRESET`

**原因**：国内网络访问 `registry.npmjs.org` 很慢或不通

**解决方案**：
```bash
# 切换到 npmmirror 国内镜像
npm config set registry https://registry.npmmirror.com

# 验证配置
npm config get registry

# 重试安装
npm install -g @anthropic-ai/claude-code

# 安装完成后可以恢复（可选）
# npm config set registry https://registry.npmjs.org
```

---

## 10. Node.js 版本不对（系统自带旧版）

**现象**：`node --version` 显示 v12/v14/v16，Claude Code 报错版本不兼容

**原因**：shell 优先使用了 `/usr/bin/node`（系统包管理器安装的旧版），而非 nvm 管理的 Node 22

**解决方案**：
```bash
# 确认 nvm 已加载
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

# 切换到 Node 22
nvm use 22
nvm alias default 22

# 确保 ~/.bashrc 包含 nvm 初始化（重新登录后生效）
grep 'nvm' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' >> ~/.bashrc

# 验证
node --version   # 应为 v22.x.x
which node       # 应为 ~/.nvm/versions/node/v22.x.x/bin/node
```

---

## 11. setup.sh 权限不足

**现象**：`./setup.sh` 报错 `Permission denied`

**原因**：脚本文件没有可执行权限

**解决方案**：
```bash
# 方法 1：用 bash 直接运行（无需执行权限）
bash ~/setup.sh

# 方法 2：添加执行权限后运行
chmod +x ~/setup.sh
./setup.sh
```
推荐始终使用 `bash ~/setup.sh` 方式，避免权限问题。

---

## 12. 飞书连不上（应用未发布）

**现象**：飞书消息无响应，日志显示连接失败或鉴权错误

**原因**：
- 飞书应用未发布（仍在开发/测试状态）
- 应用权限过期或被撤销
- Bot 未被添加到目标群组

**解决方案**：
1. 登录[飞书开放平台](https://open.feishu.cn/)
2. 进入应用管理 → 找到对应应用
3. 检查应用状态是否为**已发布**
4. 检查**权限管理** → 确认消息相关权限已申请并通过
5. 在目标群组中 **@机器人** 并将其加入群组
6. 如果是企业应用，确认企业管理员已审批应用发布

```bash
# 检查飞书相关日志
journalctl --user -u openclaw-gateway --no-pager -n 100 | grep -i feishu
```
