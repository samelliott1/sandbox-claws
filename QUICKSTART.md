# Quick Start Guide

Get Agent Sandbox running in under 60 seconds.

## Prerequisites Check

```bash
# Check if Docker is installed
docker --version

# Check if Docker Compose is available
docker compose version
# OR
docker-compose --version
```

If Docker is not installed, see [Docker Installation](https://docs.docker.com/get-docker/).

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/agent-sandbox.git
cd agent-sandbox
```

### Step 2: Deploy

```bash
# Make script executable
chmod +x deploy.sh

# Run automated deployment
./deploy.sh
```

The script will:
- ✅ Detect your environment (Docker/Proxmox/Standalone)
- ✅ Set up configuration files
- ✅ Pull and build container images
- ✅ Start all services
- ✅ Display access information

### Step 3: Access Web UI

Open your browser to:
```
http://localhost:8080
```

You should see the Agent Sandbox testing hub!

## Initial Configuration

### Configure OpenClaw Credentials

The only thing you need to configure is your test Gmail account:

```bash
# Edit the OpenClaw environment file
nano .env.openclaw
```

Add your test account credentials:
```bash
GMAIL_CLIENT_ID=your_test_account_id
GMAIL_CLIENT_SECRET=your_test_account_secret
GMAIL_REFRESH_TOKEN=your_test_account_token

GOOGLE_CALENDAR_CLIENT_ID=your_test_account_id
GOOGLE_CALENDAR_CLIENT_SECRET=your_test_account_secret
GOOGLE_CALENDAR_REFRESH_TOKEN=your_test_account_token
```

### Restart OpenClaw

```bash
docker compose restart openclaw
```

## Verify Installation

### Check Services

```bash
# View running containers
docker compose ps
```

You should see:
- ✅ `agent-sandbox-web` - Running
- ✅ `agent-sandbox-openclaw` - Running
- ✅ `agent-sandbox-logs` - Running

### View Logs

```bash
# View all logs
docker compose logs

# Follow OpenClaw logs
docker compose logs -f openclaw

# View logs in browser
open http://localhost:8081
```

## Start Testing

1. **Open Web UI:** http://localhost:8080

2. **Complete Security Checklist:**
   - Check off VM isolation items
   - Verify account isolation
   - Confirm monitoring setup

3. **Run Your First Test:**
   - Navigate to Testing section
   - Click "Start Test" on any test case
   - OpenClaw will execute in isolated container

4. **Document Findings:**
   - Press `Ctrl/Cmd + K` to add findings
   - Categorize by severity
   - Add detailed descriptions

5. **Generate Report:**
   - Scroll to Executive Summary
   - Click "Generate Report"
   - Download Markdown file

## Common Commands

### Start Services
```bash
docker compose up -d
```

### Stop Services
```bash
docker compose stop
```

### Restart Services
```bash
docker compose restart
```

### View Logs
```bash
docker compose logs -f openclaw
```

### Shutdown Everything
```bash
docker compose down
```

### Update Containers
```bash
git pull
docker compose pull
docker compose build
docker compose up -d
```

## Troubleshooting

### Port Already in Use

If port 8080 is in use:

```bash
# Edit .env file
nano .env

# Change WEB_PORT
WEB_PORT=8090

# Restart
docker compose up -d
```

### Container Won't Start

```bash
# Check logs for errors
docker compose logs openclaw

# Rebuild container
docker compose build --no-cache openclaw
docker compose up -d
```

### Can't Access Web UI

```bash
# Check if containers are running
docker compose ps

# Check if port is accessible
curl http://localhost:8080

# Check firewall
sudo ufw status
```

## Optional Features

### Enable Network Monitoring

```bash
docker compose --profile monitoring up -d
```

Access at: http://localhost:3000

### Enable Remote Access (Cloudflare Tunnel)

1. Get tunnel token from https://one.dash.cloudflare.com/

2. Add to `.env`:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=your_token_here
   ```

3. Start with remote access profile:
   ```bash
   docker compose --profile remote-access up -d
   ```

### Enable Tailscale

```bash
# Install Tailscale on host
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to your network
sudo tailscale up

# Get your Tailscale IP
tailscale ip -4
```

Access via: `http://[tailscale-ip]:8080`

## Next Steps

1. **Configure test credentials** in `.env.openclaw`
2. **Read the documentation:**
   - [Docker Guide](docs/DOCKER.md)
   - [Proxmox Guide](docs/PROXMOX.md)
3. **Start testing OpenClaw** capabilities
4. **Document your findings** in the web UI
5. **Generate reports** for stakeholders

## Getting Help

- **Documentation:** Check `docs/` folder
- **Issues:** [GitHub Issues](https://github.com/yourusername/agent-sandbox/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/agent-sandbox/discussions)

## Security Reminders

⚠️ **Important:**
- Only use test accounts (never production credentials)
- Keep your test environment isolated
- Take snapshots before each test session
- Review logs regularly for suspicious activity
- Export findings frequently

---

**You're all set! Happy testing! 🚀**

For detailed information, see the [full README](README.md).
