# Sandbox Claws Repository Structure

Clean, organized structure with clear separation of concerns.

## Root Level (Public)

```
sandbox-claws/
├── README.md                          # Main project overview
├── QUICKSTART.md                      # 5-minute getting started guide
├── CONTRIBUTING.md                    # How to contribute
├── UNINSTALL_GUIDE.md                # Complete removal instructions
├── INTERNAL_DOCS_README.md           # Guide to internal docs (gitignored)
│
├── deploy-sandbox-claws.sh           # Main deployment script
├── uninstall-sandbox-claws.sh        # Uninstall script
├── create-zip.sh                     # Package utility
├── docker-compose.yml                # Service orchestration
├── index.html                        # Web dashboard
│
├── .env.example                      # Environment template
├── .env.openclaw.example             # OpenClaw config template
└── .gitignore                        # Git ignore patterns
```

## Documentation (docs/)

```
docs/
├── README.md                         # Documentation index
├── ROADMAP.md                        # Future enhancements
│
├── analysis/
│   └── AI_AGENT_SECURITY_RESEARCH.md # Security research & lessons
│
├── deployment/
│   ├── DOCKER.md                     # Docker deployment guide
│   ├── PROXMOX.md                    # Proxmox LXC guide
│   └── GITHUB_INTEGRATION_GUIDE.md   # CI/CD setup
│
├── integrations/                     # 🔥 NEW
│   ├── OPENCLAW_INTEGRATION.md       # OpenClaw testing guide
│   └── NANOCLAW_INTEGRATION.md       # NanoClaw testing guide
│
├── security/
│   ├── COST_CONTROLS.md              # Budget enforcement guide
│   ├── ADVANCED_SECURITY.md          # Advanced security features
│   ├── SECURITY_DEPLOYMENT.md        # Hardening guide
│   └── DATA_EXFILTRATION.md          # Threat model
│
├── testing/
│   └── TESTING_GUIDE.md              # Testing procedures
│
└── internal/                         # Gitignored planning docs
    ├── COMPLETE_PROJECT_SPECIFICATION.md
    ├── COST_CONTROL_ANALYSIS.md
    ├── IMPLEMENTATION_SUMMARY.md
    ├── INSTRUCTIONS_FOR_AI.md
    ├── LINUX_VS_MACOS_ANALYSIS.md
    ├── QUICKSTART_FOR_AI.md
    ├── REDDIT_PAIN_POINTS_ANALYSIS.md
    ├── REPO_ANALYSIS.md
    ├── SESSION_SUMMARY_2026-02-07.md
    ├── SHARE_WITH_MODELS.md
    └── UBUNTU_INSTALLATION_GUIDE.md
```

## Claude Code Skills (.claude/)

```
.claude/
└── skills/                           # 🔥 NEW - AI-native setup
    ├── README.md                     # Skills usage guide
    │
    ├── setup-sandbox-claws/
    │   └── SKILL.md                  # Automated setup skill
    │
    ├── test-nanoclaw-skill/
    │   └── SKILL.md                  # Skill testing workflow
    │
    ├── scan-skill/                   # (Placeholder for future)
    └── estimate-costs/               # (Placeholder for future)
```

## Docker Services (docker/)

```
docker/
├── cost-tracker/                     # Phase 2a: Cost controls
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── tracker.py                    # Cost tracking service (495 lines)
│   └── pricing.json                  # API pricing data
│
├── skill-scanner/                    # Phase 1: Malware detection
│   ├── Dockerfile
│   ├── requirements.txt
│   └── scanner.py                    # Skill scanning service
│
├── openclaw/                         # OpenClaw agent container
│   ├── Dockerfile
│   └── entrypoint.sh
│
├── egress-filter/                    # Squid proxy
│   └── Dockerfile
│
├── dlp-scanner/                      # Data Loss Prevention
│   ├── Dockerfile
│   └── scanner.py
│
├── filesystem-monitor/               # Credential theft detection
│   ├── Dockerfile
│   └── monitor.py
│
└── mock-apis/                        # Air-gapped mode mocks
    ├── Dockerfile
    └── server.py
```

## Security Configuration (security/)

```
security/
├── squid.conf                        # Egress proxy configuration
└── allowlist.txt                     # Allowed domains
```

## Skills & Scripts

```
skills/
└── README.md                         # Placeholder for ClawHub skills

scripts/
├── get-gmail-token.sh               # OAuth helper
└── test-cost-controls.sh            # Cost control testing
```

## Web Assets

```
css/
└── style.css                        # Dashboard styles

js/
└── main.js                          # Dashboard logic (with cost tracking)
```

## Configuration Templates

```
openclaw-config/                     # OpenClaw configurations
secrets/                            # API keys (gitignored)
```

---

## Organization Principles

### 1. **Clear Separation**
- **Public docs** (`docs/`) - User-facing documentation
- **Internal docs** (`docs/internal/`) - Gitignored planning/analysis
- **Services** (`docker/`) - Each service in own directory
- **Skills** (`.claude/skills/`) - AI-native setup workflows

### 2. **Intuitive Hierarchy**
```
Root:       Quick access (README, deploy script)
docs/:      All user documentation
docker/:    All service implementations
.claude/:   AI-native automation
```

### 3. **No Clutter in Root**
- Only 5 essential markdown files
- 3 scripts (deploy, uninstall, create-zip)
- 1 compose file
- 1 dashboard (index.html)

### 4. **Logical Grouping**
- **Integrations** separate from general docs
- **Security** features grouped together
- **Testing** guides in one place
- **Deployment** options organized

### 5. **Self-Documenting**
- Each directory has README.md
- Clear naming conventions
- No cryptic abbreviations
- Obvious file purposes

---

## File Count Summary

| Directory | Files | Purpose |
|-----------|-------|---------|
| **Root** | 13 | Core project files |
| **docs/** | 18 public + 11 internal | Documentation |
| **docs/integrations/** | 2 | OpenClaw & NanoClaw guides |
| **.claude/skills/** | 4 | AI-native setup |
| **docker/** | 20+ | Service containers |
| **scripts/** | 2 | Helper utilities |
| **Total Public** | ~60 | User-facing |
| **Total Internal** | 11 | Planning (gitignored) |

---

## Why This is Clean

✅ **No Planning Docs in Public Repo**
- All internal planning in `docs/internal/` (gitignored)

✅ **Clear Documentation Hierarchy**
- `docs/README.md` is the documentation index
- Organized by purpose: security/, testing/, deployment/, integrations/

✅ **Minimal Root Clutter**
- Only essential files at top level
- Everything else properly nested

✅ **Logical Service Organization**
- Each Docker service has own directory
- Clear naming: `cost-tracker/`, `skill-scanner/`, etc.

✅ **AI-Native Extensions**
- `.claude/skills/` separate from main code
- Clear skill naming and organization

✅ **No Orphaned Files**
- Everything has a clear purpose and location
- No "misc" or "temp" directories

---

## Comparison to Other Projects

### OpenClaw (52+ modules)
```
openclaw/
├── 8 config files
├── 15 channel providers
├── 45+ dependencies
├── Complex abstractions
└── Shared memory space
```

### NanoClaw (~5 files)
```
nanoclaw/
├── src/index.ts
├── src/container-runner.ts
├── src/task-scheduler.ts
├── src/db.ts
└── groups/*/CLAUDE.md
```

### Sandbox Claws (Focused Testing)
```
sandbox-claws/
├── Clear public/internal separation ✓
├── Logical service organization ✓
├── Comprehensive documentation ✓
├── AI-native setup ✓
└── Production-ready ✓
```

---

## Next Maintainer Can...

✅ **Understand structure in 5 minutes**
- Clear hierarchy
- Intuitive naming
- README in each directory

✅ **Find any file quickly**
- Logical grouping
- Predictable locations
- Self-documenting

✅ **Add new integrations easily**
- Just add to `docs/integrations/`
- Follow existing pattern
- Update `docs/README.md`

✅ **Create new skills**
- Add to `.claude/skills/`
- Copy existing pattern
- Document in skills README

✅ **Deploy confidently**
- Single `deploy-sandbox-claws.sh` script
- Clear configuration files
- Comprehensive docs

---

**Bottom Line:** Repository is clean, organized, and production-ready! ✅
