# Docker Hardening Guide

**Secure Container Configuration for AI Agent Testing**

Based on [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) and [Composio's Secure OpenClaw Guide](https://composio.dev/blog/secure-openclaw-moltbot-clawdbot-setup).

---

## 🎯 The RAK Framework

Sandbox Claws mitigates three critical threat vectors:

### **Root Risk** - Host Compromise
**Threat:** Agent executes malicious code on host OS (e.g., `rm -rf /`)  
**Mitigation:** Container isolation with hardened runtime

### **Agency Risk** - Unintended Actions  
**Threat:** Agent hallucinations cause destructive actions  
**Mitigation:** Skill scanning, rate limiting, cost controls (Phase 2b: transparency dashboard)

### **Keys Risk** - Credential Leakage
**Threat:** API keys leaked via logs, context windows, or file access  
**Mitigation:** Credential isolation, filesystem monitoring, read-only mounts

---

## 🛡️ Docker Hardening Checklist

Sandbox Claws implements all recommended Docker security flags:

### 1. **Read-Only Filesystem**

```yaml
read_only: true
tmpfs:
  - /tmp:rw,noexec,nosuid,size=64M
```

**Why:**
- Prevents attacker from writing malware to disk
- Can't modify system binaries
- Even with RCE, can't persist changes
- `tmpfs` allows temporary files but prevents execution (`noexec`)

### 2. **Drop Linux Capabilities**

```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # Only if needed
```

**Why:**
- Removes `SYS_ADMIN` (can't mount drives)
- Removes `NET_ADMIN` (can't modify network)
- Removes `SYS_MODULE` (can't load kernel modules)
- Principle of least privilege

### 3. **Prevent Privilege Escalation**

```yaml
security_opt:
  - no-new-privileges:true
```

**Why:**
- Prevents gaining privileges via `setuid` binaries
- Blocks privilege escalation exploits
- Even if attacker finds a vuln, can't escalate

### 4. **CPU and Memory Limits**

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'       # Max 1 CPU core
      memory: 2G        # Max 2GB RAM
    reservations:
      cpus: '0.5'       # Guaranteed 0.5 CPU
      memory: 512M      # Guaranteed 512MB
```

**Why:**
- Prevents resource exhaustion attacks
- Protects other containers
- Prevents denial-of-service
- Limits cost of runaway agents

### 5. **Non-Root User**

```yaml
user: "1000:1000"
```

**Why:**
- If container is compromised, attacker has limited privileges
- Can't modify system files
- Can't install packages
- Defense in depth

### 6. **Least-Privilege Volume Mounts**

```yaml
volumes:
  - ./openclaw-config:/app/config:ro      # Read-only
  - ./skills:/app/skills:ro               # Read-only
  - openclaw-data:/app/data               # Read-write (necessary)
```

**Why:**
- Agent can't modify skill files
- Can't overwrite config
- Prevents credential theft from mounted directories
- Specific mounts (not `~/` entire home directory)

---

## 🔒 Network Egress Control

### Three Security Profiles

#### **Basic** (Learning/Demos)
```yaml
# Full internet access
# No proxy
networks:
  - sandbox-claws
```

**Use when:** Learning, demos, non-sensitive data  
**Root Risk:** Medium (Container isolation only)  
**Keys Risk:** High (Can exfiltrate to any domain)

#### **Filtered** (Recommended Default)
```yaml
# Allowlist-only egress via Squid proxy
environment:
  - HTTP_PROXY=http://egress-filter:3128
  - HTTPS_PROXY=http://egress-filter:3128
networks:
  - sandbox-claws
depends_on:
  - egress-filter
```

**Use when:** Standard testing, CI/CD  
**Root Risk:** Low (Container + egress control)  
**Keys Risk:** Low (Only allowlisted domains)

**Allowlist Example:**
```
# security/allowed-domains.txt
api.openai.com
api.anthropic.com
github.com
*.googleapis.com
```

**Blocks:** Prevents data exfiltration to `attacker-site.com` even if agent tries

#### **Air-Gapped** (Maximum Security)
```yaml
# No internet access
# Uses mock APIs
networks:
  - sandbox-claws-isolated  # Isolated network
environment:
  - GMAIL_API_BASE=http://mock-apis:8080/gmail
```

**Use when:** PII, PHI, regulated data  
**Root Risk:** Minimal (Container + no network)  
**Keys Risk:** None (No external egress possible)

---

## 📊 Security Comparison

| Security Feature | Basic | Filtered | Air-Gapped |
|------------------|-------|----------|------------|
| **Container Isolation** | ✅ | ✅ | ✅ |
| **Read-only FS** | ✅ | ✅ | ✅ |
| **Dropped Capabilities** | ✅ | ✅ | ✅ |
| **CPU/Memory Limits** | ✅ | ✅ | ✅ |
| **Network Egress Control** | ❌ | ✅ Allowlist | ✅ None |
| **Data Exfiltration Risk** | High | Low | None |
| **Suitable For** | Demos | Testing | Production |

---

## 🚨 Common Mistakes to Avoid

### ❌ **Mistake 1: Running as Root**

**Bad:**
```yaml
# No user specified → runs as root
services:
  openclaw:
    image: openclaw/agent
```

**Good:**
```yaml
services:
  openclaw:
    image: openclaw/agent
    user: "1000:1000"
```

### ❌ **Mistake 2: Mounting Entire Home Directory**

**Bad:**
```yaml
volumes:
  - /Users/name:/app/home  # Exposes SSH keys, .aws/, photos
```

**Good:**
```yaml
volumes:
  - /Users/name/openclaw_workspace:/app/workspace:rw
  - /Users/name/docs:/app/docs:ro  # Read-only if only reading
```

### ❌ **Mistake 3: Default Tmpfs (Allows Execution)**

**Bad:**
```yaml
tmpfs:
  - /tmp  # Can execute scripts from /tmp
```

**Good:**
```yaml
tmpfs:
  - /tmp:rw,noexec,nosuid,size=64M  # Can't execute
```

### ❌ **Mistake 4: No Resource Limits**

**Bad:**
```yaml
# No limits → agent can consume all RAM/CPU
```

**Good:**
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
```

### ❌ **Mistake 5: Trusting Default Container**

**Bad:**
```bash
docker run openclaw/agent  # Default is too permissive
```

**Good:**
```bash
docker run \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64M \
  --security-opt=no-new-privileges \
  --cap-drop=ALL \
  --cpus="1.0" \
  --memory="2g" \
  -u 1000:1000 \
  openclaw/agent
```

---

## 🧪 Testing Your Configuration

### Verify Read-Only Filesystem

```bash
# Try to write to filesystem (should fail)
docker exec sandbox-claws-openclaw touch /test
# Expected: "Read-only file system"
```

### Verify Tmpfs is Non-Executable

```bash
# Try to execute script from /tmp (should fail)
docker exec sandbox-claws-openclaw sh -c 'echo "#!/bin/bash" > /tmp/test.sh && chmod +x /tmp/test.sh && /tmp/test.sh'
# Expected: "Permission denied"
```

### Verify CPU Limits

```bash
# Check CPU allocation
docker stats sandbox-claws-openclaw
# Should show max 100% (1 core)
```

### Verify Memory Limits

```bash
# Check memory allocation
docker inspect sandbox-claws-openclaw | grep -A 5 Memory
# Should show 2GB limit
```

### Verify Network Egress (Filtered Profile)

```bash
# Try to access blocked domain
docker exec sandbox-claws-openclaw-filtered curl http://attacker-site.com
# Expected: Connection failed (proxy blocked)

# Try to access allowed domain
docker exec sandbox-claws-openclaw-filtered curl https://api.openai.com
# Expected: Success
```

---

## 📚 References

### Official Documentation
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

### Security Research
- [Composio: Secure OpenClaw Setup](https://composio.dev/blog/secure-openclaw-moltbot-clawdbot-setup) - RAK Framework
- [Common AI Agent Security Anti-Patterns](https://www.thesystemguide.com/ai-agent-security-anti-patterns)
- [AI Agent Security Framework](https://manveerc.substack.com/p/ai-agent-security-framework)

### Related Guides
- [Advanced Security Features](./ADVANCED_SECURITY.md) - Skill scanning, credential isolation
- [Cost Controls](./COST_CONTROLS.md) - Budget enforcement
- [Security Deployment](../SECURITY_DEPLOYMENT.md) - Profile configuration

---

## 🎯 Summary

**Sandbox Claws implements defense-in-depth:**

1. ✅ **Container Isolation** (Root Risk mitigation)
2. ✅ **Hardened Runtime** (Read-only, dropped caps, no-new-privileges)
3. ✅ **Resource Limits** (CPU, memory constraints)
4. ✅ **Network Egress Control** (3 security profiles)
5. ✅ **Credential Isolation** (Filesystem monitoring, read-only mounts)
6. ✅ **Skill Scanning** (Malware detection)
7. ✅ **Cost Controls** (Budget enforcement, rate limiting)

**What Remains (Phase 2b):**
- ⚠️ Agent Transparency Dashboard (Agency Risk mitigation)
- ⚠️ Context Management (Overflow prevention)
- ⚠️ Circuit Breakers (Auto-stop failed actions)

---

**Ready to deploy with confidence!** 🦞🔒
