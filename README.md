# Sandbox Claws

**Secure AI Agent Testing Framework with Egress Control**

> Docker + Test Harness + Firewall for AI Agents

🔥 **NEW: Phase 1 Security Features** - [Read about the OpenClaw crisis →](OPENCLAW_SECURITY_ANALYSIS.md)
- ✅ **Skill Marketplace Scanner** - Detect malicious ClawHub skills
- ✅ **Remote Markdown Blocker** - Prevent heartbeat.md RCE attacks  
- ✅ **Credential Isolation** - Block access to ~/.ssh/, ~/.aws/
- ✅ **Filesystem Monitor** - Real-time credential theft detection

[📖 Phase 1 Documentation →](PHASE_1_SECURITY.md)

## The Problem

Standard container sandboxes isolate compute but not network traffic. An AI agent in a typical Docker container can still exfiltrate sensitive data to arbitrary external servers.

**Recent OpenClaw Crisis (Feb 2026):** Hundreds of malicious skills on ClawHub, #1 skill was backdoored, enterprise networks infected. [Full analysis →](OPENCLAW_SECURITY_ANALYSIS.md)

Sandbox Claws adds enforceable egress controls, air-gapped execution, automated DLP scanning, **and now Phase 1 security features** so you can test agents safely—even with sensitive data.

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
./deploy.sh

# 2. Add your Anthropic API key
nano .env.openclaw
# Add: ANTHROPIC_API_KEY=sk-ant-your-key-here

# 3. Restart OpenClaw
docker-compose restart openclaw

# Access dashboard
open http://localhost:8080
```

**📖 Detailed Guide:** See [QUICKSTART_SIMPLE.md](QUICKSTART_SIMPLE.md) for step-by-step instructions

### Other Commands

```bash
# Deploy with specific security profile
./deploy.sh filtered    # Allowlist-only egress
./deploy.sh airgapped   # No internet access

# Uninstall everything
./uninstall.sh
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
├── deploy.sh                 # One-command deployment
├── uninstall.sh              # One-command uninstall
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

- [Testing Guide](docs/TESTING_GUIDE.md) — Pre-built test cases and methodology
- [Security Deployment](docs/SECURITY_DEPLOYMENT.md) — Profile configuration details
- [Data Exfiltration Analysis](docs/DATA_EXFILTRATION.md) — Threat model deep-dive

## License

MIT
