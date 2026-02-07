# ✅ Uninstall Script Added!

## What Was Added

A comprehensive `uninstall-sandbox-claws.sh` script that safely removes all Sandbox Claws components with interactive prompts.

## Features

### 🎯 Interactive Uninstall Process

The script asks for confirmation before each action:

1. **Stop & Remove Containers** - Automatically removes all Sandbox Claws containers
2. **Remove Images** (optional) - Delete Docker images to save space
3. **Remove Volumes** (optional) - Delete data volumes (warns about data loss)
4. **Remove Networks** - Clean up Docker networks
5. **Remove Config Files** (optional) - Delete .env and .env.openclaw files
6. **Uninstall Docker** (optional) - Complete Docker removal with double confirmation
7. **Clean Dangling Resources** (optional) - Remove unused Docker resources

### 🛡️ Safety Features

- ✅ **Interactive prompts** - You control what gets removed
- ✅ **Double confirmation** for Docker uninstall
- ✅ **Clear warnings** before deleting data
- ✅ **Color-coded output** for easy reading
- ✅ **Safe defaults** - Only removes Sandbox Claws components by default

### 🖥️ Cross-Platform Support

Works on:
- ✅ **macOS** (removes Docker Desktop properly)
- ✅ **Ubuntu/Debian** (apt-based systems)
- ✅ **RHEL/CentOS/Fedora** (yum-based systems)

## Usage

### On Your Mac

```bash
# Pull the latest updates
git pull origin main

# Make executable
chmod +x uninstall-sandbox-claws.sh

# Run uninstall
./uninstall-sandbox-claws.sh
```

### Example Uninstall Flow

```bash
$ ./uninstall-sandbox-claws.sh

============================================
    Sandbox Claws - Uninstall
============================================

[WARNING] This will uninstall Sandbox Claws components.

Continue with uninstall? [y/N]: y

[INFO] Starting uninstall process...

[INFO] Stopping and removing Sandbox Claws containers...
[SUCCESS] Containers removed

Remove Sandbox Claws Docker images? [y/N]: y
[INFO] Removing Docker images...
[SUCCESS] Images removed

Remove data volumes (this deletes all OpenClaw data)? [y/N]: n
[INFO] Keeping data volumes

[INFO] Removing Docker networks...
[SUCCESS] Networks removed

Clean up dangling Docker resources (unused images, volumes)? [y/N]: y
[INFO] Cleaning up dangling resources...
[SUCCESS] Dangling resources cleaned

Remove configuration files (.env, .env.openclaw)? [y/N]: n
[INFO] Keeping configuration files

Uninstall Docker completely? [y/N]: n
[INFO] Keeping Docker installed

============================================
  Uninstall Complete
============================================

[SUCCESS] Sandbox Claws has been uninstalled

[INFO] What was kept (if you chose to keep them):
  • Configuration files (.env, .env.openclaw)
  • Data volumes (OpenClaw data, logs)
  • Docker installation
  • This repository folder

[INFO] To completely remove this repository:
  cd ..
  rm -rf sandbox-claws
```

## What Gets Removed

### Always Removed (No Prompt)
- Sandbox Claws containers
- Sandbox Claws Docker networks

### Optional (With Confirmation)
- Docker images (saves disk space)
- Data volumes (permanent data loss!)
- Configuration files (.env files)
- Docker installation (complete removal)
- Dangling resources (cleanup)

## Safety Notes

⚠️ **Data Volumes**: If you remove data volumes, all OpenClaw data, logs, and history will be permanently deleted.

⚠️ **Docker Uninstall**: If you uninstall Docker, ALL Docker containers and images from ALL projects will be removed (not just Sandbox Claws).

✅ **Repository Files**: The uninstall script never removes the repository files themselves. You can always redeploy.

## Reinstalling After Uninstall

If you want to reinstall after uninstalling:

```bash
# If you kept the repository
./deploy.sh

# If you removed everything
git clone https://github.com/samelliott1/sandbox-claws.git
cd sandbox-claws
./deploy.sh
```

## Commands Summary

```bash
# Install/Deploy
./deploy.sh              # Basic profile (default)
./deploy.sh filtered     # Filtered profile
./deploy.sh airgapped    # Air-gapped profile

# Uninstall
./uninstall-sandbox-claws.sh           # Interactive uninstall

# Management
docker compose ps        # Check status
docker compose logs -f   # View logs
docker compose down      # Stop services
docker compose restart   # Restart services
```

---

**The uninstall script is now live on GitHub!** 🎉

Pull the latest changes to get it:
```bash
git pull origin main
chmod +x uninstall.sh
```
