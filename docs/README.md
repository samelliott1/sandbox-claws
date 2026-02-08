# Sandbox Claws Documentation

Complete documentation for the Sandbox Claws secure AI agent testing framework.

---

## 🚀 Getting Started

- **[Quickstart Guide](../QUICKSTART.md)** - Get running in 5 minutes
- **[Main README](../README.md)** - Project overview and quick start

---

## 🔐 Security Features

- **[Cost Controls](security/COST_CONTROLS.md)** 🔥 NEW - Budget enforcement & rate limiting
  - Session, hourly, and daily budget limits
  - Real-time cost tracking dashboard
  - Automatic alerts at 80% budget threshold
  - Rate limiting to prevent runaway agents
- **[Advanced Security Features](security/ADVANCED_SECURITY.md)** - Core security enhancements
  - Skill Marketplace Scanner
  - Remote Markdown Blocker
  - Credential Isolation
  - Filesystem Monitor
- **[Security Deployment Guide](SECURITY_DEPLOYMENT.md)** - Hardening and best practices
- **[Data Exfiltration Analysis](DATA_EXFILTRATION.md)** - Threat model and controls

---

## 🧪 Testing

- **[Testing Guide](TESTING_GUIDE.md)** - How to test AI agents safely
  - Setting up test accounts
  - Running test scenarios
  - Documenting findings

---

## 🚀 Deployment

- **[Docker Deployment](DOCKER.md)** - Standard Docker setup
- **[Proxmox LXC Deployment](PROXMOX.md)** - Proxmox container deployment
- **[GitHub Integration](deployment/GITHUB_INTEGRATION_GUIDE.md)** - CI/CD and GitHub setup

---

## 🔌 Integrations

- **[OpenClaw Integration Guide](integrations/OPENCLAW_INTEGRATION.md)** 🔥 NEW - Test OpenClaw agents safely
  - Cost estimation before production
  - Skill malware scanning
  - Context overflow monitoring
  - Sub-agent testing workflows
- **[NanoClaw Integration Guide](integrations/NANOCLAW_INTEGRATION.md)** 🔥 NEW - Test NanoClaw skills before personal use
  - AI-native setup with Claude Code
  - Security scanning for community skills
  - Cost estimation for scheduled tasks
  - Test → Validate → Deploy workflow

---

## 📊 Analysis & Research

- **[AI Agent Security Research](analysis/AI_AGENT_SECURITY_RESEARCH.md)** - Industry security lessons
- **[Product Roadmap](ROADMAP.md)** - Future enhancements

---

## 🛠️ Utilities

- **[Uninstall Guide](../UNINSTALL_GUIDE.md)** - Complete removal instructions
- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute

---

## 📂 Documentation Structure

```
docs/
├── README.md                           ← You are here
├── ROADMAP.md                          ← Future enhancements
├── deployment/
│   ├── DOCKER.md                       ← Docker setup
│   ├── PROXMOX.md                      ← Proxmox LXC
│   └── GITHUB_INTEGRATION_GUIDE.md     ← CI/CD setup
├── integrations/
│   ├── OPENCLAW_INTEGRATION.md         ← OpenClaw testing guide 🔥 NEW
│   └── NANOCLAW_INTEGRATION.md         ← NanoClaw testing guide 🔥 NEW
├── security/
│   ├── COST_CONTROLS.md                ← Budget enforcement 🔥 NEW
│   ├── ADVANCED_SECURITY.md            ← Advanced security features
│   ├── SECURITY_DEPLOYMENT.md          ← Hardening guide
│   └── DATA_EXFILTRATION.md            ← Threat model
├── testing/
│   └── TESTING_GUIDE.md                ← Testing procedures
└── analysis/
    └── AI_AGENT_SECURITY_RESEARCH.md   ← Security research
```

---

## 🆘 Getting Help

- **GitHub Issues:** [Report bugs or request features](https://github.com/samelliott1/sandbox-claws/issues)
- **GitHub Discussions:** [Ask questions or share ideas](https://github.com/samelliott1/sandbox-claws/discussions)
- **Documentation:** Browse the docs/ folder

---

## 🎯 Quick Links

| Task | Documentation |
|------|---------------|
| **Get started** | [QUICKSTART.md](../QUICKSTART.md) |
| **Test OpenClaw agents** 🔥 | [OPENCLAW_INTEGRATION.md](integrations/OPENCLAW_INTEGRATION.md) |
| **Test NanoClaw skills** 🔥 | [NANOCLAW_INTEGRATION.md](integrations/NANOCLAW_INTEGRATION.md) |
| **AI-native setup** 🔥 | [Claude Code Skills](../.claude/skills/README.md) |
| **Deploy on Docker** | [DOCKER.md](DOCKER.md) |
| **Secure deployment** | [SECURITY_DEPLOYMENT.md](SECURITY_DEPLOYMENT.md) |
| **Test agents** | [TESTING_GUIDE.md](TESTING_GUIDE.md) |
| **Cost controls** 🔥 | [COST_CONTROLS.md](security/COST_CONTROLS.md) |
| **Security features** | [ADVANCED_SECURITY.md](security/ADVANCED_SECURITY.md) |
| **Uninstall** | [UNINSTALL_GUIDE.md](../UNINSTALL_GUIDE.md) |
| **Contribute** | [CONTRIBUTING.md](../CONTRIBUTING.md) |

---

**Happy testing! 🦞🔒**
