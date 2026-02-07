# Cost Controls & Budget Management

**Phase 2a Security Feature**  
*Addressing the #1 Pain Point from Reddit Community Feedback*

## Overview

The Cost Tracker prevents runaway API costs through real-time monitoring, budget enforcement, and rate limiting. Based on Reddit feedback, users have reported bills of $300-500 from uncontrolled AI agents. This feature provides comprehensive protection against "Denial of Wallet" attacks and accidental cost overruns.

## Reddit Community Feedback

### The Problem

From r/openclaw, r/clawdbot, and r/myclaw:

- **"My bill hit $437 in one night"** - User reported agent stuck in infinite loop
- **"No way to set spending limits"** - Requested budget caps before deployment
- **"Claude Opus is $15/1M tokens"** - Cost concerns with expensive models
- **"How do I track costs in real-time?"** - Need for visibility

### Our Solution

✅ **Session, hourly, and daily budget limits**  
✅ **Real-time cost tracking with live dashboard**  
✅ **Rate limiting (30 calls/minute default)**  
✅ **Automatic blocking when budget exceeded**  
✅ **Alerts at 80% budget threshold**  
✅ **Token counting and cost projections**

---

## Features

### 1. Budget Enforcement (Multi-Level)

Budget limits at three time scales prevent both short-term spikes and long-term drift:

```bash
# Default Budget Limits (configurable)
MAX_COST_PER_SESSION_USD=10.00   # Per testing session
MAX_COST_PER_HOUR_USD=50.00      # Rolling hourly limit
MAX_COST_PER_DAY_USD=200.00      # Daily cap
```

**How it works:**
- API calls are blocked BEFORE execution if they would exceed any limit
- Costs estimated using token counting + pricing data
- Budget resets automatically (hourly/daily) or manually (session)

### 2. Rate Limiting

Prevents API abuse and runaway loops:

```bash
MAX_API_CALLS_PER_MINUTE=30      # Max API calls per minute
MAX_TOKENS_PER_REQUEST=8000      # Max tokens per request
```

**Protection:**
- Blocks calls if rate exceeded
- Returns "retry after" time
- Tracks calls in sliding 60-second window

### 3. Real-Time Monitoring

Live dashboard with 5-second auto-refresh:

- 💰 **Budget Usage**: Session, hourly, daily costs with progress bars
- 🚦 **Rate Limits**: Current calls/minute with remaining capacity
- 🎯 **Token Tracking**: Input, output, and total tokens
- 📊 **Projections**: Average cost/call, cost/hour, remaining hours
- 🔔 **Alerts**: Warnings when approaching limits

### 4. Token Counting & Cost Estimation

Accurate cost prediction using:
- **tiktoken** for OpenAI/Claude models (when available)
- **Fallback approximation**: ~1.3 words per token
- **Model-specific pricing** from pricing.json

### 5. Alerts & Notifications

Automatic alerts:
- ⚠️ **80% budget**: Warning notification
- 🚫 **100% budget**: Calls blocked, session must reset
- 🔥 **90%+ rate limit**: Rate limit warning

---

## Quick Start

### 1. Deploy with Cost Tracker

```bash
# Start all services (includes cost-tracker)
./deploy.sh filtered

# Or start cost-tracker separately
docker-compose up -d cost-tracker
```

### 2. Access Web Dashboard

Navigate to the **Cost Tracker** section in the web UI:

```
http://localhost:8080/#costs
```

The dashboard auto-refreshes every 5 seconds.

### 3. Configure Budgets (Optional)

Edit `.env` to customize limits:

```bash
# Edit environment file
nano .env

# Add or modify cost control settings
MAX_COST_PER_SESSION_USD=20.00   # Increase session budget to $20
MAX_COST_PER_HOUR_USD=100.00     # Increase hourly budget
MAX_API_CALLS_PER_MINUTE=50      # Allow 50 calls/minute
ALERT_AT_PERCENT=75.0            # Alert at 75% instead of 80%
```

Restart cost-tracker after changes:

```bash
docker-compose restart cost-tracker
```

---

## API Reference

The Cost Tracker exposes a REST API on port 5003:

### Health Check

```bash
curl http://localhost:5003/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "cost-tracker"
}
```

### Get Current Statistics

```bash
curl http://localhost:5003/stats
```

**Response:**
```json
{
  "session": {
    "cost": 2.45,
    "budget": 10.00,
    "percent": 24.5,
    "remaining": 7.55,
    "calls": 12,
    "duration_seconds": 342,
    "avg_cost_per_call": 0.204
  },
  "hourly": {
    "cost": 2.45,
    "budget": 50.00,
    "percent": 4.9,
    "remaining": 47.55
  },
  "daily": {
    "cost": 5.30,
    "budget": 200.00,
    "percent": 2.65,
    "remaining": 194.70
  },
  "tokens": {
    "input": 15230,
    "output": 7840,
    "total": 23070
  },
  "rate": {
    "calls_this_minute": 3,
    "max_per_minute": 30,
    "calls_per_hour": 126,
    "cost_per_hour": 25.78
  },
  "projections": {
    "remaining_hours_at_current_rate": 0.29,
    "estimated_total_if_continues": 10.00
  }
}
```

### Check if Call is Allowed

```bash
curl -X POST http://localhost:5003/check \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Your prompt here",
    "model": "claude-opus-4.5"
  }'
```

**Response (Allowed):**
```json
{
  "allowed": true,
  "estimate": {
    "model": "claude-opus-4.5",
    "input_tokens": 45,
    "output_tokens": 23,
    "total_tokens": 68,
    "input_cost": 0.000675,
    "output_cost": 0.001725,
    "total_cost": 0.0024
  },
  "rate_limit": {
    "allowed": true,
    "calls_this_minute": 12,
    "max_per_minute": 30,
    "remaining": 18
  },
  "budget": {
    "allowed": true,
    "current_session_cost": 2.45,
    "estimated_cost": 0.0024,
    "session_percent": 24.5,
    "alert": false
  }
}
```

**Response (Blocked):**
```json
{
  "allowed": false,
  "reason": "rate_limit",
  "details": {
    "calls_this_minute": 30,
    "max_per_minute": 30,
    "retry_after_seconds": 42.3
  }
}
```

### Track an API Call

```bash
curl -X POST http://localhost:5003/track \
  -H "Content-Type: application/json" \
  -d '{
    "cost": 0.0024,
    "input_tokens": 45,
    "output_tokens": 23,
    "model": "claude-opus-4.5",
    "duration_ms": 1234
  }'
```

**Response:** Returns updated statistics (same as `/stats`)

### Get Alerts

```bash
curl http://localhost:5003/alerts
```

**Response:**
```json
{
  "alerts": [
    {
      "timestamp": "2026-02-07T12:34:56.789Z",
      "type": "budget_warning",
      "message": "⚠️ Budget at 82.5%",
      "session_cost": 8.25,
      "session_budget": 10.00
    }
  ],
  "count": 1
}
```

### Reset Session

```bash
curl -X POST http://localhost:5003/reset
```

**Response:**
```json
{
  "success": true,
  "message": "Session reset"
}
```

### Get Pricing Information

```bash
curl http://localhost:5003/pricing
```

**Response:**
```json
{
  "claude-opus-4.5": {
    "input_per_million": 15.00,
    "output_per_million": 75.00,
    "description": "Most capable model, highest cost"
  },
  ...
}
```

---

## Integration Examples

### Python Integration

```python
import requests

COST_TRACKER_URL = "http://localhost:5003"

def call_ai_agent(prompt, model="claude-opus-4.5"):
    # 1. Check if call is allowed
    check_response = requests.post(
        f"{COST_TRACKER_URL}/check",
        json={"prompt": prompt, "model": model}
    )
    check_data = check_response.json()
    
    if not check_data["allowed"]:
        reason = check_data.get("reason", "unknown")
        if reason == "rate_limit":
            retry_after = check_data["details"]["retry_after_seconds"]
            raise Exception(f"Rate limit exceeded. Retry after {retry_after}s")
        elif reason == "session_budget_exceeded":
            raise Exception("Session budget exceeded. Reset session or increase limit.")
        else:
            raise Exception(f"Call blocked: {reason}")
    
    # 2. Make the actual API call
    start_time = time.time()
    response = anthropic.messages.create(
        model=model,
        messages=[{"role": "user", "content": prompt}]
    )
    duration_ms = (time.time() - start_time) * 1000
    
    # 3. Track the call
    usage = response.usage
    cost = calculate_cost(usage.input_tokens, usage.output_tokens, model)
    
    requests.post(
        f"{COST_TRACKER_URL}/track",
        json={
            "cost": cost,
            "input_tokens": usage.input_tokens,
            "output_tokens": usage.output_tokens,
            "model": model,
            "duration_ms": duration_ms
        }
    )
    
    return response

def calculate_cost(input_tokens, output_tokens, model):
    # Get pricing
    pricing_response = requests.get(f"{COST_TRACKER_URL}/pricing")
    pricing = pricing_response.json()
    
    model_pricing = pricing.get(model, pricing["default"])
    
    input_cost = (input_tokens / 1_000_000) * model_pricing["input_per_million"]
    output_cost = (output_tokens / 1_000_000) * model_pricing["output_per_million"]
    
    return input_cost + output_cost
```

### Bash Integration

```bash
#!/bin/bash
# check_and_call.sh

COST_TRACKER_URL="http://localhost:5003"
PROMPT="Your prompt here"
MODEL="claude-opus-4.5"

# Check if call is allowed
CHECK_RESPONSE=$(curl -s -X POST "$COST_TRACKER_URL/check" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": \"$PROMPT\", \"model\": \"$MODEL\"}")

ALLOWED=$(echo "$CHECK_RESPONSE" | jq -r '.allowed')

if [ "$ALLOWED" != "true" ]; then
    echo "❌ Call blocked:"
    echo "$CHECK_RESPONSE" | jq -r '.reason'
    exit 1
fi

echo "✅ Call allowed. Making API request..."

# Make your API call here
# ...

# Track the call
curl -s -X POST "$COST_TRACKER_URL/track" \
  -H "Content-Type: application/json" \
  -d "{
    \"cost\": 0.0024,
    \"input_tokens\": 45,
    \"output_tokens\": 23,
    \"model\": \"$MODEL\",
    \"duration_ms\": 1234
  }" > /dev/null

echo "✅ Call tracked"
```

---

## Troubleshooting

### Cost Tracker Not Running

**Symptom:** Web UI shows "Cost Tracker Offline"

**Solution:**
```bash
# Check if service is running
docker-compose ps | grep cost-tracker

# Start the service
docker-compose up -d cost-tracker

# Check logs
docker-compose logs cost-tracker
```

### Budget Reset Not Working

**Symptom:** Session cost doesn't reset

**Solution:**
```bash
# Manual reset via API
curl -X POST http://localhost:5003/reset

# Or restart the service (also resets)
docker-compose restart cost-tracker
```

### Inaccurate Token Counting

**Symptom:** Cost estimates don't match actual usage

**Solution:**
1. Install tiktoken in the container for accurate counts:
   ```bash
   docker-compose exec cost-tracker pip install tiktoken
   docker-compose restart cost-tracker
   ```

2. Update pricing.json if using different models

### CORS Errors in Web UI

**Symptom:** Browser console shows CORS errors

**Solution:**
- Cost Tracker has CORS enabled by default
- Check that you're accessing UI and API from same hostname
- If using remote access, update COST_TRACKER_URL in main.js

---

## Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `COST_TRACKER_PORT` | `5003` | API server port |
| `MAX_COST_PER_SESSION_USD` | `10.00` | Session budget limit |
| `MAX_COST_PER_HOUR_USD` | `50.00` | Hourly budget limit |
| `MAX_COST_PER_DAY_USD` | `200.00` | Daily budget limit |
| `MAX_API_CALLS_PER_MINUTE` | `30` | Rate limit (calls/min) |
| `MAX_TOKENS_PER_REQUEST` | `8000` | Max tokens per request |
| `ALERT_AT_PERCENT` | `80.0` | Alert threshold (%) |

### Model Pricing

Pricing is configured in `docker/cost-tracker/pricing.json`:

```json
{
  "claude-opus-4.5": {
    "input_per_million": 15.00,
    "output_per_million": 75.00,
    "description": "Most capable model, highest cost"
  },
  "claude-sonnet-4.5": {
    "input_per_million": 3.00,
    "output_per_million": 15.00,
    "description": "Balanced performance and cost"
  },
  "default": {
    "input_per_million": 3.00,
    "output_per_million": 15.00,
    "description": "Default pricing if model not found"
  }
}
```

To add new models:
1. Edit `docker/cost-tracker/pricing.json`
2. Add model entry with pricing
3. Restart cost-tracker: `docker-compose restart cost-tracker`

---

## Best Practices

### 1. Set Conservative Budgets Initially

Start with low limits and increase as needed:

```bash
MAX_COST_PER_SESSION_USD=5.00    # Start with $5
MAX_COST_PER_HOUR_USD=25.00      # Start with $25/hour
```

### 2. Monitor Dashboard Regularly

Check the dashboard during testing:
- Watch for approaching limits
- Review cost projections
- Adjust if tests are being blocked

### 3. Use Cheaper Models for Testing

Use Haiku or Sonnet for initial testing:
- **Haiku**: $0.25 input / $1.25 output (per 1M tokens)
- **Sonnet**: $3.00 input / $15.00 output (per 1M tokens)
- **Opus**: $15.00 input / $75.00 output (per 1M tokens)

### 4. Reset Sessions Between Tests

```bash
# Reset session budget before major tests
curl -X POST http://localhost:5003/reset
```

### 5. Set Alerts Early

Get warnings before hitting limits:

```bash
ALERT_AT_PERCENT=75.0   # Alert at 75% instead of 80%
```

### 6. Review Call History

```bash
# Check recent API calls
curl http://localhost:5003/history?limit=50 | jq
```

### 7. Enable Logging

Review cost-tracker logs for audit trail:

```bash
docker-compose logs -f cost-tracker
```

---

## Comparison: Sandbox Claws vs Default OpenClaw

| Feature | OpenClaw (Default) | Sandbox Claws |
|---------|-------------------|---------------|
| Budget Limits | ❌ None | ✅ Session/Hourly/Daily |
| Cost Tracking | ❌ No | ✅ Real-time |
| Rate Limiting | ❌ No | ✅ 30 calls/minute |
| Cost Alerts | ❌ No | ✅ At 80% budget |
| Token Counting | ❌ No | ✅ tiktoken + fallback |
| Live Dashboard | ❌ No | ✅ Auto-refresh 5s |
| API Blocking | ❌ No | ✅ Before budget exceeded |
| Projections | ❌ No | ✅ Cost/hour + remaining |
| Multi-level Budget | ❌ No | ✅ 3 time scales |
| Manual Reset | ❌ N/A | ✅ API endpoint |

---

## Roadmap: Future Enhancements

Phase 2b (Planned):

- [ ] **Per-model budget limits** - Different limits for Opus vs Sonnet
- [ ] **Cost history graphs** - Visualize spending over time
- [ ] **Slack/email alerts** - Notifications to external channels
- [ ] **Multi-user support** - Track costs per user/project
- [ ] **Budget approval workflow** - Require approval for high-cost calls
- [ ] **Cost forecasting** - ML-based cost predictions
- [ ] **Integration with billing** - Direct API provider cost sync

---

## Support & Feedback

**Found a bug or have a suggestion?**

- Open an issue: https://github.com/samelliott1/sandbox-claws/issues
- Join the discussion on r/sandboxclaws (coming soon)

**Based on your feedback:**

This feature was prioritized based on Reddit community feedback from r/openclaw, r/clawdbot, and r/myclaw. Thank you for helping us build the features that matter most!

---

**Phase 2a Status:** ✅ Complete  
**Last Updated:** February 7, 2026
