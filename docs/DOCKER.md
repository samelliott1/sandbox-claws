# Docker Deployment Guide

Complete guide for deploying Agent Sandbox using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+ (or docker-compose 1.29+)
- 2GB RAM minimum
- 10GB disk space

## Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/agent-sandbox.git
cd agent-sandbox

# Run automated deployment
chmod +x deploy.sh
./deploy.sh
```

That's it! The script handles everything.

## Manual Deployment

If you prefer manual control:

```bash
# 1. Copy environment files
cp .env.example .env
cp .env.openclaw.example .env.openclaw

# 2. Edit environment files with your credentials
nano .env.openclaw

# 3. Start services
docker compose up -d
```

## Architecture

```
┌─────────────────────────────────────────┐
│  agent-sandbox Network (172.28.0.0/16)  │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │   Web    │  │ OpenClaw │           │
│  │   UI     │  │  Agent   │           │
│  │  :8080   │  │          │           │
│  └──────────┘  └──────────┘           │
│                                         │
│  ┌──────────┐  ┌──────────┐           │
│  │   Logs   │  │ Network  │           │
│  │ (Dozzle) │  │ Monitor  │           │
│  │  :8081   │  │  :3000   │           │
│  └──────────┘  └──────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

## Services

### Web UI (Required)
- **Port:** 8080 (configurable via WEB_PORT)
- **Purpose:** Testing hub interface
- **Image:** nginx:alpine
- **Access:** http://localhost:8080

### OpenClaw Agent (Required)
- **Purpose:** The AI agent being tested
- **Image:** Custom built from Dockerfile
- **Security:** Non-root user, read-only filesystem, capability restrictions

### Logs - Dozzle (Required)
- **Port:** 8081 (configurable via LOG_PORT)
- **Purpose:** Real-time container log viewing
- **Image:** amir20/dozzle:latest
- **Access:** http://localhost:8081

### Network Monitor (Optional)
- **Port:** 3000 (configurable via MONITOR_PORT)
- **Purpose:** Network traffic analysis
- **Profile:** monitoring
- **Access:** http://localhost:3000

### Cloudflare Tunnel (Optional)
- **Purpose:** Secure remote access
- **Profile:** remote-access
- **Configuration:** Requires CLOUDFLARE_TUNNEL_TOKEN

## Configuration

### Environment Variables

#### `.env` - Main configuration
```bash
# Web UI port
WEB_PORT=8080

# Logs viewer port
LOG_PORT=8081

# Network monitor port
MONITOR_PORT=3000

# OpenClaw environment
OPENCLAW_ENV=sandbox
OPENCLAW_LOG_LEVEL=INFO

# Remote access (optional)
CLOUDFLARE_TUNNEL_TOKEN=your_token_here
```

#### `.env.openclaw` - Agent configuration
```bash
# Gmail API
GMAIL_CLIENT_ID=your_client_id
GMAIL_CLIENT_SECRET=your_client_secret
GMAIL_REFRESH_TOKEN=your_refresh_token

# Google Calendar API
GOOGLE_CALENDAR_CLIENT_ID=your_client_id
GOOGLE_CALENDAR_CLIENT_SECRET=your_client_secret
GOOGLE_CALENDAR_REFRESH_TOKEN=your_refresh_token

# Security
OPENCLAW_SANDBOX_MODE=true
OPENCLAW_RATE_LIMIT=10
```

## Docker Compose Profiles

### Default Profile
Starts: Web UI, OpenClaw Agent, Logs viewer
```bash
docker compose up -d
```

### With Network Monitoring
```bash
docker compose --profile monitoring up -d
```

### With Remote Access
```bash
# Set CLOUDFLARE_TUNNEL_TOKEN in .env first
docker compose --profile remote-access up -d
```

### All Services
```bash
docker compose --profile monitoring --profile remote-access up -d
```

## Security Features

### Container Hardening

1. **Non-root user:** OpenClaw runs as unprivileged user
2. **Read-only filesystem:** Prevents file system modifications
3. **Capability dropping:** Only essential capabilities retained
4. **No new privileges:** Prevents privilege escalation
5. **Resource limits:** CPU/memory constraints (via Docker settings)
6. **Network isolation:** Dedicated bridge network

### Network Security

```bash
# Isolated bridge network
network:
  driver: bridge
  ipam:
    config:
      - subnet: 172.28.0.0/16
```

### Recommended Docker Daemon Settings

Add to `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "userland-proxy": false,
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

## Management Commands

### View Status
```bash
docker compose ps
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f openclaw

# Last 100 lines
docker compose logs --tail=100 openclaw
```

### Stop Services
```bash
# Stop all
docker compose stop

# Stop specific service
docker compose stop openclaw
```

### Restart Services
```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart openclaw
```

### Shutdown Everything
```bash
docker compose down
```

### Shutdown and Remove Volumes
```bash
docker compose down -v
```

## Persistence

### Data Volumes

- **openclaw-data:** Agent data storage
- **openclaw-logs:** Log files

### Backup Volumes

```bash
# Backup volume
docker run --rm -v agent-sandbox_openclaw-data:/data \
  -v $(pwd)/backup:/backup \
  ubuntu tar czf /backup/openclaw-data-$(date +%Y%m%d).tar.gz -C /data .

# Restore volume
docker run --rm -v agent-sandbox_openclaw-data:/data \
  -v $(pwd)/backup:/backup \
  ubuntu tar xzf /backup/openclaw-data-YYYYMMDD.tar.gz -C /data
```

### Export Configuration

```bash
# Backup all configs
tar czf agent-sandbox-config-$(date +%Y%m%d).tar.gz \
  .env .env.openclaw docker-compose.yml
```

## Snapshots

### Using Docker Commit

```bash
# Take snapshot before testing
docker commit agent-sandbox-openclaw agent-sandbox-openclaw:snapshot-$(date +%Y%m%d-%H%M%S)

# Rollback to snapshot
docker compose stop openclaw
docker tag agent-sandbox-openclaw:snapshot-YYYYMMDD-HHMMSS agent-sandbox-openclaw:latest
docker compose up -d openclaw
```

## Monitoring

### Resource Usage

```bash
# Real-time stats
docker stats

# Specific container
docker stats agent-sandbox-openclaw
```

### Health Checks

```bash
# Check container health
docker inspect agent-sandbox-openclaw | grep -A 10 Health
```

### Disk Usage

```bash
# Check disk usage
docker system df

# Detailed view
docker system df -v
```

## Remote Access

### Via Cloudflare Tunnel

1. Get tunnel token from https://one.dash.cloudflare.com/
2. Add to `.env`:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=your_token_here
   ```
3. Start with profile:
   ```bash
   docker compose --profile remote-access up -d
   ```

### Via Tailscale

```bash
# Install Tailscale on host
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to your tailnet
sudo tailscale up

# Access via Tailscale IP
echo "Access at: http://$(tailscale ip -4):8080"
```

### Via SSH Tunnel

```bash
# From remote machine
ssh -L 8080:localhost:8080 user@your-server
```

## Troubleshooting

### Containers Won't Start

```bash
# Check logs
docker compose logs

# Rebuild images
docker compose build --no-cache

# Remove and recreate
docker compose down
docker compose up -d
```

### Port Conflicts

```bash
# Check what's using the port
sudo lsof -i :8080

# Change port in .env
WEB_PORT=8090
```

### Permission Issues

```bash
# Fix file permissions
chmod +x deploy.sh
chmod 644 .env*
```

### Network Issues

```bash
# Recreate network
docker compose down
docker network prune
docker compose up -d
```

### Out of Disk Space

```bash
# Clean up
docker system prune -a --volumes

# Remove old images
docker image prune -a
```

## Performance Tuning

### Resource Limits

Add to `docker-compose.yml` under OpenClaw service:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '1'
      memory: 1G
```

### Build Cache

```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker compose build
```

## Updates

### Update Images

```bash
# Pull latest images
docker compose pull

# Rebuild custom images
docker compose build --pull

# Restart with new images
docker compose up -d
```

### Update Code

```bash
# Pull latest code
git pull origin main

# Rebuild
docker compose build

# Restart
docker compose up -d
```

## Production Considerations

1. **Use specific image tags** instead of `latest`
2. **Set resource limits** for all containers
3. **Enable log rotation** in Docker daemon
4. **Regular backups** of volumes and configs
5. **Monitor container health** with healthchecks
6. **Use secrets management** for sensitive data
7. **Enable TLS** for remote access
8. **Implement rate limiting** at reverse proxy

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
