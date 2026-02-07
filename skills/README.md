# Skills Directory

Place OpenClaw skills here for scanning by the Skill Scanner service.

## Usage

1. **Download a skill** from ClawHub or elsewhere
2. **Place it in this directory** (e.g., `skills/my-skill.md`)
3. **Skill Scanner automatically scans it** for malicious patterns
4. **Check results** at http://localhost:5001/results

## Example

```bash
# Download a skill
curl -o skills/test-skill.md https://clawhub.com/skills/example-skill.md

# Check scan results
curl http://localhost:5001/results
```

## What Gets Scanned

The Skill Scanner looks for:

- **Credential access** (.ssh/, .aws/, .openclaw/config.json)
- **Data exfiltration** (pastebin, base64 encoding before upload)
- **Destructive commands** (rm -rf /, DROP DATABASE)
- **Obfuscation** (eval, exec, base64 decoding)
- **Remote fetching** (moltbook.com heartbeat.md)
- **Crypto mining** (xmrig, minergate)
- **Reverse shells** (bash -i >&  /dev/tcp/)

## API Endpoints

- `GET /health` - Health check
- `POST /scan` - Scan content directly
- `POST /scan-file` - Scan a file
- `GET /results` - Get all scan results
- `GET /results/<skill_name>` - Get result for specific skill
- `GET /stats` - Get scanner statistics

## Scan Result Example

```json
{
  "skill_name": "suspicious-skill.md",
  "safe": false,
  "blocked": true,
  "severity_score": 15,
  "findings_count": 3,
  "findings": [
    {
      "category": "credential_access",
      "severity": "CRITICAL",
      "description": "Accessing OpenClaw config file containing all API keys",
      "line": 42,
      "match": "cat ~/.openclaw/config.json"
    }
  ],
  "recommendation": "🚨 BLOCK - Critical security risk detected. DO NOT EXECUTE."
}
```

## Notes

- Skills are scanned automatically when added or modified
- Blocked skills (CRITICAL findings) should NEVER be executed
- All scan results are logged and available via API
