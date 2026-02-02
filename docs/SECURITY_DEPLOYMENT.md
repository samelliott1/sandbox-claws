# 🔒 Sandbox Claws - Security Deployment Guide

## 🚨 **IMPORTANT: Data Exfiltration Risk**

**Your AI leader is correct:** Sandboxing alone does NOT prevent data exfiltration.

Even in an isolated container, an AI agent with network access can exfiltrate data through:
- ✅ Authorized API calls (Gmail, Calendar - legitimate traffic)
- ✅ DNS queries (data encoded in lookups)
- ✅ HTTP/HTTPS requests to any endpoint
- ✅ Cloud service uploads (Pastebin, GitHub Gists, file hosting)
- ✅ Timing attacks and covert channels

---

## 📊 Security Profiles

Sandbox Claws now supports **3 security profiles**:

| Profile | Network Access | Exfiltration Risk | Use Case |
|---------|---------------|-------------------|----------|
| **Basic** | Full internet | ⚠️ HIGH | Low-sensitivity testing |
| **Filtered** | Allowlist only | 🟡 MEDIUM | Normal testing |
| **Air-Gapped** | Zero internet | ✅ NONE | Sensitive data, compliance |

---

## 🎯 Deployment Options

### **Option 1: Basic Mode (Default)**

```bash
# Standard deployment
./deploy.sh
```

**What you get:**
- ✅ Container isolation
- ✅ Non-root execution
- ✅ Comprehensive logging
- ❌ **Agent can access ANY internet endpoint**

**Security controls:**
- Container can't escape to host
- Can't escalate privileges
- All actions logged

**Does NOT prevent:**
- Data sent via Gmail API
- Uploads to Pastebin/GitHub
- DNS exfiltration
- Any network-based data leaks

**Use when:**
- Testing with synthetic data only
- Learning the system
- Development/demo environments

**NEVER use with:**
- Real credentials
- Sensitive data
- Production information
- Personal information

---

### **Option 2: Filtered Mode (Recommended)** ⭐

```bash
# Deploy with egress filtering
docker compose --profile filtered up -d
```

**What you get:**
- ✅ All Basic Mode features
- ✅ **Squid proxy filters ALL outbound traffic**
- ✅ **Only approved domains accessible**
- ✅ Detailed traffic logs
- 🟡 Agent can only reach allowlisted APIs

**How it works:**
```
OpenClaw → Squid Proxy → Checks allowlist → Allow/Deny
```

**Allowed by default:**
- googleapis.com (Gmail, Calendar)
- google.com (Auth)
- OAuth endpoints

**Blocked:**
- pastebin.com ❌
- github.com (unless you add it) ❌
- All file-sharing services ❌
- Unknown APIs ❌

**Configuration:**
```bash
# Edit allowed domains
nano security/allowed-domains.txt

# Add your approved endpoints
echo "your-approved-api.com" >> security/allowed-domains.txt

# Restart proxy
docker compose restart egress-filter
```

**Use when:**
- Testing with semi-sensitive data
- You know which APIs should be accessed
- You want audit logs of all traffic
- Production testing (non-critical)

**Still vulnerable to:**
- Data exfiltration through approved APIs
- Encoding data in allowed API calls
- Timing-based covert channels

---

### **Option 3: Air-Gapped Mode (Maximum Security)** 🔒

```bash
# Deploy with ZERO internet access
docker compose --profile airgapped up -d
```

**What you get:**
- ✅ All container isolation
- ✅ **ZERO internet connectivity**
- ✅ Mock API server (Gmail, Calendar)
- ✅ **100% exfiltration prevention**
- ✅ Completely isolated network

**How it works:**
```
OpenClaw → Mock APIs (local) → No external network
         ↓
    172.29.0.0/16 (internal: true)
         ↓
    NO ROUTE TO INTERNET
```

**What works:**
- All agent functionality
- Email operations (against mocks)
- Calendar operations (against mocks)
- Complete testing workflows

**What doesn't work:**
- Real email delivery
- Real calendar sync
- Actual API integration
- Internet access (by design!)

**Mock API Setup:**
```bash
# Mocks are configured in mocks/initializer.json
# Example Gmail mock response:
{
  "httpRequest": {
    "path": "/gmail/v1/users/me/messages/send"
  },
  "httpResponse": {
    "statusCode": 200,
    "body": {
      "id": "mock-message-id",
      "threadId": "mock-thread-id"
    }
  }
}
```

**Use when:**
- Testing with sensitive data
- Compliance requirements (HIPAA, SOC2)
- Security audits
- Production-like testing without risk
- You need to prove zero exfiltration

**Perfect for:**
- Financial data
- Healthcare information
- PII/Sensitive customer data
- Trade secrets
- Security research

---

## 🛡️ Additional Security Layers

### **Data Loss Prevention (DLP) Scanner**

```bash
# Deploy with DLP scanning
docker compose --profile dlp up -d
```

**What it does:**
- Monitors all OpenClaw logs in real-time
- Scans for sensitive patterns:
  - Credit card numbers
  - Social Security Numbers
  - API keys / Private keys
  - AWS credentials
  - Email addresses
  - Passwords

**Alert example:**
```
🚨 DLP ALERT: API_KEY DETECTED
====================================
Time: 2026-02-01T15:30:45
File: openclaw.log
Line: 1234
Pattern: api_key
Preview: Found key: sk-abc123...
====================================
```

**Configuration:**
```bash
# Edit patterns
nano security/dlp-patterns.json

# Set action mode
DLP_ACTION=alert  # or 'block'
docker compose --profile dlp up -d
```

---

### **Combined: Maximum Security**

```bash
# Air-gapped + DLP + Network monitoring
docker compose --profile airgapped --profile dlp --profile monitoring up -d
```

**You get:**
- ✅ Zero internet access (air-gapped)
- ✅ DLP scanning of all logs
- ✅ Network traffic analysis
- ✅ Real-time alerts
- ✅ Complete audit trail

---

## 📈 Security Comparison

### **Attack Scenario: Agent tries to exfiltrate data**

| Attack Vector | Basic | Filtered | Air-Gapped |
|---------------|-------|----------|------------|
| Gmail API abuse | ❌ Works | ⚠️ Logged | ✅ Blocked |
| Upload to Pastebin | ❌ Works | ✅ Blocked | ✅ Blocked |
| DNS tunneling | ❌ Works | ⚠️ Logged | ✅ Blocked |
| GitHub upload | ❌ Works | ✅ Blocked* | ✅ Blocked |
| Timing covert channel | ❌ Works | ❌ Works | ⚠️ Limited |
| Encoding in API calls | ❌ Works | ⚠️ Detectable | ✅ Blocked |

*If not in allowlist

---

## 🎯 Recommended Configurations

### **For Learning / Demos:**
```bash
# Basic mode is fine
./deploy.sh
```
- Use fake data only
- Don't enter real credentials
- Treat as fully exposed

### **For Development:**
```bash
# Filtered mode
docker compose --profile filtered up -d
```
- Still use test accounts
- Audit logs regularly
- Review allowed-domains.txt

### **For Security Testing:**
```bash
# Air-gapped + DLP
docker compose --profile airgapped --profile dlp up -d
```
- Can test with realistic data
- Zero exfiltration risk
- Full audit trail

### **For Compliance / Production:**
```bash
# Maximum security
docker compose --profile airgapped --profile dlp --profile monitoring up -d
```
- SOC2 / HIPAA friendly
- Complete isolation
- Real-time monitoring
- Comprehensive logging

---

## 🔍 Monitoring & Auditing

### **Check Egress Filter Logs:**
```bash
# See all attempted connections
docker compose logs egress-filter | grep -i denied

# See allowed connections
docker compose logs egress-filter | grep -i tcp_miss
```

### **Check DLP Alerts:**
```bash
# Real-time DLP alerts
docker compose logs -f dlp-scanner

# View alert history
docker compose exec dlp-scanner cat /logs/dlp-alerts.log
```

### **Network Traffic Analysis:**
```bash
# Start network monitor
docker compose --profile monitoring up -d network-monitor

# Access at http://localhost:3000
open http://localhost:3000
```

---

## ⚖️ Risk Acceptance

### **What Sandbox Claws CAN'T Prevent:**

Even with all security profiles, some risks remain:

1. **Steganography** - Data hidden in allowed API responses
2. **Timing channels** - Using response times to encode data
3. **Approved API abuse** - Exfiltrating via Gmail (if allowed)
4. **Side channels** - CPU usage, memory patterns, etc.

### **Mitigation:**

1. **Never use production credentials**
2. **Use air-gapped mode** for sensitive data
3. **Review all logs** after testing
4. **Limit test data** to what's necessary
5. **Rotate test accounts** regularly

---

## 📚 References

- [Full Data Exfiltration Analysis](DATA_EXFILTRATION.md)
- [Testing Guide](TESTING_GUIDE.md)
- [Docker Deployment](DOCKER.md)

---

## 🎓 Security Summary

**Remember:**
- 🔒 **Sandboxing ≠ Exfiltration Prevention**
- 🔒 **Network access = Exfiltration risk**
- 🔒 **Air-gapped = Only true prevention**
- 🔒 **Logging = Detection, not prevention**
- 🔒 **Test accounts only, always**

**Choose your security profile based on data sensitivity, not convenience.**

---

**Questions about security configurations?** See [DATA_EXFILTRATION.md](DATA_EXFILTRATION.md) for detailed threat analysis.