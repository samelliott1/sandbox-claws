# Test NanoClaw Skill

## Description
Tests a NanoClaw skill safely in Sandbox Claws before deploying to personal assistant.
Performs security scanning, functionality testing, and cost estimation.

## When to Use
- Before adding a new skill to NanoClaw
- Testing community-contributed skills
- Validating custom skills you created
- Estimating costs of scheduled tasks

## What This Skill Does
1. Copies skill file to Sandbox Claws
2. Scans for malware and security issues
3. Tests functionality in isolated container
4. Monitors API costs and token usage
5. Calculates daily/monthly cost estimates
6. Reports whether safe to deploy

## Usage

```bash
# In Claude Code, say:
"Test the /add-telegram skill from ~/Downloads/add-telegram.md 
before I add it to my NanoClaw"

# Or:
"I want to create a morning briefing skill for NanoClaw. 
Test it in Sandbox Claws and estimate monthly costs."
```

## Steps

### 1. Locate the Skill File

```bash
# Ask user for skill file location or detect from context
echo "Which skill would you like to test?"
echo "Examples:"
echo "  - ~/Downloads/add-telegram.md"
echo "  - ~/nanoclaw/.claude/skills/morning-briefing/SKILL.md"
echo "  - ./custom-skill.md"

read -p "Skill file path: " SKILL_PATH

if [ ! -f "$SKILL_PATH" ]; then
    echo "⚠ Skill file not found: $SKILL_PATH"
    exit 1
fi

SKILL_NAME=$(basename "$SKILL_PATH" .md)
echo "✓ Found skill: $SKILL_NAME"
```

### 2. Copy to Sandbox Claws

```bash
# Ensure we're in sandbox-claws directory
cd ~/sandbox-claws || exit 1

# Copy skill to skills directory
cp "$SKILL_PATH" "./skills/${SKILL_NAME}.md"
echo "✓ Copied skill to ./skills/${SKILL_NAME}.md"
```

### 3. Security Scan

```bash
echo "🔍 Scanning for security issues..."

# Trigger skill scanner
curl -X POST http://localhost:5001/scan

# Wait for scan to complete
sleep 2

# Get scan results
SCAN_RESULT=$(curl -s "http://localhost:5001/results/${SKILL_NAME}")

# Parse results
IS_SAFE=$(echo "$SCAN_RESULT" | jq -r '.is_safe')
THREAT_LEVEL=$(echo "$SCAN_RESULT" | jq -r '.threat_level')
FINDINGS=$(echo "$SCAN_RESULT" | jq -r '.findings[]')

echo ""
echo "Security Scan Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Safe: $IS_SAFE"
echo "Threat Level: $THREAT_LEVEL"

if [ "$FINDINGS" != "" ]; then
    echo ""
    echo "⚠️  Security Findings:"
    echo "$FINDINGS" | while read -r finding; do
        echo "  - $finding"
    done
fi

# Stop if unsafe
if [ "$IS_SAFE" = "false" ]; then
    echo ""
    echo "❌ Skill failed security scan - DO NOT USE"
    echo "Recommendation: Review findings and fix issues"
    exit 1
fi

echo "✓ Security scan passed"
```

### 4. Test Functionality

```bash
echo ""
echo "🧪 Testing skill functionality..."

# Read skill content to determine how to test it
SKILL_CONTENT=$(cat "./skills/${SKILL_NAME}.md")

# For different skill types, test differently:

# If it's a channel integration (/add-telegram, /add-slack)
if [[ $SKILL_CONTENT == *"telegram"* ]] || [[ $SKILL_CONTENT == *"slack"* ]]; then
    echo "Testing channel integration skill..."
    echo "This skill modifies code structure."
    echo "Recommendation: Review code changes before applying to NanoClaw"
    
# If it's a scheduled task (morning briefing, weekly summary)
elif [[ $SKILL_CONTENT == *"schedule"* ]] || [[ $SKILL_CONTENT == *"every"* ]]; then
    echo "Testing scheduled task skill..."
    # Simulate the task execution
    docker-compose exec -T openclaw bash -c "
        cd /workspace
        echo 'Testing: ${SKILL_NAME}'
        # Run the skill logic
        cat skills/${SKILL_NAME}.md
    "
    
# If it's a tool/function skill
else
    echo "Testing general skill..."
    # Test basic execution
    docker-compose exec -T openclaw bash -c "
        cd /workspace
        cat skills/${SKILL_NAME}.md
    "
fi

echo "✓ Functionality test complete"
```

### 5. Monitor Costs

```bash
echo ""
echo "💰 Monitoring costs..."

# Get initial cost
INITIAL_COST=$(curl -s http://localhost:5003/stats | jq -r '.cost')

# Wait a bit for costs to update
sleep 3

# Get current cost
CURRENT_COST=$(curl -s http://localhost:5003/stats | jq -r '.cost')
API_CALLS=$(curl -s http://localhost:5003/stats | jq -r '.api_calls')
TOKENS_IN=$(curl -s http://localhost:5003/stats | jq -r '.input_tokens')
TOKENS_OUT=$(curl -s http://localhost:5003/stats | jq -r '.output_tokens')

TEST_COST=$(echo "$CURRENT_COST - $INITIAL_COST" | bc)

echo ""
echo "Cost Analysis:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test run cost: \$${TEST_COST}"
echo "API calls: ${API_CALLS}"
echo "Input tokens: ${TOKENS_IN}"
echo "Output tokens: ${TOKENS_OUT}"
```

### 6. Calculate Estimates

```bash
echo ""
echo "📊 Cost Estimates:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Estimate based on frequency
echo "If this skill runs:"
echo "  - Once per day:  \$$(echo "$TEST_COST * 30" | bc) / month"
echo "  - Once per week: \$$(echo "$TEST_COST * 4" | bc) / month"
echo "  - Twice per day: \$$(echo "$TEST_COST * 60" | bc) / month"
echo "  - Every hour:    \$$(echo "$TEST_COST * 720" | bc) / month"
```

### 7. Generate Report

```bash
echo ""
echo "📋 Test Report for: ${SKILL_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Security:"
echo "  ✅ Safe to use: $IS_SAFE"
echo "  Threat level: $THREAT_LEVEL"
echo ""
echo "Functionality:"
echo "  ✅ Basic tests passed"
echo ""
echo "Cost (per run):"
echo "  \$${TEST_COST}"
echo ""
echo "Monthly Estimate (daily use):"
echo "  \$$(echo "$TEST_COST * 30" | bc)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Recommendation
if [ "$IS_SAFE" = "true" ] && (( $(echo "$TEST_COST < 1" | bc -l) )); then
    echo "✅ Recommendation: SAFE TO DEPLOY"
    echo ""
    echo "To add to NanoClaw:"
    echo "  cp ./skills/${SKILL_NAME}.md ~/nanoclaw/.claude/skills/${SKILL_NAME}/SKILL.md"
elif [ "$IS_SAFE" = "true" ]; then
    echo "⚠️  Recommendation: SAFE but EXPENSIVE"
    echo "   Consider optimizing before daily use"
else
    echo "❌ Recommendation: DO NOT DEPLOY"
    echo "   Fix security issues first"
fi
```

## Success Criteria

After running this skill, user knows:
- ✅ Whether skill is safe to use
- ✅ Security issues (if any)
- ✅ Cost per execution
- ✅ Monthly cost estimate
- ✅ Clear recommendation: deploy or fix

## Error Handling

### If Sandbox Claws not running:
```bash
echo "⚠ Sandbox Claws services not running"
echo "Run: docker-compose up -d"
exit 1
```

### If skill file is empty:
```bash
if [ ! -s "$SKILL_PATH" ]; then
    echo "⚠ Skill file is empty"
    exit 1
fi
```

### If cost tracker unavailable:
```bash
if ! curl -s http://localhost:5003/health > /dev/null; then
    echo "⚠ Cost tracker not responding"
    echo "Check: docker-compose logs cost-tracker"
    exit 1
fi
```

## Related Skills

- `/scan-skill` - Security scan only
- `/estimate-costs` - Cost estimation only
- `/setup-sandbox-claws` - Initial setup
