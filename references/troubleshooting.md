# Troubleshooting Guide

## 1. Anthropic API returns 403

**Symptom**: `claude` command reports 403 Forbidden, or messages get no response

**Cause**: Anthropic blocks direct connections from China IPs

**Solution**:
```bash
# Use a third-party API proxy, modify ~/.claude/settings.json
# Change apiBaseUrl to your proxy address
{
  "apiBaseUrl": "https://your-api-proxy.example.com",
  "apiKey": "sk-..."
}
```
Do not connect directly to `api.anthropic.com`; use a proxy service that supports access from China.

---

## 2. Claude Code fails to start (nvm wrapper overwritten)

**Symptom**: `claude` command reports `node: not found` or `bad interpreter`, or uses system's old Node version

**Cause**: `npm install -g` reinstalling Claude Code overwrote the nvm wrapper, causing claude to call the system node instead of nvm-managed Node 22

**Solution**:
```bash
# Rebuild the nvm wrapper
cat > ~/.npm-global/bin/claude << 'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use 22 --silent 2>/dev/null || true
exec "$(dirname "$(readlink -f "$0")")/../../lib/node_modules/@anthropic-ai/claude-code/cli.js" "$@"
EOF
chmod +x ~/.npm-global/bin/claude

# Verify
claude --version
node --version  # should be v22.x.x
```

---

## 3. Discord images fail to load

**Symptom**: Discord text messages work fine, but images/attachments fail to load or display

**Cause**: Discord CDN domains (`cdn.discordapp.com`, etc.) fail DNS resolution or are polluted in China

**Solution**:
```bash
# Add Discord CDN static entries to /etc/hosts
# First use nslookup from outside China to get the correct IPs, then:
sudo tee -a /etc/hosts << 'EOF'
162.159.128.233 cdn.discordapp.com
162.159.128.233 media.discordapp.net
EOF

# Verify
ping cdn.discordapp.com
```

---

## 4. workspace path errors (different username)

**Symptom**: OpenClaw reports `ENOENT: no such file or directory /home/olduser/...`

**Cause**: Username differs between old and new server; absolute paths in `openclaw.json` still point to the old user's home directory

**Solution**:
```bash
OLD_USER="old-username"
NEW_USER=$(whoami)

# Bulk-replace paths in openclaw.json
sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/openclaw.json

# Also fix CLAUDE.md
sed -i "s|/home/$OLD_USER|/home/$NEW_USER|g" ~/.openclaw/CLAUDE.md

# Verify
grep "/home/" ~/.openclaw/openclaw.json | head -5
```

---

## 5. git push fails (SSH key permissions)

**Symptom**: `git push` reports `WARNING: UNPROTECTED PRIVATE KEY FILE!` or `Permission denied (publickey)`

**Cause**: SSH private key permissions are too broad (must not be 644, must be 600)

**Solution**:
```bash
# Fix private key permissions
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_rsa  # if rsa key exists
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

# Verify
ls -la ~/.ssh/
# Private keys should show -rw-------

# Test SSH connection
ssh -T git@github.com
```

---

## 6. Service stops after SSH logout (systemd session killed)

**Symptom**: OpenClaw stops automatically after SSH disconnect; journalctl shows `session closed`

**Cause**: User systemd session is terminated when SSH disconnects, stopping all user-level services

**Solution**:
```bash
# Allow user session to continue after logout
sudo loginctl enable-linger $USER

# Verify
loginctl show-user $USER | grep Linger
# Should show Linger=yes

# Restart the service
systemctl --user start openclaw-gateway
```

---

## 7. OpenClaw port already in use

**Symptom**: `openclaw gateway start` reports `EADDRINUSE: address already in use :::PORT`

**Cause**: Previous process did not exit cleanly, or a zombie process is holding the port

**Solution**:
```bash
# Find the process using the port (default port is usually 3000 or 8080)
PORT=$(grep -o '"port":[0-9]*' ~/.openclaw/openclaw.json | grep -o '[0-9]*' | head -1)
lsof -i :$PORT

# Kill the process holding the port
kill -9 $(lsof -ti :$PORT)

# Or change the port in openclaw.json
# Then restart
openclaw gateway start
```

---

## 8. Discord Bot offline (two instances running simultaneously)

**Symptom**: Bot shows as offline in Discord, or messages are heavily delayed or frequently disconnecting

**Cause**: The same Bot Token is running on two servers simultaneously; Discord force-disconnects the old connection, causing frequent reconnects

**Solution**:
```bash
# Stop OpenClaw on the old server
systemctl --user stop openclaw-gateway

# After confirming the old server is stopped, restart on new server
systemctl --user restart openclaw-gateway

# Verify only one instance is running
# Check old server:
# systemctl --user status openclaw-gateway  # should show inactive
```
During migration, ensure only one server is running at any given time.

---

## 9. npm install timeout (China network)

**Symptom**: `npm install` hangs and eventually reports `ETIMEDOUT` or `ECONNRESET`

**Cause**: China network access to `registry.npmjs.org` is very slow or unavailable

**Solution**:
```bash
# Switch to npmmirror China mirror
npm config set registry https://registry.npmmirror.com

# Verify config
npm config get registry

# Retry installation
npm install -g @anthropic-ai/claude-code

# Optional: restore original after installation
# npm config set registry https://registry.npmjs.org
```

---

## 10. Wrong Node.js version (system's old version)

**Symptom**: `node --version` shows v12/v14/v16; Claude Code reports version incompatibility

**Cause**: Shell is using `/usr/bin/node` (old version from system package manager) instead of nvm-managed Node 22

**Solution**:
```bash
# Confirm nvm is loaded
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

# Switch to Node 22
nvm use 22
nvm alias default 22

# Ensure ~/.bashrc includes nvm initialization (takes effect on next login)
grep 'nvm' ~/.bashrc || echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' >> ~/.bashrc

# Verify
node --version   # should be v22.x.x
which node       # should be ~/.nvm/versions/node/v22.x.x/bin/node
```

---

## 11. setup.sh permission denied

**Symptom**: `./setup.sh` reports `Permission denied`

**Cause**: Script file lacks execute permission

**Solution**:
```bash
# Method 1: Run directly with bash (no execute permission needed)
bash ~/setup.sh

# Method 2: Add execute permission then run
chmod +x ~/setup.sh
./setup.sh
```
Always recommended to use `bash ~/setup.sh` to avoid permission issues.

---

## 12. Feishu not connecting (app not published)

**Symptom**: No response to Feishu messages; logs show connection failure or auth error

**Cause**:
- Feishu app not published (still in development/testing status)
- App permissions expired or revoked
- Bot not added to the target group

**Solution**:
1. Log in to [Feishu Open Platform](https://open.feishu.cn/)
2. Go to App Management → find the target app
3. Check if app status is **Published**
4. Check **Permission Management** → confirm messaging permissions are applied and approved
5. In the target group, **@mention the bot** and add it to the group
6. If it's an enterprise app, confirm the enterprise admin has approved the app publication

```bash
# Check Feishu-related logs
journalctl --user -u openclaw-gateway --no-pager -n 100 | grep -i feishu
```
