#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Accept old_user as arg or read from old_user.txt
if [ -n "$1" ]; then
    OLD_USER="$1"
elif [ -f ~/openclaw-migration-tmp/old_user.txt ]; then
    OLD_USER=$(cat ~/openclaw-migration-tmp/old_user.txt)
elif [ -f /tmp/old_user.txt ]; then
    OLD_USER=$(cat /tmp/old_user.txt)
else
    OLD_USER=$(whoami)
fi

OUTPUT=~/migration-instructions.md

cat > "$OUTPUT" << HEREDOC
# OpenClaw 迁移指令

> 这是一份给 Claude Code 的自动迁移指令。请按顺序执行所有步骤，每步完成后报告状态。
> 旧服务器用户名：\`${OLD_USER}\`

---

## 准备工作

首先解压迁移包到临时目录：

\`\`\`bash
mkdir -p ~/migration-tmp
tar xzf ~/openclaw-migration-pack.tar.gz -C ~/migration-tmp
OLD_USER="${OLD_USER}"
NEW_USER=\$(whoami)
\`\`\`

---

## Step 1：安装 openclaw 和 mcporter

\`\`\`bash
npm install -g openclaw
npm install -g mcporter

# 验证安装
which openclaw
which mcporter
openclaw --version
\`\`\`

---

## Step 2：恢复 OpenClaw 配置

\`\`\`bash
mkdir -p ~/.openclaw

# 恢复配置文件（不覆盖程序文件）
if [ -d ~/migration-tmp/openclaw-config ]; then
    cp -r ~/migration-tmp/openclaw-config/. ~/.openclaw/
    echo "OpenClaw 配置已恢复"
else
    echo "警告：迁移包中未找到 openclaw-config/"
fi
\`\`\`

---

## Step 3：路径修正

如果新旧服务器用户名不同，批量替换路径：

\`\`\`bash
OLD_USER="${OLD_USER}"
NEW_USER=\$(whoami)

if [ "\$OLD_USER" != "\$NEW_USER" ]; then
    echo "用户名变更：\$OLD_USER → \$NEW_USER，正在修正路径..."

    # 修正 openclaw.json 中的路径
    if [ -f ~/.openclaw/openclaw.json ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/.openclaw/openclaw.json
        echo "✅ openclaw.json 路径已修正"
    fi

    # 修正 CLAUDE.md 中的路径
    if [ -f ~/.openclaw/CLAUDE.md ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/.openclaw/CLAUDE.md
        echo "✅ CLAUDE.md 路径已修正"
    fi

    # 修正 crontab 备份中的路径
    if [ -f ~/migration-tmp/crontab-backup.txt ]; then
        sed -i "s|/home/\$OLD_USER|/home/\$NEW_USER|g" ~/migration-tmp/crontab-backup.txt
        echo "✅ crontab 路径已修正"
    fi
else
    echo "用户名相同（\$NEW_USER），无需路径修正"
fi
\`\`\`

---

## Step 4：恢复 /etc/hosts

\`\`\`bash
if [ -f ~/migration-tmp/hosts-custom.txt ] && [ -s ~/migration-tmp/hosts-custom.txt ]; then
    # 避免重复添加
    while IFS= read -r line; do
        [[ "\$line" =~ ^#.*$ || -z "\$line" ]] && continue
        if ! grep -qF "\$line" /etc/hosts; then
            echo "\$line" | sudo tee -a /etc/hosts > /dev/null
        fi
    done < ~/migration-tmp/hosts-custom.txt
    echo "✅ /etc/hosts 自定义条目已恢复"
else
    echo "⚠️  hosts-custom.txt 为空或不存在，跳过"
fi
\`\`\`

---

## Step 5：恢复 crontab

\`\`\`bash
if [ -f ~/migration-tmp/crontab-backup.txt ] && grep -qv '^#' ~/migration-tmp/crontab-backup.txt 2>/dev/null; then
    crontab ~/migration-tmp/crontab-backup.txt
    echo "✅ crontab 已恢复"
    crontab -l
else
    echo "⚠️  crontab 备份为空，跳过"
fi
\`\`\`

---

## Step 6：安装 proxychains4

\`\`\`bash
sudo apt-get install -y proxychains4

# 如果迁移包中有 proxychains 配置则恢复
if [ -f ~/migration-tmp/openclaw-config/proxychains4.conf ]; then
    sudo cp ~/migration-tmp/openclaw-config/proxychains4.conf /etc/proxychains4.conf
    echo "✅ proxychains4.conf 已恢复"
else
    echo "ℹ️  未找到 proxychains4.conf，使用默认配置"
fi
\`\`\`

---

## Step 7：检查 Claude Code nvm wrapper

\`\`\`bash
CLAUDE_BIN=~/.npm-global/bin/claude

# 检查是否是 nvm wrapper（应包含 nvm 相关内容）
if [ -f "\$CLAUDE_BIN" ]; then
    if grep -q 'nvm' "\$CLAUDE_BIN" 2>/dev/null; then
        echo "✅ Claude Code 已是 nvm wrapper"
    else
        echo "⚠️  Claude Code 不是 nvm wrapper，正在重建..."
        CLAUDE_ACTUAL=\$(find ~/.nvm -name 'claude' -type f 2>/dev/null | head -1)
        if [ -n "\$CLAUDE_ACTUAL" ]; then
            cat > "\$CLAUDE_BIN" << 'WRAPPER'
#!/bin/bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && source "\$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true
exec "\$(dirname "\$(readlink -f "\$0")")/../../lib/node_modules/@anthropic-ai/claude-code/cli.js" "\$@"
WRAPPER
            chmod +x "\$CLAUDE_BIN"
            echo "✅ nvm wrapper 已重建"
        else
            echo "ℹ️  未找到 claude 实际路径，跳过 wrapper 重建"
        fi
    fi
else
    echo "⚠️  未找到 \$CLAUDE_BIN"
fi
\`\`\`

---

## Step 8：启动 OpenClaw Gateway

\`\`\`bash
# 启动
openclaw gateway start

# 等待启动
sleep 3

# 配置 systemd 开机自启
systemctl --user daemon-reload
systemctl --user enable openclaw-gateway 2>/dev/null || true
systemctl --user start openclaw-gateway 2>/dev/null || true

# 防止退出 SSH 后服务被杀
sudo loginctl enable-linger \$USER

echo "✅ OpenClaw Gateway 已启动"
openclaw gateway status
\`\`\`

---

## Step 9：恢复 Dashboard（可选）

\`\`\`bash
if [ -d ~/migration-tmp/dashboard ]; then
    echo "发现 Dashboard 数据，正在恢复..."
    cp -r ~/migration-tmp/dashboard ~/openclaw-dashboard

    # 安装 Python 依赖
    if [ -f ~/openclaw-dashboard/backend/requirements.txt ]; then
        pip3 install -r ~/openclaw-dashboard/backend/requirements.txt
    fi

    echo "✅ Dashboard 已恢复到 ~/openclaw-dashboard/"
    echo "ℹ️  请手动配置 systemd service 以开机自启 Dashboard"
else
    echo "ℹ️  迁移包中无 Dashboard，跳过"
fi
\`\`\`

---

## Step 10：检查日志确认频道连接

\`\`\`bash
echo "=== 最近 50 行 OpenClaw 日志 ==="
journalctl --user -u openclaw-gateway --no-pager -n 50 2>/dev/null || \
    openclaw gateway logs 2>/dev/null || \
    echo "无法获取日志，请手动检查"

# 检查关键字
echo ""
echo "=== 连接状态检查 ==="
journalctl --user -u openclaw-gateway --no-pager -n 200 2>/dev/null | grep -Ei 'discord|feishu|connected|error|failed' | tail -20 || true
\`\`\`

---

## Step 11：清理迁移文件

\`\`\`bash
echo "正在清理敏感的迁移文件..."
rm -rf ~/migration-tmp
rm -f ~/openclaw-migration-pack.tar.gz
rm -f ~/setup.sh
echo "✅ 迁移临时文件已清理"
echo "ℹ️  migration-instructions.md 保留作为参考"
\`\`\`

---

## 完成后汇报

所有步骤完成后，请汇报：
1. OpenClaw 运行状态（\`openclaw gateway status\`）
2. systemd 服务状态（\`systemctl --user status openclaw-gateway\`）
3. 日志中是否有 Discord/飞书连接成功的信息
4. 是否有任何步骤失败或需要用户手动处理的事项

如有失败步骤，详细说明错误信息和建议的解决方案。
HEREDOC

echo -e "${GREEN}✅ migration-instructions.md 已生成：$OUTPUT${NC}"
