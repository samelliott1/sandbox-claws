# 🚀 Sandbox Claws - Super Quick Start

Get up and running in **5 minutes** with just 3 steps!

---

## ⚡ Prerequisites

- **Docker installed** (script can install it for you)
- **Anthropic API key** (Get one at: https://console.anthropic.com/)
  - Cost: ~$5-20 to start (pay-as-you-go)
  - Takes 2 minutes to set up

---

## 📋 Three-Step Setup

### Step 1: Clone & Deploy (2 minutes)

```bash
# Clone the repository
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws

# Make deploy script executable
chmod +x deploy.sh

# Deploy everything (installs Docker if needed)
./deploy.sh
```

**What happens:**
- ✅ Checks/installs Docker
- ✅ Builds containers (OpenClaw with Node.js)
- ✅ Starts web dashboard, logs viewer, and OpenClaw
- ✅ Creates config files

### Step 2: Add Your Anthropic API Key (1 minute)

```bash
# Edit the OpenClaw config
nano .env.openclaw

# Add this line (paste your actual key):
ANTHROPIC_API_KEY=sk-ant-your-actual-api-key-here

# Save and exit (Ctrl+X, Y, Enter)
```

**Where to get your API key:**
1. Go to: https://console.anthropic.com/settings/keys
2. Click "Create Key"
3. Copy the key (starts with `sk-ant-`)
4. Paste it in `.env.openclaw`

### Step 3: Restart & Test (1 minute)

```bash
# Restart OpenClaw to load the API key
docker-compose restart openclaw

# Check if it's running
docker ps | grep openclaw

# View logs to confirm it started
docker logs sandbox-claws-openclaw --tail 20
```

**Expected output:**
```
OpenClaw Agent Sandbox - Starting
OpenClaw is installed globally
Starting OpenClaw gateway...
Gateway listening on port 18789 ✅
```

---

## 🎉 You're Done!

### Access Your Dashboard
```bash
open http://localhost:8080
```

### Access Log Viewer
```bash
open http://localhost:8081
```

---

## 🧪 Quick Test

Test OpenClaw from command line:

```bash
# Enter the container
docker exec -it sandbox-claws-openclaw sh

# Inside container, run:
openclaw --version

# Test the gateway
curl http://localhost:18789/health
```

---

## 🔧 Common Issues & Quick Fixes

### Issue: "Container is restarting"
**Fix:**
```bash
# Check logs for errors
docker logs sandbox-claws-openclaw

# If you see Python errors, rebuild:
docker-compose down
docker-compose build openclaw --no-cache
docker-compose up -d
```

### Issue: "No module named openclaw"
**Solution:** You have old Python version - pull latest:
```bash
git pull origin main
docker-compose build openclaw --no-cache
docker-compose up -d
```

### Issue: OpenClaw won't respond
**Check:** Did you add the API key?
```bash
# Verify API key is set
docker exec -it sandbox-claws-openclaw env | grep ANTHROPIC

# If empty, go back to Step 2
```

---

## 📊 What's Running?

After setup, you have:

| Service | Port | Purpose |
|---------|------|---------|
| **Web Dashboard** | 8080 | Security monitoring & testing hub |
| **Log Viewer** | 8081 | Real-time container logs (Dozzle) |
| **OpenClaw Gateway** | 18789 | AI assistant control plane |

---

## 🎯 Next Steps (Optional)

### Want to test email/calendar features?

1. **Create a test Gmail account** (never use your real one!)
2. **Get Gmail API credentials** (see: `docs/TESTING_GUIDE.md`)
3. **Run the helper script:**
   ```bash
   ./scripts/get-gmail-token.sh
   ```
4. **Add credentials to `.env.openclaw`**
5. **Restart:** `docker-compose restart openclaw`

### Want to connect messaging apps?

See: `docs/TESTING_GUIDE.md` for WhatsApp, Telegram, Slack, Discord setup

---

## 🛑 Uninstall Everything

```bash
# One-command uninstall (interactive)
./uninstall.sh

# Optionally removes Docker too
```

---

## 💡 Key Commands Reference

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f openclaw

# Restart a service
docker-compose restart openclaw

# Stop everything
docker-compose down

# Update everything
git pull origin main
docker-compose build
docker-compose up -d
```

---

## 🔑 API Key Costs (Anthropic Claude)

Typical usage costs with Anthropic API:

| Usage | Cost |
|-------|------|
| **100 messages** | ~$0.50-2.00 |
| **Light testing (1 day)** | ~$1-5 |
| **Heavy testing (1 week)** | ~$10-30 |

💡 **Tip:** Start with $5-10 credit, monitor usage in Anthropic console.

---

## 📚 Full Documentation

- **Complete Setup:** `README.md`
- **Testing Guide:** `docs/TESTING_GUIDE.md`
- **Security Details:** `docs/SECURITY_DEPLOYMENT.md`
- **Docker Guide:** `docs/DOCKER.md`

---

## ❓ Getting Help

- **Check logs:** `docker-compose logs openclaw`
- **Run health check:** `docker exec sandbox-claws-openclaw openclaw doctor`
- **GitHub Issues:** https://github.com/samelliott1/sandbox-claws/issues

---

## ⚠️ Security Reminders

- ✅ Only use **test accounts** (Gmail, etc.)
- ✅ Never use **production credentials**
- ✅ Keep your **API keys secure**
- ✅ Monitor **costs** in Anthropic console
- ✅ Use **air-gapped mode** for sensitive data: `./deploy.sh airgapped`

---

**That's it! You're ready to test AI agents securely! 🎊**

Need help? Check the logs or open an issue on GitHub.
