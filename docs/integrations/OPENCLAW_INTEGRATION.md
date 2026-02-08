# OpenClaw Integration Guide

**Test OpenClaw Agents Safely** | The Missing Safety Net for OpenClaw Development

---

## 🎯 Why Test OpenClaw in Sandbox Claws?

OpenClaw is powerful but has **zero built-in safety controls**. Sandbox Claws acts as your **testing safety net** before deploying to production.

### The Gap

| OpenClaw Feature | Missing Safety | Sandbox Claws Solution |
|------------------|----------------|------------------------|
| **Multi-channel agents** | No cost tracking | ✅ Real-time cost monitoring |
| **ClawHub skills** | No malware scanning | ✅ Automatic skill scanning |
| **Memory system** | No context monitoring | ✅ Context overflow alerts |
| **Sub-agents** | No rate limiting | ✅ 30 calls/min default limit |
| **Browser automation** | No budget caps | ✅ Multi-level budgets |
| **Cron jobs** | No failure detection | ✅ Circuit breaker protection |

### Real Costs from Reddit

> "My OpenClaw agent ran overnight and cost me **$437**"  
> — r/openclaw user

> "Infinite loop burned through **$215 in 4 hours**"  
> — r/clawdbot user

> "Hit **$500 bill** testing sub-agents. No way to set limits."  
> — r/AI_Agents user

**Sandbox Claws prevents these disasters.**

---

## 🚀 Quick Start: Test Your OpenClaw Agent

### Prerequisites

- Docker installed
- OpenClaw workspace directory
- Anthropic API key

### Step 1: Clone Sandbox Claws

```bash
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws
```

### Step 2: Configure API Keys

```bash
# Copy OpenClaw credentials
cp ~/.openclaw/openclaw.json ./openclaw-config/

# Or set API key directly
echo "ANTHROPIC_API_KEY=your_key_here" >> .env.openclaw
```

### Step 3: Deploy with Security Profile

```bash
# Make deployment script executable
chmod +x deploy-sandbox-claws.sh

# Deploy with filtered egress (recommended for testing)
./deploy-sandbox-claws.sh filtered
```

### Step 4: Access Dashboard

Open your browser to:
- **Main Dashboard**: http://localhost:8080
- **Cost Tracker**: http://localhost:8080/#costs
- **Logs**: http://localhost:8081

---

## 🛡️ Testing OpenClaw Features Safely

### 1. Test ClawHub Skills

**Problem:** ClawHub marketplace has **malware risks** ([Reddit reports](https://www.reddit.com/r/AI_Agents/comments/1qvynpz/))

**Solution:** Sandbox Claws scans skills automatically

```bash
# Copy your OpenClaw skills
cp -r ~/.openclaw/skills/ ./skills/

# Deploy - skills are auto-scanned
./deploy-sandbox-claws.sh filtered

# Check scan results
curl http://localhost:5001/results
```

**What Gets Scanned:**
- ✅ Credential access patterns
- ✅ Data exfiltration attempts
- ✅ Destructive commands
- ✅ Remote code execution
- ✅ Obfuscation techniques
- ✅ Crypto mining indicators
- ✅ Reverse shell patterns

### 2. Test Cost-Heavy Operations

**Problem:** OpenClaw has **no cost awareness** ([mega-cheatsheet](https://moltfounders.com/openclaw-mega-cheatsheet))

**Solution:** Set budgets before testing

```bash
# Edit .env.openclaw
MAX_COST_PER_SESSION_USD=5.00    # Test with $5 limit
MAX_COST_PER_HOUR_USD=20.00      # $20/hour cap
MAX_COST_PER_DAY_USD=50.00       # $50/day max

# Restart cost tracker
docker-compose restart cost-tracker
```

**Test Operations:**
```javascript
// Visit cost dashboard
window.location = 'http://localhost:8080/#costs';

// Watch real-time spending
// - Session budget: $0.45 / $5.00
// - Hourly budget: $0.45 / $20.00
// - Calls: 3 / 30 per minute
```

### 3. Test Context-Heavy Workflows

**Problem:** OpenClaw requires **manual context management** (`/context list`, `/compact`)

**Solution:** Automatic context monitoring

```bash
# Dashboard shows:
# - Current context usage (tokens)
# - Warning at 80% (e.g., 160K / 200K)
# - Auto-alert before overflow
```

**Example Test:**
```bash
# Test long conversation
# 1. Start agent in Sandbox Claws
# 2. Send 50 messages
# 3. Watch context usage on dashboard
# 4. Get alert before hitting 200K token limit
```

### 4. Test Sub-Agent Spawning

**Problem:** Sub-agents can **run wild** with no oversight

**Solution:** Rate limiting + cost tracking per sub-agent

```bash
# Set conservative limits for sub-agent testing
MAX_API_CALLS_PER_MINUTE=10      # Lower limit for sub-agents
MAX_TOKENS_PER_REQUEST=4000      # Smaller context windows

# Test sub-agent spawning
# Each sub-agent call is tracked and rate-limited
```

### 5. Test Cron Jobs & Heartbeats

**Problem:** Failed cron jobs run silently in OpenClaw

**Solution:** Monitor failures in real-time

```bash
# Check logs dashboard
open http://localhost:8081

# Filter for:
# - Heartbeat failures
# - Cron job errors
# - Cost anomalies
```

---

## 📊 Dashboard Overview

### Main Dashboard (http://localhost:8080)

```
┌─────────────────────────────────────────────────────────┐
│  Sandbox Claws Dashboard                                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Security Status:                                        │
│  ✅ Skill Scanner: Active                               │
│  ✅ Cost Tracker: Active                                │
│  ✅ Egress Filter: Filtered Mode                        │
│  ✅ DLP Scanner: Active                                 │
│                                                          │
│  Cost Controls (Live):                                   │
│  Session:  $2.45 / $5.00    [████████░░] 49%           │
│  Hourly:   $2.45 / $20.00   [██░░░░░░░░] 12%           │
│  Daily:    $2.45 / $50.00   [█░░░░░░░░░] 5%            │
│                                                          │
│  Rate Limiting:                                          │
│  API Calls: 12 / 30 per minute                          │
│  Tokens:    2,450 / 8,000 per request                   │
│                                                          │
│  Recent Alerts:                                          │
│  🟢 All systems normal                                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Cost Tracker Dashboard (http://localhost:8080/#costs)

```
┌─────────────────────────────────────────────────────────┐
│  Real-Time Cost Tracking                                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  📊 Cost Projections:                                   │
│  Average per call:   $0.204                             │
│  Cost per hour:      $12.24                             │
│  Remaining hours:    0.85h (51 minutes)                 │
│                                                          │
│  📈 Usage Statistics:                                   │
│  Total API calls:    12                                 │
│  Input tokens:       14,230                             │
│  Output tokens:      3,420                              │
│                                                          │
│  ⚠️  Alerts:                                            │
│  Session budget at 80% - approaching limit!             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration Cheatsheet

### Essential Environment Variables

```bash
# Cost Controls
MAX_COST_PER_SESSION_USD=10.00   # Per testing session
MAX_COST_PER_HOUR_USD=50.00      # Hourly rolling window
MAX_COST_PER_DAY_USD=200.00      # Daily cap (resets midnight UTC)

# Rate Limiting
MAX_API_CALLS_PER_MINUTE=30      # Prevent infinite loops
MAX_TOKENS_PER_REQUEST=8000      # Context limit per call

# Alerts
ALERT_AT_PERCENT=80.0            # Warn at 80% of budget

# Ports
COST_TRACKER_PORT=5003           # Cost tracker API
WEB_PORT=8080                    # Dashboard
LOG_PORT=8081                    # Dozzle logs
```

### Security Profiles

```bash
# Basic (No filtering)
./deploy-sandbox-claws.sh basic

# Filtered (Recommended for testing)
./deploy-sandbox-claws.sh filtered
# - Blocks non-allowlisted domains
# - DLP scanning enabled
# - Skill scanning enabled

# Air-gapped (Maximum security)
./deploy-sandbox-claws.sh airgapped
# - No external network access
# - Uses mock APIs
# - Isolated container network
```

---

## 🧪 Example Testing Workflows

### Test 1: Validate New Skill Before Production

```bash
# 1. Copy skill from ClawHub
cp ~/Downloads/new-skill.md ~/.openclaw/skills/

# 2. Copy to Sandbox Claws for testing
cp ~/.openclaw/skills/new-skill.md ./skills/

# 3. Deploy and scan
./deploy-sandbox-claws.sh filtered

# 4. Check scan results
curl http://localhost:5001/results/new-skill

# 5. If safe, use in production OpenClaw
# 6. If malicious, report to ClawHub
```

### Test 2: Estimate Production Costs

```bash
# 1. Set realistic test budget
echo "MAX_COST_PER_SESSION_USD=2.00" >> .env.openclaw

# 2. Run typical workflow
# - Send 10 test messages
# - Use memory search 5 times
# - Spawn 1 sub-agent

# 3. Check cost projections
curl http://localhost:5003/stats

# Example response:
# {
#   "cost": 1.23,
#   "avg_cost_per_call": 0.123,
#   "cost_per_hour": 7.38,
#   "estimated_remaining_hours": 0.10
# }

# 4. Extrapolate to production
# If 10 messages = $1.23
# Then 1000 messages/day ≈ $123/day
```

### Test 3: Debug Context Overflow

```bash
# 1. Start agent with long conversation
# 2. Monitor context on dashboard
# 3. Watch for 80% warning (160K / 200K tokens)
# 4. Test /compact behavior
# 5. Verify context reduction
# 6. Check cost impact of compaction
```

### Test 4: Stress Test Sub-Agents

```bash
# 1. Lower rate limits for stress testing
MAX_API_CALLS_PER_MINUTE=5

# 2. Spawn multiple sub-agents
# 3. Watch for rate limiting
# 4. Verify graceful backoff
# 5. Check cost accumulation
```

---

## 🐛 Troubleshooting

### Issue: OpenClaw Logs Not Appearing

**Solution:**
```bash
# Mount OpenClaw log directory
docker-compose exec openclaw ln -s /app/logs /openclaw-logs
```

### Issue: Cost Tracker Shows $0.00

**Solution:**
```bash
# Verify API key is configured
docker-compose exec cost-tracker env | grep ANTHROPIC

# Check cost tracker logs
docker-compose logs cost-tracker

# Restart cost tracker
docker-compose restart cost-tracker
```

### Issue: Skills Not Being Scanned

**Solution:**
```bash
# Verify skills directory is mounted
ls -la ./skills/

# Manually trigger scan
curl -X POST http://localhost:5001/scan

# Check scanner logs
docker-compose logs skill-scanner
```

### Issue: Context Overflow Not Detected

**Solution:**
```bash
# Context monitoring is automatic
# Check dashboard at http://localhost:8080/#costs
# Or query API:
curl http://localhost:5003/stats
```

---

## 📚 Comparison: OpenClaw vs Sandbox Claws

### OpenClaw (Production Agent Framework)

**Purpose:** Run AI agents 24/7 across multiple channels

**Strengths:**
- Multi-channel support (WhatsApp, Telegram, Discord, etc.)
- Advanced memory system (vector search, BM25 hybrid)
- Sub-agent orchestration
- Browser automation
- Cron jobs & heartbeats
- Rich ecosystem (ClawHub, hooks, skills)

**Gaps:**
- ❌ No cost tracking
- ❌ No budget limits
- ❌ No rate limiting
- ❌ No malware scanning
- ❌ Manual context management
- ❌ Complex troubleshooting

### Sandbox Claws (Testing & Safety Framework)

**Purpose:** Test AI agents safely before production

**Strengths:**
- ✅ Real-time cost tracking
- ✅ Multi-level budget enforcement
- ✅ Automatic rate limiting
- ✅ Skill malware scanning
- ✅ Context overflow alerts
- ✅ Visual debugging dashboard
- ✅ Security profiles (basic, filtered, air-gapped)
- ✅ DLP scanning

**Use Together:**
1. **Test in Sandbox Claws** - Validate agents, estimate costs, scan skills
2. **Deploy in OpenClaw** - Run production agents with confidence
3. **Monitor with Sandbox Claws** - Periodic testing, cost validation

---

## 🎯 Best Practices

### 1. Always Test New Skills First

```bash
# Before adding to OpenClaw
cp new-skill.md ./sandbox-claws/skills/
./deploy-sandbox-claws.sh filtered
# Check scan results before using in production
```

### 2. Estimate Costs Before Scaling

```bash
# Test with realistic workload in Sandbox Claws
# Check projections on dashboard
# Calculate: (test_cost / test_messages) × production_volume
```

### 3. Test Context-Heavy Workflows

```bash
# Long conversations
# Memory-intensive operations
# Multi-agent orchestration
# Watch dashboard for context warnings
```

### 4. Use Filtered Mode for Testing

```bash
# Don't use "airgapped" for OpenClaw testing
# OpenClaw needs external API access
# "filtered" mode = good balance
./deploy-sandbox-claws.sh filtered
```

### 5. Set Conservative Budgets

```bash
# Start small when testing
MAX_COST_PER_SESSION_USD=2.00   # $2 for initial test
# Increase after validating behavior
MAX_COST_PER_SESSION_USD=10.00  # $10 for full workflow test
```

---

## 🔗 Resources

### Documentation
- [OpenClaw Mega Cheatsheet](https://moltfounders.com/openclaw-mega-cheatsheet)
- [Cost Controls Guide](../security/COST_CONTROLS.md)
- [Advanced Security Features](../security/ADVANCED_SECURITY.md)
- [Testing Guide](../TESTING_GUIDE.md)

### Reddit Communities
- [r/openclaw](https://reddit.com/r/openclaw) - OpenClaw discussions
- [r/clawdbot](https://reddit.com/r/clawdbot) - Community support
- [r/AI_Agents](https://reddit.com/r/AI_Agents) - AI agent ecosystem

### Support
- [GitHub Issues](https://github.com/samelliott1/sandbox-claws/issues)
- [GitHub Discussions](https://github.com/samelliott1/sandbox-claws/discussions)

---

## 💡 Key Takeaways

✅ **OpenClaw + Sandbox Claws = Safe AI Agent Development**

1. Sandbox Claws is **not a replacement** for OpenClaw
2. It's a **testing safety net** that fills critical gaps
3. Test agents in Sandbox Claws → Deploy in OpenClaw
4. Prevent $500 bills with budget enforcement
5. Catch malicious skills before production
6. Estimate costs before scaling

**Ready to test your OpenClaw agent safely?**

```bash
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws
./deploy-sandbox-claws.sh filtered
open http://localhost:8080
```

Happy testing! 🦞🔒
