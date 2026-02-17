#!/bin/bash
set -e

echo "========================================="
echo "  OpenClaw Dev Team - Full Setup Script"
echo "  9 Agents | 32 Skills | Web3 Ready"
echo "========================================="

DOMAIN="${DOMAIN:-}"
GITHUB_USER="${GITHUB_USER:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CHUTES_TOKEN="${CHUTES_TOKEN:-}"
LOGIN_USER="${LOGIN_USER:-admin}"
LOGIN_PASS="${LOGIN_PASS:-changeme}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$CHUTES_TOKEN" ]; then
  echo "ERROR: Set CHUTES_TOKEN env var"
  echo "Usage: CHUTES_TOKEN=cpk_xxx DOMAIN=mysite.io GITHUB_USER=user GITHUB_TOKEN=ghp_xxx LOGIN_USER=admin LOGIN_PASS=pass ./install.sh"
  exit 1
fi

echo "[1/10] System packages..."
apt update -qq
DEBIAN_FRONTEND=noninteractive apt install -y curl wget git build-essential python3 python3-pip nginx certbot python3-certbot-nginx apache2-utils xfce4 xfce4-terminal dbus-x11 tigervnc-standalone-server tigervnc-common novnc websockify jq ffmpeg tmux ufw

echo "[2/10] Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

echo "[3/10] OpenClaw..."
npm install -g openclaw@latest

echo "[4/10] Chrome..."
wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y /tmp/google-chrome.deb

echo "[5/10] Playwright..."
cd /tmp && npm init -y > /dev/null && npm install playwright
npx playwright install chromium --with-deps
npm link playwright 2>/dev/null || true

echo "[6/10] GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt update -qq && apt install -y gh
if [ -n "$GITHUB_TOKEN" ]; then
  echo "$GITHUB_TOKEN" | gh auth login --with-token
fi

echo "[7/10] OpenClaw onboard..."
echo "CHUTES_API_TOKEN=$CHUTES_TOKEN" > /etc/environment
echo "export CHUTES_API_TOKEN=\"$CHUTES_TOKEN\"" >> ~/.bashrc
export CHUTES_API_TOKEN="$CHUTES_TOKEN"
openclaw onboard --install-daemon --non-interactive --accept-risk 2>/dev/null || true

echo "[8/10] Agent config..."
cp "$SCRIPT_DIR/config/openclaw.json" ~/.openclaw/openclaw.json
for agent in chief researcher-web researcher-market architect designer developer reviewer security tester; do
  mkdir -p ~/.openclaw/workspace/$agent/memory ~/.openclaw/workspace/$agent/logs
  cp "$SCRIPT_DIR/agents/$agent/SOUL.md" ~/.openclaw/workspace/$agent/SOUL.md
  cp "$SCRIPT_DIR/agents/shared/AGENTS.md" ~/.openclaw/workspace/$agent/AGENTS.md
  cp "$SCRIPT_DIR/agents/shared/USER.md" ~/.openclaw/workspace/$agent/USER.md
  echo "# Status: Ready" > ~/.openclaw/workspace/$agent/memory/STATUS.md
  echo "# Action Log" > ~/.openclaw/workspace/$agent/memory/LOG.md
  echo "# Learnings" > ~/.openclaw/workspace/$agent/memory/LEARNINGS.md
done
cp "$SCRIPT_DIR/agents/chief/HEARTBEAT.md" ~/.openclaw/workspace/chief/HEARTBEAT.md
chmod o+x /root /root/.openclaw
chmod -R o+rx /root/.openclaw/workspace/

echo "[9/10] Skills..."
npm install -g clawhub@latest
SKILLS="agent-browser tavily-search firecrawl-search playwright-scraper-skill deep-scraper git-essentials git-workflows pr-reviewer senior-dev openclaw-github-assistant security-auditor openclaw-sec security-scanner market-research research-tracker shadcn-ui nextjs-expert react-expert typescript nextjs god-mode browsh fast-browser-use evm-wallet blockchain walletconnect-agent crypto-whale-monitor session-logs summarize superdesign ui-ux-design ui-audit"
for skill in $SKILLS; do
  echo "  Installing $skill..."
  npx clawhub@latest install "$skill" --force 2>/dev/null || echo "  Retry later: $skill"
  sleep 2
done

echo "[10/10] Services..."

cat > /etc/systemd/system/openclaw-gateway.service << 'SVCEOF'
[Unit]
Description=OpenClaw Gateway
After=network.target
[Service]
Type=simple
User=root
EnvironmentFile=/etc/environment
ExecStart=/usr/bin/openclaw gateway --port 18789
Restart=always
RestartSec=5
WatchdogSec=300
MemoryMax=2G
MemoryHigh=1500M
OOMPolicy=restart
[Install]
WantedBy=multi-user.target
SVCEOF

mkdir -p ~/.vnc
echo "$LOGIN_PASS" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
cat > ~/.vnc/xstartup << 'VNCEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
VNCEOF
chmod +x ~/.vnc/xstartup

cat > /etc/systemd/system/vnc.service << 'SVCEOF'
[Unit]
Description=TigerVNC Server
After=network.target
[Service]
Type=forking
User=root
ExecStartPre=/usr/bin/vncserver -kill :1 || true
ExecStart=/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24 -localhost yes
ExecStop=/usr/bin/vncserver -kill :1
Restart=on-failure
[Install]
WantedBy=multi-user.target
SVCEOF

cat > /etc/systemd/system/novnc.service << 'SVCEOF'
[Unit]
Description=noVNC Web Client
After=vnc.service
Requires=vnc.service
[Service]
Type=simple
ExecStart=/usr/bin/websockify --web=/usr/share/novnc 6080 localhost:5901
Restart=on-failure
[Install]
WantedBy=multi-user.target
SVCEOF

cat > /usr/local/bin/openclaw-health << 'HEALTHEOF'
#!/bin/bash
source /etc/environment
if ! systemctl is-active --quiet openclaw-gateway; then
    echo "$(date) Gateway down, restarting..." >> /var/log/openclaw-health.log
    systemctl restart openclaw-gateway
fi
MEM_PCT=$(free | awk '/Mem:/ {printf "%d", $3/$2*100}')
if [ $MEM_PCT -gt 85 ]; then
    echo "$(date) Memory high, restarting..." >> /var/log/openclaw-health.log
    systemctl restart openclaw-gateway
fi
if ! curl -sf -o /dev/null --max-time 5 http://127.0.0.1:18789/ 2>/dev/null; then
    echo "$(date) Gateway unresponsive, restarting..." >> /var/log/openclaw-health.log
    systemctl restart openclaw-gateway
fi
HEALTHEOF
chmod +x /usr/local/bin/openclaw-health
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/openclaw-health") | crontab -

htpasswd -cb /etc/nginx/.htpasswd "$LOGIN_USER" "$LOGIN_PASS"

mkdir -p /var/www/smartsui
cp "$SCRIPT_DIR/web/index.html" /var/www/smartsui/index.html
ln -sf /root/.openclaw/workspace /var/www/smartsui/memory

cp "$SCRIPT_DIR/config/nginx.conf" /etc/nginx/sites-available/smartsui
if [ -n "$DOMAIN" ]; then
  sed -i "s/YOURDOMAIN/$DOMAIN/g" /etc/nginx/sites-available/smartsui
fi
ln -sf /etc/nginx/sites-available/smartsui /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl daemon-reload
systemctl enable vnc novnc openclaw-gateway
systemctl start vnc novnc
systemctl restart openclaw-gateway

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

if [ -n "$DOMAIN" ]; then
  nginx -t && systemctl reload nginx
  certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN"
fi
nginx -t && systemctl reload nginx

git config --global user.name "$GITHUB_USER"
git config --global user.email "$GITHUB_USER@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global credential.helper store
if [ -n "$GITHUB_TOKEN" ]; then
  echo "https://$GITHUB_USER:$GITHUB_TOKEN@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
fi

# Cron jobs
openclaw cron add --name chief-heartbeat --every 15m --agent chief --message "Team captain: check all agents, assign tasks, push work forward."
openclaw cron add --name dev-continuous --every 30m --agent developer --message "Pick up next task, implement on dev branch, commit."
openclaw cron add --name review-continuous --every 45m --agent reviewer --message "Review unreviewed commits on dev branch."
openclaw cron add --name security-continuous --every 45m --agent security --message "Audit latest changes for vulnerabilities."
openclaw cron add --name qa-continuous --every 1h --agent tester --message "Run tests, check build, verify features."
openclaw cron add --name research-web --every 2h --agent researcher-web --message "Scan competitor web3 sites, report insights."
openclaw cron add --name research-market --every 2h --agent researcher-market --message "Research web3 UX trends and market data."
openclaw cron add --name architect-watch --every 3h --agent architect --message "Review architecture, check tech debt."
openclaw cron add --name designer-watch --every 3h --agent designer --message "Review design system, suggest improvements."

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "  Landing:  https://$DOMAIN"
echo "  Team:     https://$DOMAIN/team/"
echo "  Memory:   https://$DOMAIN/memory/"
echo "  Desktop:  https://$DOMAIN/desktop/vnc.html"
echo "  Login:    $LOGIN_USER / $LOGIN_PASS"
echo ""
echo "  9 agents | 32 skills | 24/7 autonomous"
echo "========================================="
