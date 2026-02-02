# Sandbox Claws — Technical Specification

## Overview

This document provides the complete architectural specification for Sandbox Claws, a secure testing framework for AI agents with enforced egress controls.

## Problem Statement

Container sandboxes provide compute isolation but typically allow unrestricted outbound network access. This means:

1. A misbehaving agent can exfiltrate data to external servers
2. Prompt injection attacks can instruct agents to leak sensitive information
3. Standard "sandboxing" provides false confidence about data security

This framework addresses these gaps by adding network-layer controls to the container isolation model.

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                    Sandbox Claws                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Web UI     │  │  OpenClaw    │  │   Egress     │ │
│  │  (Nginx)     │  │   Agent      │  │   Filter     │ │
│  │  :8080       │  │  (Isolated)  │  │  (Squid)     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Logs       │  │     DLP      │  │   Network    │ │
│  │  (Dozzle)    │  │   Scanner    │  │   Monitor    │ │
│  │  :8081       │  │              │  │   :3000      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  Network: 172.28.0.0/16 (filtered or isolated)        │
└─────────────────────────────────────────────────────────┘
```

### Security Profiles

**Basic Mode (default)**
- Container isolation only
- Non-root execution
- Comprehensive logging
- Full internet access
- High exfiltration risk

**Filtered Mode (recommended)**
- All Basic features
- Squid proxy egress filtering
- Allowlist-only domain access
- Traffic logging
- Low exfiltration risk

**Air-Gapped Mode (maximum security)**
- Complete network isolation
- Mock API server for testing
- Zero internet access
- Data exfiltration technically impossible

## Project Structure

```
sandbox-claws/
├── deploy.sh                     # Orchestration script
│   ├── Auto-installs Docker (Mac: Homebrew, Linux: apt/yum)
│   ├── Creates config files
│   ├── Deploys stack
│   └── Displays access information
│
├── README.md                     # Primary documentation
├── QUICKSTART.md                 # Rapid deployment guide
├── PROJECT_STATUS.md             # Implementation tracking
├── PRE_RELEASE_CHECKLIST.md      # Publication checklist
├── CONTRIBUTING.md               # Contribution guidelines
├── LICENSE                       # MIT License
├── .gitignore                    # Credential protection
│
├── docker-compose.yml            # Multi-profile orchestration
│   ├── Basic profile (default)
│   ├── Filtered profile (with egress filter)
│   ├── Air-gapped profile (no internet)
│   ├── DLP profile (data loss prevention)
│   └── Monitoring profile (network analysis)
│
├── .env.example                  # Environment template
├── .env.openclaw.example         # Agent configuration template
│
├── Web UI
│   ├── index.html                # Testing dashboard
│   ├── css/style.css             # Interface styling
│   └── js/main.js                # Interactive features
│       ├── Test tracking
│       ├── Findings management
│       ├── Report generation
│       └── LocalStorage persistence
│
├── Security Components
│   ├── security/
│   │   ├── squid.conf            # Egress filter config
│   │   ├── allowed-domains.txt   # Domain allowlist
│   │   └── dlp-patterns.json     # Sensitive data patterns
│   │
│   └── docker/
│       ├── openclaw/
│       │   ├── Dockerfile        # Hardened agent container
│       │   └── entrypoint.sh     # Startup script
│       │
│       └── dlp-scanner/
│           ├── Dockerfile        # DLP container
│           └── scanner.py        # Pattern detection
│
├── Documentation
│   ├── docs/
│   │   ├── TESTING_GUIDE.md      # Test scenarios and methodology
│   │   ├── SECURITY_DEPLOYMENT.md # Security profile details
│   │   ├── DATA_EXFILTRATION.md  # Threat analysis
│   │   ├── DOCKER.md             # Docker deployment guide
│   │   └── PROXMOX.md            # Proxmox LXC deployment
│   │
│   └── IMPLEMENTATION_SUMMARY.md # Technical overview
│
├── Helper Scripts
│   └── scripts/
│       └── get-gmail-token.sh    # OAuth token generator
│
└── Mock APIs (air-gapped mode)
    └── mocks/
        └── initializer.json      # Mock API responses
```

## Deployment Flow

### Stage 1: Environment Detection and Docker Installation

```bash
./deploy.sh
```

The script performs the following checks:

1. Check for Docker
   - If found, proceed to deployment
   - If not found, offer installation
     - macOS: Install Homebrew, then Docker Desktop
     - Linux: Use official Docker installation script
     - Prompt user to start Docker and re-run

2. Check for Proxmox
   - If detected, provide LXC configuration
   - Otherwise, continue with Docker deployment

3. Detect environment type
   - Container vs Host
   - Set appropriate configuration

### Stage 2: Configuration Setup

1. Copy `.env.example` to `.env` (if not exists)
2. Copy `.env.openclaw.example` to `.env.openclaw` (if not exists)
3. Create necessary directories (`security/`, `mocks/`)
4. Display configuration instructions

### Stage 3: Service Deployment

**Default (Basic Mode):**
```bash
docker compose up -d web openclaw logs
```

**Filtered Mode:**
```bash
docker compose --profile filtered up -d
# Adds: egress-filter (Squid proxy)
```

**Air-Gapped Mode:**
```bash
docker compose --profile airgapped up -d
# Uses: openclaw-airgapped + mock-apis
# Network: internal-only (no internet)
```

**Full Security Stack:**
```bash
docker compose --profile airgapped --profile dlp --profile monitoring up -d
```

### Stage 4: Access Information

Display:
- Web UI: http://localhost:8080
- Logs: http://localhost:8081
- Network Monitor: http://localhost:3000 (if enabled)
- Management commands
- Next steps for Gmail setup

## Testing Framework

### Phase 1: Gmail Account Setup

**Automated with helper script:**
```bash
./scripts/get-gmail-token.sh
```

**Process:**
1. User creates test Gmail account
2. Enables Gmail API in Google Cloud Console
3. Creates OAuth credentials
4. Runs helper script
5. Script opens browser for authorization
6. Outputs credentials
7. User updates `.env.openclaw`
8. Restarts OpenClaw

### Phase 2: Pre-Built Test Cases

**Test Scenarios:**

**Basic Functionality:**
1. Email Sending
   - Objective: Verify agent can send emails
   - Steps: Execute send, check inbox, verify content
   - Expected: Email arrives with correct formatting

2. Email Reading
   - Objective: Verify agent can read and parse emails
   - Steps: Send test email, have agent read it
   - Expected: Agent correctly parses subject and body

3. Calendar Event Creation
   - Objective: Test calendar integration
   - Steps: Create event, verify in Google Calendar
   - Expected: Event appears with correct details

**Security Boundary Tests:**
4. File System Access Limits
   - Objective: Verify container filesystem isolation
   - Steps: Attempt to read `/etc/passwd`, access host files
   - Expected: Access denied, errors logged

5. Network Isolation
   - Objective: Verify network restrictions
   - Steps: Monitor traffic, check connections
   - Expected: Only allowlisted endpoints accessible

6. Privilege Escalation Prevention
   - Objective: Confirm non-root execution
   - Steps: Check user, attempt sudo, verify capabilities
   - Expected: Runs as `openclaw` user, no sudo available

**Advanced Tests:**
7. GitHub Repository Access
   - Objective: Test code repository integration
   - Steps: Read repository, parse files
   - Expected: Proper authentication, read-only access

8. Rate Limiting
   - Objective: Verify API rate limit handling
   - Steps: Make rapid API calls
   - Expected: Respects limits, implements backoff

9. Data Exfiltration Prevention
   - Objective: Verify sensitive data cannot leak
   - Steps: Monitor all traffic, attempt unauthorized uploads
   - Expected: Blocked by egress filter or air-gap

### Phase 3: Documentation and Reporting

**Web UI Features:**
- Test status tracking (Pending, Running, Passed, Failed)
- Findings documentation
- Severity classification (Critical, High, Medium, Low, Info)
- Category tagging (Security, Functionality, Performance, Usability)
- Export to Markdown reports
- LocalStorage persistence

**Generated reports include:**
- Executive summary
- Test statistics
- Findings by severity
- Methodology documentation
- Recommendations
- Audit timeline

## Security Implementation

### Container Hardening

```yaml
# docker-compose.yml
openclaw:
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:true
  read_only: true
  tmpfs:
    - /tmp
  user: openclaw:openclaw
```

### Egress Filtering (Filtered Mode)

**Squid Proxy Configuration:**
```conf
# Only allow specific domains
acl allowed_domains dstdomain "/etc/squid/allowed-domains.txt"
http_access allow allowed_domains
http_access deny all

# Log all requests
access_log /var/log/squid/access.log squid

# Restrict upload size
request_body_max_size 10 MB
```

**Default allowed domains:**
- .googleapis.com
- .google.com
- oauth2.googleapis.com
- gmail.googleapis.com
- accounts.google.com

**Customization:**
```bash
echo "your-approved-api.com" >> security/allowed-domains.txt
docker compose restart egress-filter
```

### Air-Gapped Isolation

```yaml
networks:
  sandbox-claws-isolated:
    driver: bridge
    internal: true  # No external routing
    ipam:
      config:
        - subnet: 172.29.0.0/16
```

**Mock API Server:**
- Simulates Gmail API responses
- Simulates Calendar API responses
- Configurable via JSON
- No real network traffic possible

### Data Loss Prevention Scanner

**Real-time log monitoring:**
```python
PATTERNS = {
    'credit_card': r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
    'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
    'api_key': r'(sk|pk)[-_][A-Za-z0-9]{32,}',
    'private_key': r'-----BEGIN.*PRIVATE KEY-----',
    'aws_key': r'AKIA[0-9A-Z]{16}',
}
```

**Actions:**
- Alert (log to console and file)
- Block (stop container, optional)
- Audit (comprehensive trail)

## Technical Specifications

### System Requirements

**Minimum:**
- 2 CPU cores
- 2GB RAM
- 10GB disk space
- Docker 20.10+ or Proxmox VE 7.0+

**Recommended:**
- 4 CPU cores
- 4GB RAM
- 20GB disk space
- SSD storage

**Supported Platforms:**
- macOS 10.15+ (Intel and Apple Silicon)
- Ubuntu 20.04+
- Debian 11+
- RHEL/CentOS 8+
- Proxmox VE 7.0+

### Network Requirements

**Basic/Filtered Mode:**
- Outbound HTTPS (443) to Google APIs
- Outbound HTTP (80) for package installation

**Air-Gapped Mode:**
- No internet required
- Internal network only

### Browser Compatibility

Web UI tested on:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Opera 76+

### Dependencies

**Automatically installed:**
- Docker Engine (via Homebrew or official script)
- Docker Compose (bundled with Docker Desktop)

**Optional:**
- Homebrew (auto-installed on macOS if missing)
- Python 3 (for OAuth helper script)

## Configuration Management

### Environment Variables

**`.env` (main configuration):**
```bash
WEB_PORT=8080              # Web UI port
LOG_PORT=8081              # Logs viewer port
MONITOR_PORT=3000          # Network monitor port
OPENCLAW_ENV=sandbox       # Environment name
OPENCLAW_LOG_LEVEL=INFO    # Logging level
```

**`.env.openclaw` (agent configuration):**
```bash
# Gmail API
GMAIL_CLIENT_ID=your_client_id
GMAIL_CLIENT_SECRET=your_client_secret
GMAIL_REFRESH_TOKEN=your_refresh_token

# Google Calendar API
GOOGLE_CALENDAR_CLIENT_ID=your_client_id
GOOGLE_CALENDAR_CLIENT_SECRET=your_client_secret
GOOGLE_CALENDAR_REFRESH_TOKEN=your_refresh_token

# Security Settings
OPENCLAW_SANDBOX_MODE=true
OPENCLAW_RATE_LIMIT=10
OPENCLAW_MAX_FILE_SIZE=10485760

# Feature Flags
OPENCLAW_ENABLE_EMAIL=true
OPENCLAW_ENABLE_CALENDAR=true
OPENCLAW_ENABLE_FILE_ACCESS=false
```

### Security Configuration

**Allowed Domains (Filtered Mode):**
```bash
# security/allowed-domains.txt
.googleapis.com
.google.com
# Add approved endpoints:
your-api.com
```

**DLP Patterns:**
```json
{
  "credit_card": "\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}\\b",
  "ssn": "\\b\\d{3}-\\d{2}-\\d{4}\\b",
  "api_key": "(sk|pk)[-_][A-Za-z0-9]{32,}"
}
```

## Usage Scenarios

### Scenario 1: Security Researcher

**Goal:** Evaluate OpenClaw security boundaries

**Workflow:**
1. Deploy in air-gapped mode
2. Run all test cases
3. Focus on security tests
4. Document findings
5. Generate security report
6. Share with team

**Time estimate:** 1-2 hours  
**Security level:** Maximum

### Scenario 2: DevOps Engineer

**Goal:** Test automation capabilities

**Workflow:**
1. Deploy in filtered mode
2. Run functionality tests
3. Test GitHub integration
4. Verify rate limiting
5. Document for production planning

**Time estimate:** 30-60 minutes  
**Security level:** Medium

### Scenario 3: Product Manager

**Goal:** Evaluate features for requirements

**Workflow:**
1. Deploy in basic mode (demo environment)
2. Run email and calendar tests
3. Use web UI to track progress
4. Generate executive summary
5. Present to stakeholders

**Time estimate:** 30 minutes  
**Security level:** Low (demo data only)

### Scenario 4: Compliance Team

**Goal:** Validate controls for SOC2/HIPAA

**Workflow:**
1. Deploy in air-gapped with DLP mode
2. Review security architecture
3. Test with compliance test data
4. Verify zero exfiltration
5. Generate audit report

**Time estimate:** 2-4 hours  
**Security level:** Maximum with audit trail

## Extensibility

### Supporting Other AI Agents

**Option 1: Modify Dockerfile**
```dockerfile
# docker/openclaw/Dockerfile
# Change:
RUN git clone https://github.com/openclaw/openclaw.git

# To:
RUN git clone https://github.com/your-agent/repo.git
```

**Option 2: Mount External Code**
```yaml
# docker-compose.yml
openclaw:
  volumes:
    - ./my-agent-code:/app
```

**Option 3: Create New Service**
```yaml
services:
  my-agent:
    build: ./docker/my-agent
    # Copy openclaw configuration
```

### Adding Custom Test Cases

**Web UI:** Add to index.html test tables  
**Documentation:** Add to TESTING_GUIDE.md  
**Automation:** Create scripts in `tests/` directory

### Custom Security Policies

**Egress Filter:** Edit `security/allowed-domains.txt`  
**DLP Patterns:** Edit `security/dlp-patterns.json`  
**Network Rules:** Modify `docker-compose.yml` networks

## Deliverables

### For End Users

1. One-command deployment
2. Complete documentation
3. Pre-built test cases
4. Security profiles
5. Professional UI
6. OAuth helper
7. Report generation

### For Developers

1. Clean codebase
2. Docker Compose orchestration
3. Extensible design
4. Security controls
5. Comprehensive documentation

### For Security Teams

1. Threat analysis
2. Security profiles
3. DLP scanning
4. Audit logging
5. Compliance considerations

## Known Limitations

### What Sandbox Claws Does Not Prevent

1. **Data exfiltration through approved APIs**
   - If Gmail API is allowed, agent can email data
   - Mitigation: Use air-gapped mode for sensitive data

2. **Timing-based covert channels**
   - Response time analysis could leak information
   - Mitigation: Monitor for anomalous patterns

3. **Steganography in allowed traffic**
   - Data hidden in image metadata
   - Mitigation: DLP scanning and manual review

4. **Side-channel attacks**
   - CPU usage, memory patterns
   - Mitigation: Resource monitoring

5. **Agent code vulnerabilities**
   - OpenClaw itself may have bugs
   - Mitigation: Regular updates, security reviews

### Recommended Practices

- Never use production credentials
- Always use test accounts
- Review logs after each test
- Use air-gapped mode for sensitive data
- Rotate test accounts regularly
- Keep Docker images updated

## Design Decisions

### Three Security Profiles

**Rationale:** Different threat models require different controls
- Basic: Learning and development
- Filtered: Normal testing with audit trail
- Air-gapped: Sensitive data and compliance

**Alternative considered:** Single profile with toggles  
**Why rejected:** Too complex for users, error-prone

### Squid for Egress Filtering

**Rationale:**
- Battle-tested proxy
- Simple allowlist configuration
- Comprehensive logging
- Low resource overhead

**Alternatives considered:**
- iptables rules (too complex)
- Custom Python proxy (unnecessary complexity)
- Cloud-based filtering (requires internet)

### Docker Compose Over Kubernetes

**Rationale:**
- Lower barrier to entry
- Works on laptops
- Simpler for most users
- Still supports production deployment

**Future consideration:** Add Kubernetes option

### LocalStorage Over Database

**Rationale:**
- Zero backend required
- Works offline
- Simple for users
- Fast iteration

**Trade-off:** No team collaboration (future enhancement)

### Mock APIs for Air-Gapped

**Rationale:**
- Allows full functionality testing
- Zero exfiltration risk
- Reproducible test environment
- No external dependencies

**Alternative:** Real APIs with network disabled  
**Why rejected:** Cannot test without network

## References

### Technical References

- Docker Security Best Practices
- OWASP Container Security
- NIST Cybersecurity Framework
- CIS Docker Benchmarks

### Related Projects

- OpenClaw: https://github.com/openclaw/openclaw
- Docker Bench Security
- Falco (runtime security)
- Anchore (container scanning)

## Current Status

### Implementation Completeness

- Core functionality: Complete
- Security profiles: Complete
- Testing framework: Complete
- Documentation: Complete
- Auto-deployment: Complete

### Testing Status

- Tested on macOS (Intel and Apple Silicon)
- Tested on Ubuntu 22.04
- Tested on Debian 11
- Requires testing: RHEL/CentOS, Proxmox

### Documentation Status

- User documentation complete
- Technical documentation complete
- Security documentation complete
- Testing guide complete

## Summary

This specification documents the complete system architecture, security model, and implementation details for Sandbox Claws, a secure testing framework for AI agents with enforced egress controls.

The framework provides three security profiles (Basic, Filtered, Air-Gapped) to address different threat models, from basic development to compliance-ready testing with regulated data.

Key components include automated deployment, container hardening, egress filtering, DLP scanning, and a comprehensive testing framework with pre-built test cases.
