# Deployment Notes

## File Permissions

If you encounter 403 Forbidden errors with the nginx dashboard, ensure proper file permissions:

```bash
chmod 644 index.html
chmod 644 css/style.css
chmod 644 js/main.js
```

## Environment Configuration

Copy `.env.openclaw.example` to `.env.openclaw` and configure your settings:

```bash
cp .env.openclaw.example .env.openclaw
# Edit .env.openclaw with your API keys and settings
```

## Docker Deployment

### Using deploy script (recommended):
```bash
./deploy-sandbox-claws.sh filtered
```

### Manual deployment:
```bash
# Start the web dashboard only
docker-compose up -d web

# Start with egress filtering
docker-compose --profile filtered up -d

# Start all services including OpenClaw agent
docker-compose --profile basic up -d
```

## Troubleshooting

### Port 8080 already in use
```bash
sudo lsof -ti:8080 | xargs -r sudo kill -9
docker-compose restart web
```

### Docker permission denied
```bash
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
```

### iptables nft protocol error
```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```
