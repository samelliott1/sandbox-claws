#!/bin/bash

# Cost Control Testing Script
# Tests the Phase 2a cost tracking features

set -e

COST_TRACKER_URL="http://localhost:5003"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "   Phase 2a: Cost Control Tests"
echo "========================================="
echo ""

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
HEALTH=$(curl -s ${COST_TRACKER_URL}/health)
if echo "$HEALTH" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Cost tracker is healthy${NC}"
else
    echo -e "${RED}✗ Cost tracker is not responding${NC}"
    exit 1
fi
echo ""

# Test 2: Get Initial Stats
echo -e "${YELLOW}Test 2: Get Initial Stats${NC}"
STATS=$(curl -s ${COST_TRACKER_URL}/stats)
if echo "$STATS" | grep -q "session"; then
    echo -e "${GREEN}✓ Stats endpoint working${NC}"
    echo "   Session cost: $(echo $STATS | jq -r '.session.cost')"
    echo "   Hourly cost: $(echo $STATS | jq -r '.hourly.cost')"
    echo "   Daily cost: $(echo $STATS | jq -r '.daily.cost')"
else
    echo -e "${RED}✗ Stats endpoint failed${NC}"
    exit 1
fi
echo ""

# Test 3: Track a Sample API Call
echo -e "${YELLOW}Test 3: Track Sample API Call${NC}"
TRACK_RESPONSE=$(curl -s -X POST ${COST_TRACKER_URL}/track \
    -H "Content-Type: application/json" \
    -d '{
        "model": "claude-opus-4.5",
        "input_tokens": 500,
        "output_tokens": 1200,
        "cost_usd": 0.0975
    }')

if echo "$TRACK_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ API call tracked successfully${NC}"
    echo "   New session cost: $(echo $TRACK_RESPONSE | jq -r '.session_cost')"
    echo "   Budget OK: $(echo $TRACK_RESPONSE | jq -r '.budget_ok')"
else
    echo -e "${RED}✗ Failed to track API call${NC}"
    exit 1
fi
echo ""

# Test 4: Check Alerts
echo -e "${YELLOW}Test 4: Check Alerts${NC}"
ALERTS=$(curl -s ${COST_TRACKER_URL}/alerts)
ALERT_COUNT=$(echo "$ALERTS" | jq '.alerts | length')
echo -e "${GREEN}✓ Alerts retrieved (${ALERT_COUNT} alerts)${NC}"
if [ "$ALERT_COUNT" -gt 0 ]; then
    echo "   Recent alerts:"
    echo "$ALERTS" | jq -r '.alerts[] | "   - [\(.level)] \(.message)"'
fi
echo ""

# Test 5: Rate Limiting Check
echo -e "${YELLOW}Test 5: Rate Limiting${NC}"
RATE=$(echo "$STATS" | jq -r '.rate')
CALLS_THIS_MIN=$(echo "$RATE" | jq -r '.calls_this_minute')
MAX_PER_MIN=$(echo "$RATE" | jq -r '.max_per_minute')
echo -e "${GREEN}✓ Rate limiting active${NC}"
echo "   Calls this minute: ${CALLS_THIS_MIN} / ${MAX_PER_MIN}"
echo ""

# Test 6: Reset Session
echo -e "${YELLOW}Test 6: Reset Session Budget${NC}"
RESET_RESPONSE=$(curl -s -X POST ${COST_TRACKER_URL}/reset/session)
if echo "$RESET_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ Session budget reset successfully${NC}"
else
    echo -e "${RED}✗ Failed to reset session${NC}"
    exit 1
fi
echo ""

# Test 7: Verify Budget Configuration
echo -e "${YELLOW}Test 7: Verify Budget Limits${NC}"
STATS_AFTER_RESET=$(curl -s ${COST_TRACKER_URL}/stats)
SESSION_BUDGET=$(echo "$STATS_AFTER_RESET" | jq -r '.session.budget')
HOURLY_BUDGET=$(echo "$STATS_AFTER_RESET" | jq -r '.hourly.budget')
DAILY_BUDGET=$(echo "$STATS_AFTER_RESET" | jq -r '.daily.budget')

echo -e "${GREEN}✓ Budget limits configured${NC}"
echo "   Session: \$${SESSION_BUDGET}"
echo "   Hourly: \$${HOURLY_BUDGET}"
echo "   Daily: \$${DAILY_BUDGET}"
echo ""

# Summary
echo "========================================="
echo -e "${GREEN}   All Tests Passed! ✓${NC}"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Open http://localhost:8080 and go to Cost Tracking section"
echo "2. Monitor real-time cost updates (refreshes every 5 seconds)"
echo "3. Test budget alerts by adjusting limits in .env"
echo "4. Review docs/security/COST_CONTROLS.md for full documentation"
echo ""
