# Setup Sandbox Claws

## Description
Automatically sets up Sandbox Claws testing environment with security profiles and cost controls.
Detects existing configurations (NanoClaw, OpenClaw) and applies intelligent defaults.

## When to Use
- First-time Sandbox Claws setup
- Testing AI agent skills safely
- Configuring cost controls and security profiles
- Setting up for OpenClaw or NanoClaw integration

## What This Skill Does
1. Checks if Sandbox Claws is already cloned, clones if needed
2. Detects existing API keys from NanoClaw or OpenClaw
3. Configures security profile (basic, filtered, airgapped)
4. Sets up cost controls based on testing needs
5. Deploys all services
6. Verifies setup and reports dashboard URLs

## Steps

### 1. Check for Existing Installation

```bash
# Check if already in sandbox-claws directory
if [ -f "deploy-sandbox-claws.sh" ]; then
    echo "✓ Already in Sandbox Claws directory"
else
    echo "Cloning Sandbox Claws..."
    git clone https://github.com/samelliott1/sandbox-claws.git
    cd sandbox-claws
fi
```

### 2. Detect Existing API Keys

```bash
# Check for NanoClaw API key
if [ -f "$HOME/nanoclaw/.env" ]; then
    ANTHROPIC_KEY=$(grep ANTHROPIC_API_KEY "$HOME/nanoclaw/.env" | cut -d= -f2)
    echo "✓ Found API key from NanoClaw"
# Check for OpenClaw API key  
elif [ -f "$HOME/.openclaw/openclaw.json" ]; then
    ANTHROPIC_KEY=$(jq -r '.auth.anthropic.apiKey' "$HOME/.openclaw/openclaw.json")
    echo "✓ Found API key from OpenClaw"
else
    echo "⚠ No existing API key found"
    echo "Get one at: https://console.anthropic.com/settings/keys"
    read -p "Enter your Anthropic API key: " ANTHROPIC_KEY
fi
```

### 3. Configure Security Profile

Ask the user or infer from context:

**For NanoClaw testing:**
- Default: `filtered` (blocks non-allowlisted domains)
- Reason: Test skills safely with real API access

**For OpenClaw testing:**
- Default: `filtered` (same reason)

**For maximum security testing:**
- Option: `airgapped` (no external network)
- Reason: Test skill logic without real APIs

**For learning/demos:**
- Option: `basic` (full internet access)
- Reason: No restrictions

```bash
# Set default based on detected environment
if [ -d "$HOME/nanoclaw" ]; then
    PROFILE="filtered"
    echo "✓ Detected NanoClaw - using 'filtered' profile"
elif [ -d "$HOME/.openclaw" ]; then
    PROFILE="filtered"
    echo "✓ Detected OpenClaw - using 'filtered' profile"
else
    PROFILE="filtered"
    echo "✓ Using 'filtered' profile (recommended default)"
fi
```

### 4. Configure Cost Controls

Set conservative limits for testing:

```bash
# Create .env.openclaw with cost controls
cat > .env.openclaw << EOF
# Anthropic API Key
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}

# Cost Controls (Conservative for Testing)
MAX_COST_PER_SESSION_USD=5.00      # Per skill test
MAX_COST_PER_HOUR_USD=20.00        # Multiple tests
MAX_COST_PER_DAY_USD=50.00         # Full day testing

# Rate Limiting
MAX_API_CALLS_PER_MINUTE=30        # Prevent runaway loops
MAX_TOKENS_PER_REQUEST=8000        # Context limit per request

# Alerts
ALERT_AT_PERCENT=80.0              # Warn at 80% budget

# Ports
COST_TRACKER_PORT=5003
SKILL_SCANNER_PORT=5001
WEB_PORT=8080
LOG_PORT=8081
EOF

echo "✓ Created .env.openclaw with cost controls"
```

### 5. Deploy Services

```bash
# Make script executable
chmod +x deploy-sandbox-claws.sh

# Deploy with selected profile
echo "Deploying with ${PROFILE} security profile..."
./deploy-sandbox-claws.sh ${PROFILE}

# Wait for services to start
echo "Waiting for services to initialize..."
sleep 10
```

### 6. Verify Setup

```bash
# Check if services are running
docker-compose ps

# Test cost tracker
COST_STATUS=$(curl -s http://localhost:5003/health)
if [[ $COST_STATUS == *"healthy"* ]]; then
    echo "✓ Cost tracker: Running"
else
    echo "⚠ Cost tracker: Check logs"
fi

# Test skill scanner
SCAN_STATUS=$(curl -s http://localhost:5001/health)
if [[ $SCAN_STATUS == *"healthy"* ]]; then
    echo "✓ Skill scanner: Running"
else
    echo "⚠ Skill scanner: Check logs"
fi

# Test dashboard
if curl -s http://localhost:8080 > /dev/null; then
    echo "✓ Dashboard: Running"
else
    echo "⚠ Dashboard: Check logs"
fi
```

### 7. Report Results

Provide user with:

```markdown
🎉 Sandbox Claws Setup Complete!

**Dashboard URLs:**
- Main Dashboard: http://localhost:8080
- Cost Tracker: http://localhost:8080/#costs
- Logs: http://localhost:8081

**Configuration:**
- Security Profile: ${PROFILE}
- Session Budget: $5.00
- Hourly Budget: $20.00
- Daily Budget: $50.00
- Rate Limit: 30 calls/min

**Next Steps:**

For NanoClaw users:
1. Copy skills to test: `cp ~/nanoclaw/.claude/skills/*/SKILL.md ./skills/`
2. Scan skills: `curl http://localhost:5003/scan`
3. View results on dashboard

For OpenClaw users:
1. Copy skills to test: `cp ~/.openclaw/skills/*.md ./skills/`
2. Test workflows from OpenClaw Integration Guide
3. Monitor costs in real-time

**Useful Commands:**
- View all services: `docker-compose ps`
- View logs: `docker-compose logs -f`
- Restart cost tracker: `docker-compose restart cost-tracker`
- Stop all services: `docker-compose down`
- Uninstall: `./uninstall-sandbox-claws.sh`

Happy testing! 🦞🔒
```

## Error Handling

### If Docker not installed:
```bash
echo "⚠ Docker not found. Installing..."
# The deploy script handles this automatically
./deploy-sandbox-claws.sh ${PROFILE}
```

### If API key invalid:
```bash
# Test API key with simple request
TEST_RESULT=$(curl -s -X POST https://api.anthropic.com/v1/messages \
    -H "x-api-key: ${ANTHROPIC_KEY}" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{
        "model": "claude-3-5-sonnet-20241022",
        "max_tokens": 10,
        "messages": [{"role": "user", "content": "Hi"}]
    }')

if [[ $TEST_RESULT == *"error"* ]]; then
    echo "⚠ API key appears invalid. Please check and try again."
    exit 1
fi
```

### If ports already in use:
```bash
# Check if ports are available
for PORT in 8080 8081 5001 5003; do
    if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "⚠ Port ${PORT} already in use"
        echo "Options:"
        echo "1. Stop conflicting service"
        echo "2. Edit .env.example to use different ports"
    fi
done
```

## Success Criteria

After running this skill, the user should have:
- ✅ All services running (openclaw, cost-tracker, skill-scanner, etc.)
- ✅ Dashboard accessible at http://localhost:8080
- ✅ Cost tracker showing $0.00 / configured limits
- ✅ Skill scanner ready to scan
- ✅ Clear next steps for their use case (NanoClaw or OpenClaw)

## Customization Examples

After initial setup, users can ask Claude to customize:

```
"Increase session budget to $10"
"Change security profile to airgapped"
"Add Docker Desktop installation if missing"
"Lower rate limit to 20 calls per minute"
"Add automatic skill scanning on file change"
```

## Related Skills

- `/test-nanoclaw-skill` - Test a specific NanoClaw skill
- `/test-openclaw-agent` - Test OpenClaw agent workflow
- `/estimate-costs` - Estimate monthly costs for a skill
- `/scan-skill` - Scan a skill for malware patterns
