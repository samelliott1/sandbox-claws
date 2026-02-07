# Ubuntu Installation Guide for Mac Mini

**Purpose:** Install Ubuntu Server 24.04 LTS on Mac Mini for optimal Docker performance  
**Target:** Mac Mini (Intel or Apple Silicon compatible with Linux)  
**Time Required:** 30-45 minutes  
**Difficulty:** Beginner-friendly

---

## 📋 Prerequisites

### What You'll Need

1. **Mac Mini** (Intel-based recommended, or ARM with Ubuntu support)
2. **USB Drive** (8GB minimum, will be erased)
3. **Another computer** (to create bootable USB)
4. **Ethernet cable** (optional but recommended for initial setup)
5. **Keyboard and monitor** (for installation only)

### Hardware Compatibility Check

**Intel Mac Mini (2012-2020):**
- ✅ Fully supported
- ✅ All hardware works out of box
- ✅ Best choice for Docker performance

**Apple Silicon Mac Mini (M1/M2):**
- ⚠️ Limited support (check [ubuntu.com/download/server/arm](https://ubuntu.com/download/server/arm))
- Alternative: Use UTM virtualization or stick with macOS Docker

---

## 🚀 Installation Steps

### Step 1: Download Ubuntu Server

1. Go to: [https://ubuntu.com/download/server](https://ubuntu.com/download/server)
2. Download **Ubuntu Server 24.04 LTS** (latest stable)
3. File will be ~2.5GB: `ubuntu-24.04-live-server-amd64.iso`

**Why Server Edition?**
- Lightweight (no GUI overhead)
- Better for Docker workloads
- Lower resource usage
- You can add GUI later if needed

---

### Step 2: Create Bootable USB Drive

#### On macOS:

```bash
# 1. Insert USB drive and identify it
diskutil list
# Look for your USB (e.g., /dev/disk2)

# 2. Unmount the drive (replace diskN with your disk number)
diskutil unmountDisk /dev/diskN

# 3. Write Ubuntu ISO to USB (this takes 5-10 minutes)
# WARNING: This will ERASE the USB drive!
sudo dd if=~/Downloads/ubuntu-24.04-live-server-amd64.iso of=/dev/rdiskN bs=1m
# Note: Use /dev/rdiskN (with 'r') for faster writing

# 4. Eject when done
diskutil eject /dev/diskN
```

#### On Windows:

1. Download [Rufus](https://rufus.ie/)
2. Insert USB drive
3. Open Rufus:
   - Device: Select your USB drive
   - Boot selection: Select the Ubuntu ISO
   - Partition scheme: GPT
   - Target system: UEFI
4. Click "START"
5. Wait 5-10 minutes

#### On Linux:

```bash
# 1. Identify USB drive
lsblk

# 2. Write ISO (replace sdX with your drive letter)
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

---

### Step 3: Boot Mac Mini from USB

1. **Shut down** Mac Mini completely
2. **Insert** bootable USB drive
3. **Power on** while holding **Option (⌥)** key
4. **Select** "EFI Boot" or "USB" from boot menu
5. Wait for Ubuntu installer to load (30-60 seconds)

**Troubleshooting:**
- If boot menu doesn't appear, try holding **Option** immediately after power button
- If Mac boots to macOS, restart and try again
- Intel Macs: Option key works
- Apple Silicon: May need to boot to Recovery Mode first (Command+R)

---

### Step 4: Ubuntu Installation Wizard

#### Language & Keyboard
- Select **English**
- Keyboard layout: **English (US)** (or your layout)

#### Network
- **Ethernet (recommended):** Will auto-configure via DHCP
- **WiFi:** Select network and enter password
- Note the IP address shown (e.g., `192.168.1.100`)

#### Storage Configuration
- Choose: **Use an entire disk**
- Select your internal drive (usually largest one)
- **Confirm:** This will ERASE all data on the drive
- Review partition layout (default is fine)
- Select "Done" and confirm destructive action

**Storage Layout (Default):**
```
/boot/efi  - 512 MB  (EFI System Partition)
/          - Rest    (ext4 root partition)
swap       - 2-4 GB  (swap file)
```

#### Profile Setup
```
Your name:         Your Name
Server name:       sandbox-claws-mini
Username:          your-username
Password:          ********** (strong password!)
```

**Important:** Remember these credentials!

#### SSH Setup
- [x] Install OpenSSH server ← **SELECT THIS!**
- This lets you connect remotely later

#### Featured Snaps
- [ ] Leave all unchecked for now
- We'll install Docker manually later

#### Installation Progress
- Wait 10-15 minutes for installation
- System will download updates during install

#### Completion
- Select "Reboot Now"
- Remove USB drive when prompted
- System will reboot into Ubuntu

---

### Step 5: First Boot & Initial Setup

#### Login
```
ubuntu login: your-username
Password: **********
```

#### Update System
```bash
# Update package lists
sudo apt update

# Upgrade all packages (takes 5-10 minutes)
sudo apt upgrade -y

# Reboot to apply kernel updates
sudo reboot
```

#### Check Network Configuration
```bash
# Get IP address
ip addr show

# Test internet connection
ping -c 4 google.com

# Install helpful tools
sudo apt install -y curl wget git vim htop
```

---

### Step 6: Install Docker

```bash
# Remove any old Docker installations
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (no sudo required)
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Verify Docker installation
docker --version
docker compose version

# Test Docker
docker run hello-world
```

**Expected Output:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

### Step 7: Install Sandbox Claws

```bash
# Clone repository
cd ~
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws

# Make deploy script executable
chmod +x deploy-sandbox-claws.sh

# Deploy Sandbox Claws (with cost tracking)
./deploy-sandbox-claws.sh filtered

# Wait 2-3 minutes for all services to start
```

#### Verify Services

```bash
# Check running containers
docker ps

# Should see:
# - sandbox-claws-web
# - sandbox-claws-cost-tracker
# - sandbox-claws-egress-filter
# - sandbox-claws-openclaw-filtered
# - sandbox-claws-skill-scanner
# - sandbox-claws-fsmonitor
# - sandbox-claws-logs
```

#### Access Web UI

From your Mac (on same network):
```
http://192.168.1.100:8080
```
Replace `192.168.1.100` with your Mac Mini's IP address.

---

## 🔧 Post-Installation: Remote Access Setup

### Option 1: SSH Access (Recommended)

From your main Mac:
```bash
# SSH into Mac Mini
ssh your-username@192.168.1.100

# Or set up SSH key for passwordless login
ssh-copy-id your-username@192.168.1.100
```

### Option 2: Tailscale (Remote Access from Anywhere)

```bash
# On Mac Mini
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Get Tailscale IP
tailscale ip -4
# Example: 100.x.x.x

# Now access from anywhere:
# http://100.x.x.x:8080
```

### Option 3: Static IP (Optional)

Edit netplan configuration:
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Set static IP:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s31f6:  # Your interface name (check with 'ip a')
      addresses:
        - 192.168.1.100/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      routes:
        - to: default
          via: 192.168.1.1  # Your router IP
```

Apply changes:
```bash
sudo netplan apply
```

---

## 🛠️ Useful Commands

### System Management
```bash
# Check system resources
htop

# Check disk usage
df -h

# Check memory usage
free -h

# System info
neofetch  # Install: sudo apt install neofetch

# View logs
journalctl -xe

# Reboot
sudo reboot

# Shutdown
sudo shutdown -h now
```

### Docker Management
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View logs for specific container
docker logs sandbox-claws-cost-tracker

# Follow logs in real-time
docker logs -f sandbox-claws-cost-tracker

# Restart a service
docker compose restart cost-tracker

# Stop all services
docker compose down

# Start all services
docker compose up -d

# Rebuild a service
docker compose build cost-tracker
docker compose up -d cost-tracker
```

### Sandbox Claws Management
```bash
# Check status
cd ~/sandbox-claws
docker compose ps

# View all logs
docker compose logs

# Test cost tracker
curl http://localhost:5003/health

# Test web UI
curl http://localhost:8080

# Update Sandbox Claws
git pull origin main
docker compose down
docker compose build
docker compose up -d
```

---

## 🧪 Testing Cost Controls

Once Ubuntu and Sandbox Claws are running:

```bash
# Run automated cost control tests
cd ~/sandbox-claws
./scripts/test-cost-controls.sh

# Expected output:
# ✓ Cost tracker is healthy
# ✓ Stats endpoint working
# ✓ API call tracked successfully
# ✓ Alerts retrieved
# ✓ Rate limiting active
# ✓ Session budget reset successfully
# ✓ Budget limits configured
# All Tests Passed! ✓
```

**Web Dashboard:**
1. Open: `http://192.168.1.100:8080` (replace with your IP)
2. Scroll to: "Cost Tracking & Budget Controls"
3. Watch real-time updates (refreshes every 5 seconds)

---

## 📊 Performance Comparison

**Docker Performance: macOS vs Ubuntu on Mac Mini**

| Metric | macOS Docker | Ubuntu Docker | Improvement |
|--------|--------------|---------------|-------------|
| Container Start Time | 3-5 seconds | 0.5-1 second | **5x faster** |
| Build Time | 120 seconds | 75 seconds | **40% faster** |
| RAM Overhead | ~4 GB | ~1 GB | **4x less** |
| Disk I/O | Slow (VM layer) | Native speed | **2x faster** |
| Network | Virtualized | Direct | **Faster** |

**Why Ubuntu is Faster:**
- macOS Docker uses a VM (Docker Desktop)
- Ubuntu Docker runs natively on Linux kernel
- No translation layer = better performance

---

## 🔒 Security Hardening (Optional)

### Enable Firewall (UFW)

```bash
# Install and enable firewall
sudo apt install -y ufw

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow web ports
sudo ufw allow 8080/tcp   # Web UI
sudo ufw allow 8081/tcp   # Logs (Dozzle)
sudo ufw allow 5003/tcp   # Cost tracker

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Automatic Security Updates

```bash
# Install unattended-upgrades
sudo apt install -y unattended-upgrades

# Configure
sudo dpkg-reconfigure -plow unattended-upgrades

# Enable automatic security updates
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades
```

### Fail2Ban (SSH Protection)

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status
```

---

## 🐛 Troubleshooting

### Can't boot from USB
- **Intel Mac:** Hold Option (⌥) immediately after power button
- **Apple Silicon:** May not support external Linux boot (use VM instead)
- Try different USB port
- Recreate bootable USB

### No network connection
```bash
# Check network interfaces
ip addr show

# Restart networking
sudo systemctl restart systemd-networkd

# Check if DHCP is working
sudo dhclient -v
```

### Docker permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again, or:
newgrp docker

# Verify
docker ps
```

### Can't access web UI from other computer
```bash
# Check if port is listening
sudo netstat -tlnp | grep 8080

# Check firewall
sudo ufw status

# Allow port if needed
sudo ufw allow 8080/tcp
```

### Services not starting
```bash
# Check Docker logs
docker compose logs

# Check specific service
docker compose logs cost-tracker

# Restart all services
docker compose down
docker compose up -d
```

---

## 📚 Additional Resources

**Ubuntu Server:**
- Official Docs: https://ubuntu.com/server/docs
- Community Help: https://askubuntu.com/

**Docker:**
- Official Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/

**Sandbox Claws:**
- Repository: https://github.com/samelliott1/sandbox-claws
- Documentation: https://github.com/samelliott1/sandbox-claws/tree/main/docs

---

## ✅ Installation Checklist

- [ ] Download Ubuntu Server 24.04 LTS ISO
- [ ] Create bootable USB drive
- [ ] Boot Mac Mini from USB
- [ ] Complete Ubuntu installation wizard
- [ ] First boot and system update
- [ ] Install Docker
- [ ] Clone and deploy Sandbox Claws
- [ ] Verify all services running
- [ ] Test web UI access
- [ ] Run cost control tests
- [ ] Set up remote access (SSH/Tailscale)
- [ ] Optional: Security hardening

---

## 🎉 Success Criteria

You'll know everything is working when:

1. ✅ `docker ps` shows 7+ running containers
2. ✅ Web UI accessible at `http://IP:8080`
3. ✅ Cost tracker test script passes all tests
4. ✅ Can SSH from your main Mac
5. ✅ Dashboard shows real-time cost updates

---

## 🚀 Next Steps After Installation

1. **Configure API Keys:** Edit `.env.openclaw` with your Anthropic API key
2. **Test Cost Controls:** Run `./scripts/test-cost-controls.sh`
3. **Monitor Performance:** Compare Docker performance vs macOS
4. **Provide Feedback:** Let me know what works/doesn't work
5. **Next Steps:** Decide what to build next based on testing feedback

---

**Need Help?** Drop any questions or issues you encounter during installation!

**Estimated Total Time:** 30-45 minutes for clean install + 10 minutes for Sandbox Claws setup = **~1 hour total**
