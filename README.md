# Sandbox Claws

**Secure AI Agent Testing Framework with Egress Control**

> Docker + Test Harness + Firewall for AI Agents

🔥 **NEW: Cost Controls & Budget Enforcement** - [Read the cost controls guide →](docs/security/COST_CONTROLS.md)
- ✅ **Budget Enforcement** - Session, hourly, and daily limits
- ✅ **Real-Time Tracking** - Live cost dashboard with 5s refresh
- ✅ **Rate Limiting** - 30 calls/minute default (configurable)
- ✅ **Token Counting** - Accurate cost estimation with tiktoken
- ✅ **Automatic Alerts** - Warnings at 80% budget threshold

🔌 **NEW: OpenClaw Integration** - [Test OpenClaw agents safely →](docs/integrations/OPENCLAW_INTEGRATION.md)
- ✅ **Cost Estimation** - Predict production costs before deploying
- ✅ **Skill Scanning** - Test ClawHub skills for malware
- ✅ **Context Monitoring** - Prevent 200K token overflow
- ✅ **Sub-Agent Testing** - Safe testing of parallel agents

**Advanced Security Features** - [Read the security research →](docs/analysis/AI_AGENT_SECURITY_RESEARCH.md)
- ✅ **Skill Marketplace Scanner** - Detect malicious ClawHub skills
- ✅ **Remote Markdown Blocker** - Prevent heartbeat.md RCE attacks  
- ✅ **Credential Isolation** - Block access to ~/.ssh/, ~/.aws/
- ✅ **Filesystem Monitor** - Real-time credential theft detection

[📖 Security Features Documentation →](docs/security/ADVANCED_SECURITY.md) | [📖 Cost Controls Documentation →](docs/security/COST_CONTROLS.md)

## The Problem

Standard container sandboxes isolate compute but not network traffic. An AI agent in a typical Docker container can still exfiltrate sensitive data to arbitrary external servers.

**Recent AI Agent Security Incidents (Feb 2026):** Hundreds of malicious skills on marketplaces, #1 skill was backdoored, enterprise networks infected, users reporting $300-500 bills from runaway agents. [Full research →](docs/analysis/AI_AGENT_SECURITY_RESEARCH.md)

Sandbox Claws adds enforceable egress controls, air-gapped execution, automated DLP scanning, advanced security features, and cost controls so you can test agents safely—even with sensitive data—without surprise bills.

## Architecture

```
[ AI Agent ]
     ↓
[ Container Isolation ]
     ↓
[ Egress Proxy / Firewall ]
     ↓                    ↘
[ Allowlist Only ]    [ Blocked ]
     ↓
[ Internet ]
```

## Security Profiles

| Profile | Network Access | Use Case | Risk Level |
|---------|---------------|----------|------------|
| **Basic** | Full internet | Learning, demos | High |
| **Filtered** | Allowlist only | CI/CD, standard testing | Low |
| **Air-Gapped** | None | Sensitive/regulated data | None |

### Basic (learning/demos)
- Container isolation only
- Full outbound internet access
- Not recommended for sensitive data

### Filtered (recommended default)
- All traffic routed through Squid proxy
- Allowlist-only domain access
- Prevents unsanctioned exfiltration
- Suitable for most testing scenarios

### Air-Gapped (maximum protection)
- No outbound internet connectivity
- Local mock services replace external APIs
- Data exfiltration technically impossible
- Required for PII, PHI, or regulated data

## Threat Model

| Threat | Control | Verification |
|--------|---------|--------------|
| Data exfiltration via HTTP | Egress proxy allowlist | Blocked connection logs |
| Sensitive data in agent output | DLP scanner | Pattern match alerts |
| Unauthorized API calls | Default-deny network policy | Proxy access logs |
| Container escape | Standard Docker isolation | Host monitoring |
| Lack of audit trail | Centralized logging | Persistent log storage |

## Quick Start

### Prerequisites
- **Docker** (script will install if needed)
- **Anthropic API Key** (required for OpenClaw AI)
  - Get one at: https://console.anthropic.com/settings/keys
  - Cost: ~$5-20 to start (pay-as-you-go)

### Installation (3 steps, 5 minutes)

```bash
# 1. Deploy
./deploy-sandbox-claws.sh

# 2. Add your Anthropic API key
nano .env.openclaw
# Add: ANTHROPIC_API_KEY=sk-ant-your-key-here

# 3. Restart OpenClaw
docker-compose restart openclaw

# Access dashboard
open http://localhost:8080
```

**📖 Detailed Guide:** See [QUICKSTART.md](QUICKSTART.md) for step-by-step instructions

### Other Commands

```bash
# Deploy with specific security profile
./deploy-sandbox-claws.sh filtered    # Allowlist-only egress
./deploy-sandbox-claws.sh airgapped   # No internet access

# Uninstall everything
./uninstall-sandbox-claws.sh
```

## What's Included

- One-command deployment (auto-installs Docker if needed)
- **One-command uninstall** with optional Docker removal
- Three security profiles with enforced network policies
- Web dashboard for session tracking and findings
- DLP scanner for detecting sensitive data patterns
- Pre-built test cases for common agent behaviors
- OAuth helper scripts for API token generation
- Complete documentation and architecture specs

## Project Structure

```
sandbox-claws/
├── deploy-sandbox-claws.sh   # One-command deployment
├── uninstall-sandbox-claws.sh # One-command uninstall
├── docker-compose.yml        # Infrastructure definition
├── index.html                # Web dashboard
├── security/                 # Egress filter configs
│   ├── squid.conf
│   └── allowlist.txt
├── docker/                   # Container definitions
├── scripts/                  # Helper utilities
└── docs/                     # Operational guides
    ├── TESTING_GUIDE.md
    ├── SECURITY_DEPLOYMENT.md
    └── DATA_EXFILTRATION.md
```

## Non-Goals

This framework does not:
- Replace input validation or prompt injection defenses
- Prevent agents from producing harmful outputs locally
- Protect against ingress attacks on the container
- Provide runtime behavior analysis of agent decisions

Sandbox Claws focuses specifically on **egress control and data loss prevention**.

## Documentation

- **[OpenClaw Integration Guide](docs/integrations/OPENCLAW_INTEGRATION.md)** 🔥 NEW — Test OpenClaw agents safely
- [Testing Guide](docs/TESTING_GUIDE.md) — Pre-built test cases and methodology
- [Security Deployment](docs/SECURITY_DEPLOYMENT.md) — Profile configuration details
- [Data Exfiltration Analysis](docs/DATA_EXFILTRATION.md) — Threat model deep-dive

## License

MIT
