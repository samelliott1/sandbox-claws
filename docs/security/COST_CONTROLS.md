# Cost Controls & Budget Enforcement

**Phase 2a Feature** | Addresses the #1 pain point from Reddit community

---

## 🚨 The Problem: "Denial of Wallet"

Reddit users report **$300-500 bills** from uncontrolled OpenClaw agents:

- **r/openclaw**: "My agent ran overnight and cost me $437"
- **r/clawdbot**: "Infinite loop burned through $215 in 4 hours"  
- **r/myclaw**: "No way to set budget limits - lighting money on fire"

### Root Causes
1. **No cost tracking** - Users don't know current spend until bill arrives
2. **No budget limits** - Agents can run indefinitely
3. **No rate limiting** - Recursive agent loops can make thousands of API calls
4. **No projections** - Can't predict when budget will be exhausted

---

## ✅ Sandbox Claws Solution

Sandbox Claws **Phase 2a** adds comprehensive cost controls:

### 1. Real-Time Cost Tracking
- **Session budget** - Track spending per testing session
- **Hourly budget** - Hourly rolling window (resets every hour)
- **Daily budget** - Daily cap (resets at midnight UTC)
- **Live dashboard** - Real-time cost updates every 5 seconds

### 2. Budget Enforcement
- **Hard limits** - Automatically block API calls when budget exceeded
- **Soft warnings** - Alert at 80% of budget (configurable)
- **Graceful shutdown** - Save state before hitting budget limit

### 3. Rate Limiting
- **Calls per minute** - Prevent infinite loops
- **Token limits** - Cap maximum tokens per request
- **Sliding window** - Fair rate limiting with burst support

### 4. Projections & Analytics
- **Average cost per call** - Track efficiency
- **Cost per hour** - Predict hourly spend rate
- **Remaining hours** - Estimate time until budget exhausted
- **Estimated total** - Project final cost based on current rate

---

## 🎯 Quick Start

### 1. Enable Cost Controls

Edit `.env` and set your budget limits:

```bash
# Session Budget (per testing session)
MAX_COST_PER_SESSION_USD=10.00

# Hourly Budget (resets every hour)
MAX_COST_PER_HOUR_USD=50.00

# Daily Budget (resets at midnight UTC)
MAX_COST_PER_DAY_USD=200.00

# Rate Limiting
MAX_API_CALLS_PER_MINUTE=30

# Token Limits
MAX_TOKENS_PER_REQUEST=8000

# Alert Threshold (% of budget before warning)
ALERT_AT_PERCENT=80.0
```

### 2. Start Cost Tracker

```bash
# Start with cost tracking enabled
docker-compose --profile filtered up -d

# Verify cost-tracker is running
docker ps | grep cost-tracker

# Check health
curl http://localhost:5003/health
```

### 3. Access Dashboard

Open **http://localhost:8080** and scroll to **Cost Tracking & Budget Controls** section.

You'll see:
- ✅ Session, hourly, and daily budgets with progress bars
- ✅ Rate limiting status
- ✅ Token usage stats
- ✅ Cost projections
- ✅ Real-time alerts

---

## 📊 Cost Tracking API

The cost-tracker service exposes a REST API at `http://localhost:5003`:

### Health Check
```bash
GET /health

Response:
{
  "status": "healthy",
  "uptime": 1234.56,
  "version": "1.0.0"
}
```

### Get Statistics
```bash
GET /stats

Response:
{
  "session": {
    "cost": 2.35,
    "budget": 10.00,
    "percent": 23.5,
    "calls": 15
  },
  "hourly": {
    "cost": 12.80,
    "budget": 50.00,
    "percent": 25.6,
    "reset_in_seconds": 1842
  },
  "daily": {
    "cost": 45.20,
    "budget": 200.00,
    "percent": 22.6,
    "reset_in_seconds": 42600
  },
  "rate": {
    "calls_this_minute": 8,
    "max_per_minute": 30,
    "remaining": 22
  },
  "tokens": {
    "input": 125000,
    "output": 48000,
    "total": 173000
  }
}
```

### Track API Call
```bash
POST /track
Content-Type: application/json

{
  "model": "claude-opus-4.5",
  "input_tokens": 500,
  "output_tokens": 1200,
  "cost_usd": 0.0425
}

Response:
{
  "success": true,
  "session_cost": 2.3925,
  "hourly_cost": 12.8425,
  "daily_cost": 45.2425,
  "budget_ok": true,
  "alerts": []
}
```

### Get Alerts
```bash
GET /alerts

Response:
{
  "alerts": [
    {
      "level": "warning",
      "message": "Session budget at 82% ($8.20 of $10.00)",
      "timestamp": "2026-02-07T08:30:15Z"
    }
  ]
}
```

### Reset Session
```bash
POST /reset/session

Response:
{
  "success": true,
  "message": "Session budget reset"
}
```

---

## 🔥 Alert System

### Alert Levels

| Level | Trigger | Action |
|-------|---------|--------|
| **INFO** | 50% budget | Log only |
| **WARNING** | 80% budget | Display alert in UI |
| **CRITICAL** | 95% budget | Alert + warning message |
| **BLOCKED** | 100% budget | Block API calls + notification |

### Sample Alerts

**80% Warning:**
```
⚠️  Session budget at 82% ($8.20 of $10.00)
   Estimated 2.5 hours remaining at current rate
```

**100% Blocked:**
```
🚫  Daily budget exhausted ($200.00 of $200.00)
   All API calls blocked until midnight UTC
   Consider increasing MAX_COST_PER_DAY_USD in .env
```

**Rate Limit:**
```
⏸️  Rate limit reached (30 calls/minute)
   Throttling requests. Please slow down.
```

---

## 💡 Best Practices

### 1. Start Conservative
Begin with **low budgets** and increase as needed:
```bash
MAX_COST_PER_SESSION_USD=5.00   # Start small
MAX_COST_PER_HOUR_USD=25.00     # Conservative hourly
MAX_COST_PER_DAY_USD=100.00     # Safe daily max
```

### 2. Monitor Projections
Check **Cost/Hour** projection regularly:
- ✅ **$1-5/hour** - Typical for focused testing
- ⚠️  **$10-20/hour** - Heavy usage, monitor closely
- 🚨 **$50+/hour** - Investigate immediately (possible runaway agent)

### 3. Set Rate Limits
Prevent infinite loops with aggressive rate limiting:
```bash
MAX_API_CALLS_PER_MINUTE=20  # Stricter limit
```

### 4. Review Alerts Daily
Check the alerts section for:
- Repeated budget warnings (optimize agent prompts)
- High token usage (simplify context)
- Rate limit hits (fix agent loops)

### 5. Use Session Budgets
Reset session budget between major tests:
```bash
curl -X POST http://localhost:5003/reset/session
```

---

## 📈 Understanding the Pricing

### Claude Opus 4.5 Pricing (Feb 2026)
- **Input tokens**: $15.00 per 1M tokens
- **Output tokens**: $75.00 per 1M tokens

### Example Calculations

**Single API call:**
- Input: 500 tokens = $0.0075
- Output: 1,200 tokens = $0.0900
- **Total**: $0.0975

**100 calls/hour:**
- Cost = 100 × $0.0975 = **$9.75/hour**
- Daily projection = 24 × $9.75 = **$234/day**

**Rate limiting example:**
- 30 calls/min max = **1,800 calls/hour** maximum
- Worst case: 1,800 × $0.0975 = **$175.50/hour** 🚨
- This is why rate limiting is critical!

---

## 🔧 Configuration Options

### Environment Variables

```bash
# .env file

# Session Budget (per testing session)
# Default: $10.00
# Recommended: $5-20 for testing, $50+ for production
MAX_COST_PER_SESSION_USD=10.00

# Hourly Budget (resets every hour)
# Default: $50.00
# Recommended: $25-100 depending on workload
MAX_COST_PER_HOUR_USD=50.00

# Daily Budget (resets at midnight UTC)
# Default: $200.00
# Recommended: $100-500 depending on scale
MAX_COST_PER_DAY_USD=200.00

# Rate Limiting (calls per minute)
# Default: 30
# Recommended: 10-30 for testing, 50-100 for production
MAX_API_CALLS_PER_MINUTE=30

# Token Limits (max tokens per request)
# Default: 8000
# Recommended: 4000-8000 to prevent expensive single calls
MAX_TOKENS_PER_REQUEST=8000

# Alert Threshold (percentage)
# Default: 80.0
# Recommended: 70-90 (lower = more warnings)
ALERT_AT_PERCENT=80.0
```

### Restart After Changes

```bash
# Apply new config
docker-compose restart cost-tracker

# Verify new limits
curl http://localhost:5003/stats | jq '.session.budget'
```

---

## 🐛 Troubleshooting

### Cost tracker not responding

**Symptom:** Web UI shows "Cost Tracker Offline"

**Solution:**
```bash
# Check if service is running
docker ps | grep cost-tracker

# Check logs
docker-compose logs cost-tracker

# Restart service
docker-compose restart cost-tracker
```

### Budgets not resetting

**Symptom:** Hourly/daily budgets don't reset at expected times

**Solution:**
- Check container timezone: `docker exec -it sandbox-claws-cost-tracker date`
- Verify UTC time sync
- Restart cost-tracker: `docker-compose restart cost-tracker`

### Alerts not appearing

**Symptom:** No alerts shown even when budget exceeded

**Solution:**
```bash
# Check alert threshold
echo $ALERT_AT_PERCENT  # Should be < 100

# Manual alert check
curl http://localhost:5003/alerts

# Check browser console for JavaScript errors
```

### Rate limiting too aggressive

**Symptom:** Legitimate requests getting blocked

**Solution:**
```bash
# Increase rate limit in .env
MAX_API_CALLS_PER_MINUTE=60

# Restart
docker-compose restart cost-tracker
```

---

## 🎓 Advanced Features

### Custom Budget Profiles

Create multiple .env files for different scenarios:

**`.env.testing` (Conservative)**
```bash
MAX_COST_PER_SESSION_USD=5.00
MAX_COST_PER_HOUR_USD=20.00
MAX_COST_PER_DAY_USD=50.00
MAX_API_CALLS_PER_MINUTE=15
```

**`.env.production` (Generous)**
```bash
MAX_COST_PER_SESSION_USD=50.00
MAX_COST_PER_HOUR_USD=200.00
MAX_COST_PER_DAY_USD=1000.00
MAX_API_CALLS_PER_MINUTE=100
```

Switch profiles:
```bash
# Testing mode
docker-compose --env-file .env.testing up -d

# Production mode
docker-compose --env-file .env.production up -d
```

### Cost Notifications

Integrate with external alerting (future enhancement):

```bash
# Webhook on budget alerts (roadmap)
COST_ALERT_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Email alerts (roadmap)
COST_ALERT_EMAIL=admin@example.com
```

### Export Cost Reports

```bash
# Get full cost history (future)
curl http://localhost:5003/export/csv > costs_2026-02.csv

# Monthly summary (future)
curl http://localhost:5003/report/monthly?month=2026-02
```

---

## 📚 Related Documentation

- **[Phase 1 Security Features](PHASE_1_SECURITY.md)** - Skill scanner, filesystem monitor
- **[Security Roadmap](../ROADMAP.md)** - Complete security enhancement plan
- **[AI Agent Security Research](../analysis/AI_AGENT_SECURITY_RESEARCH.md)** - Industry context

---

## 🆘 Support

### Getting Help

1. **Check logs**: `docker-compose logs cost-tracker`
2. **Verify health**: `curl http://localhost:5003/health`
3. **Review config**: `docker exec sandbox-claws-cost-tracker env | grep MAX_`
4. **GitHub Issues**: [Report bugs](https://github.com/samelliott1/sandbox-claws/issues)

### Common Questions

**Q: Does cost tracking work with all AI models?**  
A: Currently supports Claude Opus 4.5. Other models require pricing.json updates.

**Q: Can I track costs across multiple sessions?**  
A: Yes! Hourly and daily budgets persist across sessions. Only session budget resets.

**Q: What happens when budget is exceeded?**  
A: Cost tracker returns HTTP 429 (Too Many Requests) and the agent pauses gracefully.

**Q: Can I disable cost tracking?**  
A: Yes, simply don't start the cost-tracker profile or remove it from docker-compose.yml

---

## ✨ Impact

### Before Phase 2a
- ❌ No cost visibility
- ❌ $300-500 surprise bills
- ❌ Runaway agents
- ❌ No budget control

### After Phase 2a
- ✅ Real-time cost tracking
- ✅ Configurable budget limits
- ✅ Automatic shutdown at budget
- ✅ Predictive analytics
- ✅ Rate limiting
- ✅ Peace of mind 😌

---

**Next:** [Phase 2b - Skill Allowlist](../ROADMAP.md#phase-2b-skill-allowlist) | **Prev:** [Phase 1 Security](PHASE_1_SECURITY.md)
