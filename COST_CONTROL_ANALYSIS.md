# Cost Control Analysis
## Current State vs. User Concerns

**Date:** February 7, 2026  
**Issue:** Reddit shows major concerns about "Denial of Wallet" attacks

---

## 🚨 **Current State: NO COST CONTROLS IMPLEMENTED**

### **What We Have:**
- ❌ No rate limiting
- ❌ No cost tracking
- ❌ No budget limits
- ❌ No token counting
- ❌ No web UI visibility
- ⚠️ Basic `OPENCLAW_RATE_LIMIT=10` in .env (but not enforced!)

### **What We Documented (but didn't build):**
- Phase 1 focused on security (skills, RCE, credentials, filesystem)
- Phase 2 (not implemented) includes Cost Controls
- Roadmap mentions it as **HIGH PRIORITY** but not built

---

## 📊 **Reddit Concerns (r/openclaw, r/clawdbot, r/myclaw)**

### **Common Complaints:**

1. **"Lighting money on fire"**
   - Opus 4.5 costs $5-15 per million tokens
   - Simple tasks rack up hundreds of dollars
   - No warning when costs exceed budget

2. **"Infinite loops bankrupted me"**
   - Agent got stuck in a loop
   - Made 1000+ API calls before noticed
   - $500+ bill in one hour

3. **"No visibility into costs"**
   - Can't see how much spent
   - No breakdown by task
   - No alerts before hitting credit card

4. **"Can't set limits"**
   - No per-session caps
   - No per-hour/day limits
   - All or nothing

---

## ❌ **Gap Analysis**

| Feature | Status | Impact | User Request |
|---------|--------|--------|--------------|
| **Rate Limiting** | ❌ Not implemented | HIGH | "Stop after N calls" |
| **Cost Tracking** | ❌ Not implemented | CRITICAL | "Show me costs" |
| **Budget Limits** | ❌ Not implemented | CRITICAL | "Stop at $X" |
| **Token Counting** | ❌ Not implemented | HIGH | "Tokens per request" |
| **Web UI Dashboard** | ❌ Not implemented | HIGH | "See costs live" |
| **Cost Alerts** | ❌ Not implemented | CRITICAL | "Warn at 80%" |
| **Per-Task Breakdown** | ❌ Not implemented | MEDIUM | "Cost by test" |

---

## 🎯 **What Sandbox Claws Should Have**

### **Phase 2a: Cost Controls (URGENT)**

#### **1. Rate Limiter Service**
```python
# docker/rate-limiter/limiter.py
class CostController:
    def __init__(self):
        self.session_cost = 0.0
        self.max_session_cost = 10.0  # $10 default
        self.calls_this_minute = 0
        self.max_calls_per_minute = 30
        
    def check_budget(self, estimated_cost: float):
        if self.session_cost + estimated_cost > self.max_session_cost:
            raise BudgetExceededError(
                f"Would exceed budget: ${self.session_cost:.2f} + ${estimated_cost:.2f} > ${self.max_session_cost}"
            )
        
    def track_call(self, actual_cost: float):
        self.session_cost += actual_cost
        self.calls_this_minute += 1
```

#### **2. Web UI Dashboard**
```html
<!-- Add to index.html -->
<div class="cost-monitor">
    <h3>💰 Cost Monitor</h3>
    <div class="cost-gauge">
        <div class="progress">
            <div class="progress-bar" id="cost-progress"></div>
        </div>
        <p>
            <strong id="current-cost">$0.00</strong> / 
            <span id="budget-limit">$10.00</span>
        </p>
    </div>
    
    <div class="stats">
        <div class="stat">
            <label>API Calls</label>
            <strong id="api-calls">0</strong>
        </div>
        <div class="stat">
            <label>Tokens Used</label>
            <strong id="tokens-used">0</strong>
        </div>
        <div class="stat">
            <label>Avg Cost/Call</label>
            <strong id="avg-cost">$0.00</strong>
        </div>
    </div>
    
    <button onclick="resetCostTracking()" class="btn btn-warning">
        Reset Session
    </button>
</div>
```

#### **3. Cost Estimation**
```python
# Estimate before making call
def estimate_cost(prompt: str, model: str) -> float:
    """Estimate cost before API call."""
    token_count = len(prompt.split()) * 1.3  # rough estimate
    
    pricing = {
        "claude-opus-4.5": {
            "input": 15.00 / 1_000_000,
            "output": 75.00 / 1_000_000
        },
        "claude-sonnet-4.5": {
            "input": 3.00 / 1_000_000,
            "output": 15.00 / 1_000_000
        }
    }
    
    estimated = token_count * pricing[model]["input"]
    estimated += token_count * 0.5 * pricing[model]["output"]  # assume 50% output
    
    return estimated
```

#### **4. Budget Configuration**
```bash
# .env additions
MAX_COST_PER_SESSION_USD=10.00
MAX_COST_PER_HOUR_USD=50.00
MAX_COST_PER_DAY_USD=200.00
MAX_API_CALLS_PER_MINUTE=30
MAX_TOKENS_PER_REQUEST=8000
ALERT_AT_PERCENT=80
```

---

## 🏗️ **Implementation Plan**

### **Step 1: Cost Tracker Service (2 hours)**
```yaml
# docker-compose.yml
cost-tracker:
  build: ./docker/cost-tracker
  container_name: sandbox-claws-cost-tracker
  ports:
    - "5003:5003"
  environment:
    - MAX_SESSION_COST=${MAX_COST_PER_SESSION_USD:-10.00}
    - MAX_CALLS_PER_MINUTE=${MAX_API_CALLS_PER_MINUTE:-30}
  volumes:
    - ./cost-data:/data
  networks:
    - sandbox-claws
```

### **Step 2: Web UI Integration (2 hours)**
- Add cost monitor widget to index.html
- Live updates via WebSocket or polling
- Visual progress bar (green → yellow → red)
- Alert modal when approaching limit

### **Step 3: Proxy Integration (2 hours)**
- Intercept OpenClaw API calls
- Estimate cost before call
- Check budget
- Track actual cost after response
- Block calls if over budget

### **Step 4: Documentation (1 hour)**
- Update README with cost controls
- Create COST_CONTROLS.md guide
- Update Phase 2 status

**Total Time:** ~7 hours

---

## 📊 **Web UI Mockup**

```
┌─────────────────────────────────────────┐
│ 💰 Cost Monitor                         │
├─────────────────────────────────────────┤
│ Budget: $2.45 / $10.00                  │
│ [████████░░░░░░░░░░] 24%               │
│                                         │
│ 📊 Session Stats                        │
│   API Calls:        47                  │
│   Tokens Used:      125,342             │
│   Avg Cost/Call:    $0.052              │
│   Time Remaining:   ~3.5 hours @ rate   │
│                                         │
│ ⚠️ Alerts                               │
│   • Approaching half budget             │
│   • 15 calls in last minute (limit: 30) │
│                                         │
│ [Reset Session] [Export Report]         │
└─────────────────────────────────────────┘
```

---

## 🚨 **Priority Assessment**

### **Why This is CRITICAL:**

1. **User #1 Pain Point:** Cost overruns are the most complained about issue
2. **Testing Framework:** Cost controls are essential for a testing environment
3. **Enterprise Adoption:** No company will use this without cost caps
4. **Competitive Advantage:** Most agent frameworks don't have this
5. **Easy Win:** Relatively simple to implement, huge user value

### **Reddit Evidence:**

From r/openclaw:
> "Opus lit my wallet on fire in 20 minutes. $300 gone before I noticed."

From r/clawdbot:
> "We need a kill switch. A hard budget limit. Something."

From r/myclaw:
> "Can we get a cost dashboard? I have no idea what I'm spending."

---

## ✅ **Recommendation**

**Implement Cost Controls IMMEDIATELY as Phase 2a (before Phase 2b):**

**Phase 2a: Cost Controls (7 hours)**
1. Cost Tracker Service
2. Web UI Dashboard
3. Budget Enforcement
4. Documentation

**Benefits:**
- ✅ Addresses #1 user pain point
- ✅ Makes Sandbox Claws enterprise-ready
- ✅ Differentiates from competitors
- ✅ Relatively quick implementation
- ✅ High user satisfaction

**Then continue with:**
- Phase 2b: Skill Allowlist
- Phase 2c: Network Behavior Analysis

---

## 🎯 **Should We Build This Now?**

**Arguments FOR:**
- 🔥 Most requested feature on Reddit
- 🔥 Blocks enterprise adoption without it
- 🔥 Easy to implement (~7 hours)
- 🔥 High ROI (effort vs impact)

**Arguments AGAINST:**
- Phase 1 security is more critical (but done!)
- Could wait for user feedback on current version
- OpenClaw itself should handle this (but doesn't)

**My Recommendation:** **YES, build it now as Phase 2a**

It's the most impactful feature we can add in the shortest time.

---

## 📋 **Next Steps**

If you want cost controls:

1. **Create docker/cost-tracker/ service** (2 hours)
2. **Add web UI dashboard** (2 hours)
3. **Integrate with OpenClaw proxy** (2 hours)
4. **Documentation** (1 hour)
5. **Test and commit** (1 hour)

**Total:** ~8 hours for full cost control implementation

---

**Should I start building Cost Controls now?** 🚀💰

- Option A: **Build it now** (8 hours, Phase 2a)
- Option B: **Document it only** (update roadmap, wait for feedback)
- Option C: **Different priority** (what else is urgent?)

Let me know! This is definitely a critical gap.
