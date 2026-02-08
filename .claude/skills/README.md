# Sandbox Claws Claude Code Skills

AI-native setup and testing workflows for Sandbox Claws using Claude Code.

## Available Skills

### 🚀 `/setup-sandbox-claws`
Automatically sets up Sandbox Claws with intelligent defaults.
- Detects existing API keys (NanoClaw, OpenClaw)
- Configures security profile and cost controls
- Deploys all services
- Reports dashboard URLs

**Usage:**
```
"Set up Sandbox Claws for testing NanoClaw skills"
"Configure Sandbox Claws with filtered profile and $5 session budget"
```

### 🧪 `/test-nanoclaw-skill`
Comprehensively tests a NanoClaw skill before deploying to personal assistant.
- Security scanning for malware
- Functionality testing in isolation
- Cost monitoring and estimation
- Clear deploy/don't-deploy recommendation

**Usage:**
```
"Test the /add-telegram skill before adding to NanoClaw"
"Test my morning-briefing.md skill and estimate monthly costs"
```

### 🔍 `/scan-skill`
Quick security scan of a skill file for malicious patterns.
- Credential access detection
- Data exfiltration patterns
- Destructive commands
- Obfuscation techniques
- Remote code execution

**Usage:**
```
"Scan community-skill.md for security issues"
"Check if this skill is safe to use"
```

### 💰 `/estimate-costs`
Estimate monthly costs for a skill based on frequency.
- Simulates execution
- Measures API costs and tokens
- Calculates daily/weekly/monthly estimates
- Provides optimization suggestions

**Usage:**
```
"Estimate monthly cost for daily morning briefing"
"How much will this skill cost per week?"
```

## Philosophy

These skills follow NanoClaw's "AI-native" approach:
- No installation wizards → Claude handles setup
- No configuration files → Claude applies settings
- No monitoring tools → Ask Claude what's happening
- No debugging commands → Describe issue, Claude fixes

## How It Works

1. **User talks to Claude Code** naturally
2. **Claude invokes appropriate skill** from `.claude/skills/`
3. **Skill executes setup/testing steps** automatically
4. **Claude reports results** with recommendations

## Installation

Already installed! These skills are included in the Sandbox Claws repository.

```bash
cd sandbox-claws
ls .claude/skills/
# setup-sandbox-claws/
# test-nanoclaw-skill/
# scan-skill/
# estimate-costs/
```

## Examples

### Example 1: Complete Setup from Scratch

```
User: "I want to test NanoClaw skills safely. 
       Set up Sandbox Claws for me."

Claude: "I'll set up Sandbox Claws with these steps:
         1. Clone repository
         2. Detect your NanoClaw API key
         3. Configure filtered security profile
         4. Set testing budget: $5/session, $20/hour, $50/day
         5. Deploy all services
         
         Starting now..."

[Claude executes /setup-sandbox-claws skill]

Claude: "✅ Setup complete!
         
         Dashboard: http://localhost:8080
         Cost tracker: http://localhost:8080/#costs
         
         Ready to test skills. What skill should we test first?"
```

### Example 2: Test Community Skill

```
User: "I downloaded a /add-notion skill from GitHub. 
       Test it before I add to NanoClaw."

Claude: "I'll test the add-notion skill:
         1. Security scan for malicious patterns
         2. Functionality test in isolation
         3. Cost estimation for typical use
         4. Recommendation
         
         Where is the skill file?"

User: "~/Downloads/add-notion.md"

[Claude executes /test-nanoclaw-skill]

Claude: "Test Results:
         
         Security: ✅ PASSED
         - No malicious patterns detected
         - No credential access attempts
         - No data exfiltration
         
         Cost: $0.35 per use
         Monthly (10 uses): ~$3.50
         
         ✅ Recommendation: SAFE TO DEPLOY
         
         To add to NanoClaw:
         cp ~/Downloads/add-notion.md ~/nanoclaw/.claude/skills/add-notion/SKILL.md"
```

### Example 3: Cost Estimation for Scheduled Task

```
User: "I want to add a daily morning briefing to NanoClaw.
       Estimate how much it will cost monthly."

Claude: "I'll estimate costs for a morning briefing:
         1. Create test skill
         2. Simulate execution
         3. Measure API usage
         4. Calculate monthly cost
         
         What should the briefing include?"

User: "HN top 10, AI news from TechCrunch, today's calendar"

[Claude creates test skill and executes /estimate-costs]

Claude: "Cost Estimate:
         
         Per briefing: $0.42
         Daily (30 days): $12.60/month
         
         Breakdown:
         - HN scraping: $0.15
         - TechCrunch search: $0.18
         - Calendar check: $0.05
         - Summary generation: $0.04
         
         ✅ Reasonable cost for daily use
         
         Create this skill in NanoClaw?"
```

## Customization

Users can ask Claude to customize after setup:

```
"Increase session budget to $10"
"Change to airgapped security profile"
"Lower rate limit to 20 calls per minute"
"Add automatic scanning when skills are copied"
```

Claude will modify the configuration or code as needed.

## Contributing New Skills

Want to add a new testing workflow? Create a skill:

1. Create directory: `.claude/skills/your-skill-name/`
2. Create `SKILL.md` with:
   - Description
   - When to use
   - Steps (bash commands)
   - Success criteria
   - Error handling
3. Submit PR

Example skills we'd love to see:
- `/test-openclaw-agent` - Test OpenClaw agent workflows
- `/benchmark-performance` - Compare skill performance
- `/debug-context-overflow` - Diagnose context issues
- `/optimize-costs` - Suggest cost optimizations

## Resources

- [NanoClaw Integration Guide](../docs/integrations/NANOCLAW_INTEGRATION.md)
- [OpenClaw Integration Guide](../docs/integrations/OPENCLAW_INTEGRATION.md)
- [Cost Controls Guide](../docs/security/COST_CONTROLS.md)
- [Claude Code Documentation](https://code.claude.com/docs)

---

**Happy AI-native testing! 🦞🔒**
