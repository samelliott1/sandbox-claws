# Proxmox Deployment Guide

This guide covers deploying Agent Sandbox on Proxmox VE using LXC containers for optimal isolation and resource efficiency.

## Why Proxmox?

Proxmox VE provides:
- **Native containerization** with LXC
- **Resource limits** and quotas
- **Snapshot capabilities** for testing
- **Network isolation** built-in
- **Web-based management**
- **Enterprise-grade** security

## Quick Start

### Option 1: Automated LXC Creation

```bash
# On Proxmox host
curl -fsSL https://raw.githubusercontent.com/yourusername/agent-sandbox/main/scripts/proxmox-setup.sh | bash
```

### Option 2: Manual LXC Setup

1. **Create LXC Container**
   ```bash
   pct create 100 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
     --hostname agent-sandbox \
     --memory 2048 \
     --cores 2 \
     --rootfs local-lxc:8 \
     --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp \
     --unprivileged 1 \
     --features nesting=1
   ```

2. **Start Container**
   ```bash
   pct start 100
   ```

3. **Enter Container**
   ```bash
   pct enter 100
   ```

4. **Run Deployment Script**
   ```bash
   # Inside container
   apt update && apt install -y curl git
   git clone https://github.com/yourusername/agent-sandbox.git
   cd agent-sandbox
   chmod +x deploy.sh
   ./deploy.sh
   ```

## LXC Configuration

### Recommended Settings

```conf
# /etc/pve/lxc/100.conf
arch: amd64
cores: 2
hostname: agent-sandbox
memory: 2048
net0: name=eth0,bridge=vmbr0,firewall=1,ip=dhcp
rootfs: local-lxc:vm-100-disk-0,size=8G
swap: 512
unprivileged: 1

# Enable Docker inside LXC (if using Docker deployment)
features: nesting=1,keyctl=1

# CPU limit (optional)
cpulimit: 2

# I/O priority (optional)
ionice: 2
```

### Security Hardening

```conf
# Additional security options
features: nesting=1,keyctl=1

# Resource limits
lxc.cgroup2.memory.max: 2147483648
lxc.cgroup2.cpu.max: 200000 100000

# AppArmor profile
lxc.apparmor.profile: generated
```

## Network Configuration

### Isolated Network (Recommended)

Create a dedicated bridge for the agent sandbox:

```bash
# On Proxmox host
cat >> /etc/network/interfaces <<EOF

auto vmbr1
iface vmbr1 inet static
    address 10.10.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    # NAT for outbound only
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE
EOF

# Apply network configuration
ifreload -a
```

### Firewall Rules

```bash
# On Proxmox host - Create firewall rules
cat > /etc/pve/firewall/100.fw <<EOF
[OPTIONS]
enable: 1

[RULES]
# Allow outbound web traffic
OUT ACCEPT -p tcp -dport 80
OUT ACCEPT -p tcp -dport 443

# Allow DNS
OUT ACCEPT -p udp -dport 53

# Block everything else by default
OUT DROP

# Allow access from management network
IN ACCEPT -p tcp -dport 8080 -source 192.168.1.0/24
IN ACCEPT -p tcp -dport 8081 -source 192.168.1.0/24
EOF
```

## Storage Configuration

### Dedicated Storage Pool

```bash
# Create dedicated directory for agent sandbox
mkdir -p /var/lib/vz/agent-sandbox

# Set up storage in Proxmox
pvesm add dir agent-sandbox --path /var/lib/vz/agent-sandbox --content vztmpl,iso,backup
```

## Snapshots and Backups

### Create Pre-Test Snapshot

```bash
# Before each test session
pct snapshot 100 before-test-$(date +%Y%m%d-%H%M%S)
```

### Rollback to Snapshot

```bash
# List snapshots
pct listsnapshot 100

# Rollback
pct rollback 100 before-test-20260201-100000
```

### Automated Backup

```bash
# Setup vzdump backup
vzdump 100 --storage local --mode snapshot --compress zstd
```

## Monitoring

### Resource Usage

```bash
# CPU and Memory usage
pct exec 100 -- top

# Detailed stats
pct status 100 --verbose
```

### Logs

```bash
# Container logs
pct exec 100 -- journalctl -f

# Proxmox logs
tail -f /var/log/pve/tasks/active
```

## Docker Inside LXC

If using Docker deployment method inside LXC:

```bash
# Enable nesting in container config
pct set 100 -features nesting=1,keyctl=1

# Inside container, install Docker
apt update
apt install -y docker.io docker-compose
systemctl enable --now docker
```

## Remote Access

### Via Proxmox Web Interface

Access through Proxmox web UI:
- Navigate to container
- Use built-in console
- Port forwarding automatically handled

### Via SSH

```bash
# Get container IP
pct exec 100 -- ip a

# SSH into container
ssh root@<container-ip>
```

### Via Cloudflare Tunnel

Inside the container:
```bash
# Follow main deployment script
./deploy.sh
# Select Cloudflare Tunnel option
```

## Migration

### Export Container

```bash
# Stop container
pct stop 100

# Create backup
vzdump 100 --storage local --mode stop

# Backup location
ls /var/lib/vz/dump/
```

### Import on Another Host

```bash
# Copy backup to new host
scp /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst new-host:/var/lib/vz/dump/

# Restore on new host
pct restore 101 /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst
```

## Troubleshooting

### Container Won't Start

```bash
# Check configuration
pct config 100

# Check logs
journalctl -xe

# Validate config
pct validate 100
```

### Docker Issues Inside LXC

```bash
# Ensure nesting is enabled
pct set 100 -features nesting=1,keyctl=1

# Restart container
pct stop 100 && pct start 100
```

### Network Issues

```bash
# Check bridge status
brctl show

# Verify firewall rules
iptables -L -n -v

# Test connectivity from container
pct exec 100 -- ping -c 4 8.8.8.8
```

## Best Practices

1. **Always snapshot before testing** - Easy rollback
2. **Use unprivileged containers** - Better security
3. **Enable firewall** - Control network access
4. **Set resource limits** - Prevent resource exhaustion
5. **Regular backups** - Protect your configuration
6. **Isolated network** - Dedicated bridge for sandbox
7. **Monitor logs** - Track agent behavior
8. **Document findings** - Use the web UI

## Performance Tuning

### CPU Pinning

```bash
# Pin to specific CPU cores
pct set 100 -cores 2 -cpulimit 2 -cpuunits 1024
```

### I/O Priority

```bash
# Set I/O priority
pct set 100 -ionice 3
```

### Memory Ballooning

```bash
# Enable memory ballooning
pct set 100 -balloon 1024
```

## Security Considerations

- Run containers as **unprivileged** (uid mapping)
- Use **AppArmor profiles** for additional isolation
- Implement **network segmentation** with dedicated bridge
- Enable **firewall rules** to restrict traffic
- **Snapshot before testing** for easy recovery
- **Monitor logs** for suspicious activity
- **Limit resources** to prevent DoS
- Never use **production credentials**

## Additional Resources

- [Proxmox LXC Documentation](https://pve.proxmox.com/wiki/Linux_Container)
- [Container Networking](https://pve.proxmox.com/wiki/Network_Configuration)
- [Backup and Restore](https://pve.proxmox.com/wiki/Backup_and_Restore)
