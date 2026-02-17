# OpenClaw Dev Team

One-command setup for a 9-agent autonomous AI development team powered by OpenClaw + Kimi K2 Thinking.

## What You Get

- **9 AI Agents**: Chief, Scout, Insight, Architect, Designer, Developer, Reviewer, Security, Tester
- **32 Skills**: Browser, scraping, git, security audit, web3, design, and more
- **24/7 Autonomous**: Agents run on cron schedules, self-manage memory, auto-restart on failure
- **Web Dashboard**: Landing page, team chat, agent memory browser, remote desktop (noVNC)
- **SSL + Auth**: Let's Encrypt HTTPS, basic auth protection
- **GitHub Integration**: Professional main/dev branch workflow with auto-commit

## Requirements

- Fresh Ubuntu 24.04 server (8GB+ RAM recommended)
- Domain name with DNS pointing to server IP
- [Chutes API token](https://chutes.ai) for Kimi K2 Thinking model
- GitHub account + Personal Access Token

## Quick Start

```bash
git clone https://github.com/cmdenter/openclaw-devteam.git
cd openclaw-devteam

CHUTES_TOKEN=cpk_xxx \
DOMAIN=yourdomain.com \
GITHUB_USER=yourusername \
GITHUB_TOKEN=ghp_xxx \
LOGIN_USER=admin \
LOGIN_PASS=yourpassword \
./install.sh
```

Setup takes ~10 minutes. When done you'll have:

| URL | Service |
|-----|---------|
| `https://yourdomain.com` | Command Center |
| `https://yourdomain.com/team/` | Team Dashboard & Chat |
| `https://yourdomain.com/memory/` | Agent Memory Browser |
| `https://yourdomain.com/desktop/vnc.html` | Remote Desktop |

## Agent Team

| Agent | Role | Schedule |
|-------|------|----------|
| Chief | Project Manager & Orchestrator | Every 15 min |
| Scout | Web Researcher & Competitor Analysis | Every 2 hours |
| Insight | Market & UX Research | Every 2 hours |
| Architect | System Architecture & Tech Debt | Every 3 hours |
| Designer | UI/UX & Design System | Every 3 hours |
| Developer | Lead Developer | Every 30 min |
| Reviewer | Code Review | Every 45 min |
| Security | Security Auditor | Every 45 min |
| Tester | QA & Verification | Every 1 hour |

## Architecture

```
User (webchat) → Chief (orchestrator)
                    ↓
    ┌───────────────┼───────────────┐
    ↓               ↓               ↓
Scout/Insight → Architect → Designer
                    ↓
                Developer
                    ↓
              ┌─────┼─────┐
              ↓           ↓
           Reviewer    Security
              ↓           ↓
              └─────┬─────┘
                    ↓
                  Tester → Merge to dev → PR to main
```

## Skills Installed

Browser & Research: agent-browser, tavily-search, firecrawl-search, playwright-scraper, deep-scraper, browsh, fast-browser-use

Git & Dev: git-essentials, git-workflows, pr-reviewer, senior-dev, openclaw-github-assistant

Security: security-auditor, openclaw-sec, security-scanner

Design: shadcn-ui, superdesign, ui-ux-design, ui-audit

Web3: evm-wallet, blockchain, walletconnect-agent, crypto-whale-monitor

Frameworks: nextjs-expert, nextjs, react-expert, typescript

Other: god-mode, session-logs, summarize, market-research, research-tracker

## Customization

- Edit `agents/*/SOUL.md` to change agent personalities
- Edit `agents/shared/AGENTS.md` for team workflow rules
- Edit `config/openclaw.json` for model, scheduling, tool access
- Edit `config/nginx.conf` for routing
- Edit `web/index.html` for landing page

## Health & Monitoring

- Health check runs every 5 minutes (gateway alive, memory < 85%)
- Systemd auto-restart with 2GB memory limit
- Agent memory persists at `~/.openclaw/workspace/*/memory/`

## License

MIT
