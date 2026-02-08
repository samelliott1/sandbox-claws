# NanoClaw Integration Guide

**Test NanoClaw Skills Safely** | Security Layer for Personal AI Assistants

---

## 🎯 Why Test NanoClaw Skills in Sandbox Claws?

NanoClaw is brilliant for personal use—minimal, understandable, container-isolated. But it has **zero cost controls** and **no skill scanning**. Sandbox Claws acts as your **testing safety net** before adding skills to your personal assistant.

### The Philosophy Alignment

| Aspect | NanoClaw | Sandbox Claws | Together |
|--------|----------|---------------|----------|
| **Security Model** | Container isolation | Container + egress control | ✅ Defense in depth |
| **Target Use** | Personal assistant | Testing framework | ✅ Test → Deploy workflow |
| **Complexity** | ~5 files, minimal | Focused testing harness | ✅ Both stay simple |
| **Cost Awareness** | ❌ None | ✅ Real-time tracking | ✅ Prevent $500 bills |
| **Skill Safety** | ❌ Trust-based | ✅ Malware scanning | ✅ Test before personal use |

### Real Risks

Even with container isolation, NanoClaw skills can:
- ❌ Make unlimited API calls → $500 bills
- ❌ Access mounted directories → data exfiltration
- ❌ Hit 200K token context limit → expensive errors
- ❌ Contain malicious patterns → compromise your data

**Sandbox Claws prevents these disasters.**

---

## 🚀 Quick Start: Test NanoClaw Skills

### Prerequisites

- Docker installed
- NanoClaw already running
- Anthropic API key

### Step 1: Clone Sandbox Claws

```bash
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws
```

### Step 2: AI-Native Setup (Recommended)

```bash
# Option A: Use Claude Code to set everything up
claude

# In Claude Code, say:
"Set up Sandbox Claws with filtered security profile. 
Use the Anthropic API key from my NanoClaw installation. 
Configure for testing NanoClaw skills with cost limits of 
$5 per session, $20 per hour, $50 per day."
```

### Step 3: Manual Setup (Alternative)

```bash
# Make deployment script executable
chmod +x deploy-sandbox-claws.sh

# Deploy with filtered egress
./deploy-sandbox-claws.sh filtered

# Configure API key
nano .env.openclaw
# Add: ANTHROPIC_API_KEY=your_key_here

# Set conservative cost limits for skill testing
echo "MAX_COST_PER_SESSION_USD=5.00" >> .env.openclaw
echo "MAX_COST_PER_HOUR_USD=20.00" >> .env.openclaw
echo "MAX_COST_PER_DAY_USD=50.00" >> .env.openclaw

# Restart services
docker-compose restart openclaw cost-tracker
```

### Step 4: Access Dashboard

Open your browser to:
- **Main Dashboard**: http://localhost:8080
- **Cost Tracker**: http://localhost:8080/#costs
- **Logs**: http://localhost:8081

---

## 🛡️ Testing NanoClaw Skills Safely

### Workflow: Test → Validate → Deploy

```
┌─────────────────────────────────────────────────────────┐
│  1. Test Skill in Sandbox Claws                         │
│     ✓ Scan for malware patterns                         │
│     ✓ Monitor API costs                                 │
│     ✓ Check context usage                               │
│     ✓ Verify behavior                                   │
├─────────────────────────────────────────────────────────┤
│  2. If Safe → Add to NanoClaw                           │
│     ✓ Known cost per use                                │
│     ✓ Validated security                                │
│     ✓ Tested functionality                              │
└─────────────────────────────────────────────────────────┘
```

### Test 1: Validate New Skill Before Personal Use

**Scenario:** You found a `/add-telegram` skill and want to add it to your NanoClaw

```bash
# 1. Copy skill to Sandbox Claws
cp /path/to/add-telegram.md ./skills/

# 2. Scan for malicious patterns
curl -X POST http://localhost:5001/scan

# 3. Check scan results
curl http://localhost:5001/results/add-telegram

# Example safe result:
# {
#   "skill_name": "add-telegram",
#   "is_safe": true,
#   "threat_level": "low",
#   "findings": []
# }

# 4. If safe, test functionality in isolated environment
docker-compose exec openclaw bash
# Test the skill's behavior

# 5. Monitor costs on dashboard
# Visit http://localhost:8080/#costs
# Check: Session cost, API calls, token usage

# 6. If cost acceptable and behavior correct → add to NanoClaw
cp ./skills/add-telegram.md ~/nanoclaw/.claude/skills/add-telegram/SKILL.md
```

### Test 2: Estimate Costs Before Daily Use

**Scenario:** You want to add a scheduled morning briefing to NanoClaw

```bash
# 1. Write the skill in Sandbox Claws
cat > ./skills/morning-briefing.md << 'EOF'
# Morning Briefing Skill
Every morning at 9am:
- Check Hacker News top 10 stories
- Summarize AI developments
- Check calendar for today
- Message me a briefing
EOF

# 2. Test it manually first
# Send a test message simulating the morning briefing

# 3. Check cost on dashboard
# Example result: $0.45 per briefing

# 4. Calculate daily cost
# 1 briefing/day × 30 days = $13.50/month

# 5. If acceptable → schedule in NanoClaw
# 6. Set budget alert in NanoClaw to warn if exceeds estimate
```

### Test 3: Validate Community Skills

**Scenario:** Someone contributed `/add-gmail` to NanoClaw repo

```bash
# 1. Clone their skill
git clone https://github.com/contributor/nanoclaw-gmail-skill.git
cp nanoclaw-gmail-skill/SKILL.md ./skills/gmail-skill.md

# 2. Scan for security issues
curl -X POST http://localhost:5001/scan-file \
  -H "Content-Type: application/json" \
  -d '{"filename": "gmail-skill.md"}'

# 3. Check for:
# - Credential access patterns (OAuth tokens)
# - Data exfiltration attempts
# - Destructive commands
# - Obfuscation

# 4. Review scan results
curl http://localhost:5001/results/gmail-skill

# Example unsafe result:
# {
#   "skill_name": "gmail-skill",
#   "is_safe": false,
#   "threat_level": "high",
#   "findings": [
#     "Credential access pattern detected: .gmail/credentials.json",
#     "Data exfiltration: curl to external domain"
#   ]
# }

# 5. If unsafe → report to contributor and DO NOT use
# 6. If safe → test functionality before adding to NanoClaw
```

### Test 4: Debug Context Overflow Issues

**Scenario:** Your NanoClaw keeps hitting 200K token limit during long conversations

```bash
# 1. Simulate the conversation in Sandbox Claws
# 2. Monitor context usage on dashboard
# Visit http://localhost:8080/#costs

# Dashboard shows:
# - Current context: 145K / 200K tokens (72%)
# - Warning: Approaching context limit
# - Recommendation: Add /clear command to NanoClaw

# 3. Test /clear behavior in sandbox
# 4. Measure cost of context compaction
# 5. If working well → add to NanoClaw
```

---

## 📊 Dashboard Overview for NanoClaw Testing

### Cost Tracking Dashboard

```
┌─────────────────────────────────────────────────────────┐
│  Testing: morning-briefing.md skill                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Cost Tracking (Test Run):                              │
│  Session:  $0.45 / $5.00    [████░░░░░░] 9%            │
│  Hourly:   $0.45 / $20.00   [█░░░░░░░░░] 2%            │
│  Daily:    $0.45 / $50.00   [░░░░░░░░░░] 1%            │
│                                                          │
│  Rate Limiting:                                          │
│  API Calls: 3 / 30 per minute                           │
│  Tokens:    2,450 / 8,000 per request                   │
│                                                          │
│  💰 Cost Analysis:                                      │
│  Average per run: $0.45                                 │
│  Daily (1 run):   $0.45                                 │
│  Monthly (30):    $13.50                                │
│                                                          │
│  ✅ Safe to deploy to NanoClaw                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Security Scan Dashboard

```
┌─────────────────────────────────────────────────────────┐
│  Skill Security Scan: add-telegram.md                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Scan Results:                                           │
│  ✅ No credential access patterns                       │
│  ✅ No data exfiltration attempts                       │
│  ✅ No destructive commands                             │
│  ✅ No obfuscation detected                             │
│  ✅ No remote code execution                            │
│  ✅ No crypto mining patterns                           │
│                                                          │
│  Threat Level: LOW                                       │
│  Recommendation: SAFE TO USE                             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🤖 AI-Native Setup with Claude Code

### Create Setup Skill

Create `.claude/skills/setup-sandbox-claws/SKILL.md`:

```markdown
# Setup Sandbox Claws for NanoClaw Testing

## Description
Sets up Sandbox Claws as a testing environment for NanoClaw skills.
Configures filtered security profile with cost controls optimized for skill testing.

## Steps

1. Clone Sandbox Claws:
   ```bash
   git clone https://github.com/samelliott1/sandbox-claws.git
   cd sandbox-claws
   ```

2. Make deploy script executable:
   ```bash
   chmod +x deploy-sandbox-claws.sh
   ```

3. Deploy with filtered profile:
   ```bash
   ./deploy-sandbox-claws.sh filtered
   ```

4. Configure environment:
   - Copy Anthropic API key from NanoClaw
   - Set conservative cost limits for testing:
     - Session: $5.00
     - Hourly: $20.00
     - Daily: $50.00

5. Create .env.openclaw with:
   ```bash
   ANTHROPIC_API_KEY=<from NanoClaw>
   MAX_COST_PER_SESSION_USD=5.00
   MAX_COST_PER_HOUR_USD=20.00
   MAX_COST_PER_DAY_USD=50.00
   MAX_API_CALLS_PER_MINUTE=30
   MAX_TOKENS_PER_REQUEST=8000
   ALERT_AT_PERCENT=80.0
   ```

6. Restart services:
   ```bash
   docker-compose restart openclaw cost-tracker
   ```

7. Verify setup:
   - Dashboard: http://localhost:8080
   - Cost tracker: http://localhost:8080/#costs
   - Logs: http://localhost:8081

## Success Criteria
- All services running
- Cost tracker showing $0.00 / limits
- Dashboard accessible
- Ready to test NanoClaw skills
```

### Usage

```bash
cd nanoclaw
claude

# Then in Claude Code:
"Use the /setup-sandbox-claws skill to create a testing environment 
for validating skills before I add them to my personal NanoClaw."
```

---

## 🧪 Testing Workflows

### Workflow 1: Test Skill from Community

```bash
# In Claude Code:
"I found a /add-notion skill in the NanoClaw community. 
Before adding it to my personal assistant:
1. Copy it to Sandbox Claws
2. Scan for security issues
3. Test functionality
4. Estimate monthly cost
5. Report findings"
```

**Claude will:**
1. ✅ Copy skill to `./skills/`
2. ✅ Run malware scan via API
3. ✅ Test in isolated container
4. ✅ Monitor costs on dashboard
5. ✅ Calculate monthly estimate
6. ✅ Report: "Safe to use, ~$15/month"

### Workflow 2: Debug Expensive Operation

```bash
# In Claude Code:
"My NanoClaw morning briefing is costing more than expected.
Test it in Sandbox Claws and figure out why."
```

**Claude will:**
1. ✅ Run briefing in sandbox
2. ✅ Monitor token usage
3. ✅ Check API call count
4. ✅ Analyze cost breakdown
5. ✅ Suggest optimizations
6. ✅ Report: "Uses 5K tokens per search, reduce to 2 searches instead of 5"

### Workflow 3: Validate Scheduled Task

```bash
# In Claude Code:
"I want to add a weekly git history summary to NanoClaw.
Test it in Sandbox Claws first and estimate costs."
```

**Claude will:**
1. ✅ Create test git repo
2. ✅ Run summary task
3. ✅ Measure cost ($0.30)
4. ✅ Calculate weekly: $1.20
5. ✅ Calculate monthly: $5.20
6. ✅ Report: "Safe to deploy, ~$5/month"

---

## 🔧 Configuration Cheatsheet

### Essential Environment Variables

```bash
# Conservative limits for skill testing
MAX_COST_PER_SESSION_USD=5.00    # Single skill test
MAX_COST_PER_HOUR_USD=20.00      # Multiple tests
MAX_COST_PER_DAY_USD=50.00       # Full day of testing

# Rate limiting
MAX_API_CALLS_PER_MINUTE=30      # Prevent runaway skills
MAX_TOKENS_PER_REQUEST=8000      # Context limit

# Alerts
ALERT_AT_PERCENT=80.0            # Warn at 80% budget

# Ports
COST_TRACKER_PORT=5003           # Cost tracker API
SKILL_SCANNER_PORT=5001          # Malware scanner API
WEB_PORT=8080                    # Dashboard
LOG_PORT=8081                    # Logs
```

### Security Profiles for NanoClaw Testing

```bash
# Filtered (Recommended)
./deploy-sandbox-claws.sh filtered
# - Blocks non-allowlisted domains
# - DLP scanning enabled
# - Skill scanning enabled
# - Good for testing community skills

# Air-gapped (Maximum Security)
./deploy-sandbox-claws.sh airgapped
# - No external network
# - Mock APIs only
# - Test skill logic without real API calls
# - Good for debugging skill structure
```

---

## 🐛 Troubleshooting

### Issue: "Claude Code can't find Sandbox Claws"

**Solution:**
```bash
# Make sure you're in the right directory
cd ~/sandbox-claws
claude

# Or specify the path in your request
"Use Sandbox Claws at ~/sandbox-claws to test this skill"
```

### Issue: "Cost tracker shows $0.00"

**Solution:**
```bash
# Verify API key matches NanoClaw
cat .env.openclaw | grep ANTHROPIC_API_KEY
cat ~/nanoclaw/.env | grep ANTHROPIC_API_KEY

# Should be the same. If not:
cp ~/nanoclaw/.env .env.openclaw

# Restart cost tracker
docker-compose restart cost-tracker
```

### Issue: "Skill scan returns empty"

**Solution:**
```bash
# Verify skills directory is mounted
ls -la ./skills/

# Manually trigger scan
curl -X POST http://localhost:5001/scan

# Check scanner logs
docker-compose logs skill-scanner
```

---

## 📚 Comparison: NanoClaw vs Sandbox Claws

### NanoClaw (Personal AI Assistant)

**Purpose:** Your personal assistant you can understand and customize

**Strengths:**
- ✅ Minimal codebase (~5 files)
- ✅ Fork-and-modify philosophy
- ✅ Container isolation (Apple Container or Docker)
- ✅ AI-native setup (Claude Code)
- ✅ Skills over features
- ✅ WhatsApp integration
- ✅ Scheduled tasks
- ✅ Per-group context isolation

**Gaps:**
- ❌ No cost tracking
- ❌ No budget limits
- ❌ No skill malware scanning
- ❌ No egress filtering
- ❌ No context overflow alerts
- ❌ No rate limiting

### Sandbox Claws (Testing Safety Net)

**Purpose:** Test AI agent skills safely before deploying to personal use

**Strengths:**
- ✅ Real-time cost tracking
- ✅ Multi-level budget enforcement
- ✅ Automatic skill malware scanning
- ✅ Egress filtering (3 security profiles)
- ✅ Context overflow monitoring
- ✅ Rate limiting (30 calls/min default)
- ✅ Visual debugging dashboard
- ✅ DLP scanning

**Use Together:**
```
Test skills in Sandbox Claws
      ↓
Validate: security, cost, behavior
      ↓
Deploy to NanoClaw with confidence
```

---

## 💡 Best Practices

### 1. Always Test Community Skills First

```bash
# Before running /add-telegram in NanoClaw
# Test it in Sandbox Claws first:

cd ~/sandbox-claws
cp ~/Downloads/add-telegram-skill.md ./skills/

# Ask Claude to test it
claude
"Test the add-telegram skill:
1. Scan for security issues
2. Test functionality
3. Estimate cost
4. Report if safe to use in NanoClaw"
```

### 2. Estimate Costs for Scheduled Tasks

```bash
# Before scheduling daily briefings in NanoClaw
# Test cost in Sandbox Claws:

claude
"Test this morning briefing skill:
- HN top 10 stories
- AI news summary
- Calendar check
Estimate daily and monthly cost."

# Example output:
# "Daily: $0.45, Monthly: $13.50
#  Safe to schedule in NanoClaw"
```

### 3. Use Filtered Mode for Realistic Testing

```bash
# Don't use airgapped for NanoClaw skill testing
# Skills need real API access
./deploy-sandbox-claws.sh filtered
```

### 4. Set Conservative Budgets

```bash
# Start with low limits for initial testing
MAX_COST_PER_SESSION_USD=2.00
MAX_COST_PER_HOUR_USD=10.00
MAX_COST_PER_DAY_USD=25.00

# After validating behavior, increase if needed
```

### 5. Test Context-Heavy Operations

```bash
# Before adding long-running tasks to NanoClaw
# Test context usage in Sandbox Claws:

claude
"Simulate a long conversation (50+ messages) 
and monitor context usage. 
Alert me if approaching 200K tokens."
```

---

## 🔗 Resources

### Documentation
- [NanoClaw Repository](https://github.com/gavrielc/nanoclaw)
- [NanoClaw Security Model](https://github.com/gavrielc/nanoclaw/blob/main/docs/SECURITY.md)
- [Cost Controls Guide](../security/COST_CONTROLS.md)
- [Advanced Security Features](../security/ADVANCED_SECURITY.md)
- [Testing Guide](../TESTING_GUIDE.md)

### NanoClaw Community
- [GitHub Issues](https://github.com/gavrielc/nanoclaw/issues)
- [GitHub Discussions](https://github.com/gavrielc/nanoclaw/discussions)

### Sandbox Claws Support
- [GitHub Issues](https://github.com/samelliott1/sandbox-claws/issues)
- [GitHub Discussions](https://github.com/samelliott1/sandbox-claws/discussions)

---

## 🎯 Key Takeaways

✅ **NanoClaw + Sandbox Claws = Safe Personal AI**

1. **NanoClaw** is your personal assistant (minimal, customizable)
2. **Sandbox Claws** is your testing safety net (security, cost controls)
3. Test skills in Sandbox Claws → Deploy to NanoClaw
4. Prevent $500 bills with budget enforcement
5. Catch malicious skills before personal use
6. Estimate costs before scheduling tasks
7. AI-native setup with Claude Code

**Philosophy Alignment:**
- Both use container isolation (not application-level security)
- Both value simplicity and understandability
- NanoClaw = personal software you modify
- Sandbox Claws = testing framework you configure

**Security Model:**
- **NanoClaw**: Container isolation (trust but isolate)
- **Sandbox Claws**: Container + egress control (verify before trust)

**Workflow:**
```
1. Find skill (community, create custom)
   ↓
2. Test in Sandbox Claws (scan, cost, behavior)
   ↓
3. Validate (security ✓, cost ✓, works ✓)
   ↓
4. Deploy to NanoClaw (with confidence)
```

**Ready to test NanoClaw skills safely?**

```bash
# In NanoClaw directory:
claude

# Say to Claude:
"/setup-sandbox-claws to create a testing environment for my NanoClaw skills"
```

Happy testing! 🦞🔒
