#!/bin/bash

# ============================================
# Agent Sandbox - Automated Deployment Script
# ============================================
# Minimal interaction required
# Supports: Docker, Proxmox LXC, direct deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="agent-sandbox"
SECURITY_PROFILE="${1:-basic}"  # Default to basic profile

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
show_banner() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Agent Sandbox - Automated Setup${NC}"
    echo -e "${BLUE}    Security-First AI Agent Testing${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Install Docker if missing
install_docker() {
    log_info "Docker not found. Would you like to install it?"
    echo ""
    read -p "$(echo -e ${YELLOW}Install Docker now? [Y/n]:${NC} )" -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Installing Docker..."
        
        # Detect OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                log_info "Installing Docker via Homebrew..."
                brew install --cask docker
                log_success "Docker installed! Please start Docker Desktop and run this script again."
                exit 0
            else
                log_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install --cask docker
                log_success "Docker installed! Please start Docker Desktop and run this script again."
                exit 0
            fi
        elif [[ -f /etc/debian_version ]]; then
            # Debian/Ubuntu
            log_info "Installing Docker on Debian/Ubuntu..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            log_success "Docker installed! Please log out and back in, then run this script again."
            exit 0
        elif [[ -f /etc/redhat-release ]]; then
            # RHEL/CentOS/Fedora
            log_info "Installing Docker on RHEL/CentOS/Fedora..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            rm get-docker.sh
            log_success "Docker installed! Please log out and back in, then run this script again."
            exit 0
        else
            log_error "Unsupported OS. Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
        fi
    else
        log_info "Skipping Docker installation. Checking for alternatives..."
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check for Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_success "Docker found: $DOCKER_VERSION"
        
        # Check if Docker daemon is running
        if ! docker ps &> /dev/null; then
            log_warning "Docker is installed but not running."
            if [[ "$OSTYPE" == "darwin"* ]]; then
                log_info "Please start Docker Desktop and run this script again."
            else
                log_info "Starting Docker daemon..."
                sudo systemctl start docker
            fi
            exit 1
        fi
        
        DEPLOYMENT_METHOD="docker"
        return 0
    fi
    
    # Docker not found - offer to install
    install_docker
    
    # Check for Proxmox
    if [ -f "/etc/pve/.version" ]; then
        log_success "Proxmox detected"
        DEPLOYMENT_METHOD="proxmox"
        return 0
    fi
    
    log_warning "Neither Docker nor Proxmox detected"
    DEPLOYMENT_METHOD="standalone"
    return 0
}

# Detect deployment environment
detect_environment() {
    log_info "Detecting deployment environment..."
    
    # Check if running in a container
    if [ -f /.dockerenv ]; then
        ENV_TYPE="container"
    elif [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
        ENV_TYPE="container"
    else
        ENV_TYPE="host"
    fi
    
    log_info "Environment type: $ENV_TYPE"
}

# Setup environment files
setup_environment() {
    log_info "Setting up environment files..."
    
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        log_success "Created .env from template"
    else
        log_warning ".env already exists, skipping"
    fi
    
    if [ ! -f "$SCRIPT_DIR/.env.openclaw" ]; then
        cp "$SCRIPT_DIR/.env.openclaw.example" "$SCRIPT_DIR/.env.openclaw"
        log_success "Created .env.openclaw from template"
    else
        log_warning ".env.openclaw already exists, skipping"
    fi
}

# Docker deployment
deploy_docker() {
    log_info "Deploying with Docker Compose..."
    
    # Check for docker-compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        log_error "docker-compose not found. Please install Docker Compose."
        exit 1
    fi
    
    # Pull images
    log_info "Pulling Docker images..."
    $COMPOSE_CMD pull 2>/dev/null || true
    
    # Build custom images
    log_info "Building OpenClaw container..."
    $COMPOSE_CMD build openclaw dlp-scanner
    
    # Start services based on profile
    log_info "Starting services with profile: $SECURITY_PROFILE"
    case "$SECURITY_PROFILE" in
        basic)
            log_info "Basic profile: Full internet access (learning/demos)"
            $COMPOSE_CMD --profile basic up -d web logs openclaw
            ;;
        filtered)
            log_info "Filtered profile: Allowlist-only egress control"
            $COMPOSE_CMD --profile filtered up -d web logs egress-filter openclaw-filtered dlp-scanner
            ;;
        airgapped|air-gapped)
            log_info "Air-gapped profile: No internet access (maximum security)"
            $COMPOSE_CMD --profile airgapped up -d web logs mock-apis openclaw-airgapped dlp-scanner
            ;;
        *)
            log_error "Unknown profile: $SECURITY_PROFILE"
            log_info "Valid profiles: basic, filtered, airgapped"
            exit 1
            ;;
    esac
    
    # Wait for services to be ready
    log_info "Waiting for services to start..."
    sleep 5
    
    # Check service status
    if $COMPOSE_CMD ps | grep -q "Up"; then
        log_success "Services started successfully!"
    else
        log_error "Some services failed to start. Check logs with: $COMPOSE_CMD logs"
        exit 1
    fi
}

# Proxmox LXC deployment
deploy_proxmox() {
    log_info "Proxmox deployment detected..."
    log_info "Creating LXC container configuration..."
    
    cat > /tmp/agent-sandbox-lxc.conf <<EOF
# Agent Sandbox LXC Configuration
arch: amd64
cores: 2
memory: 2048
swap: 512
hostname: agent-sandbox
net0: name=eth0,bridge=vmbr0,firewall=1,ip=dhcp
rootfs: local-lxc:vm-100-disk-0,size=8G
unprivileged: 1
features: nesting=1
EOF
    
    log_info "LXC config created at /tmp/agent-sandbox-lxc.conf"
    log_info "Please create LXC container manually using this configuration"
    log_info "Then run this script again inside the container"
}

# Standalone deployment
deploy_standalone() {
    log_info "Setting up standalone deployment..."
    
    # Check for Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required for standalone deployment"
        exit 1
    fi
    
    # Check for web server
    if command -v nginx &> /dev/null; then
        log_info "Nginx detected, configuring web server..."
        setup_nginx
    elif command -v python3 &> /dev/null; then
        log_info "Starting Python HTTP server..."
        setup_python_server
    fi
}

# Setup Nginx
setup_nginx() {
    log_info "Configuring Nginx..."
    
    cat > /tmp/agent-sandbox-nginx.conf <<EOF
server {
    listen 8080;
    server_name _;
    root $SCRIPT_DIR;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location ~ /\. {
        deny all;
    }
}
EOF
    
    log_success "Nginx config created at /tmp/agent-sandbox-nginx.conf"
    log_info "Copy to /etc/nginx/sites-available/ and enable"
}

# Setup Python server
setup_python_server() {
    log_info "Starting Python HTTP server on port 8080..."
    cd "$SCRIPT_DIR"
    python3 -m http.server 8080 &
    SERVER_PID=$!
    echo $SERVER_PID > /tmp/agent-sandbox-server.pid
    log_success "Server started (PID: $SERVER_PID)"
}

# Setup remote access
setup_remote_access() {
    echo ""
    read -p "$(echo -e ${YELLOW}Do you want to enable remote access? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Remote access options:"
        echo "1) Cloudflare Tunnel (recommended)"
        echo "2) Tailscale"
        echo "3) Skip"
        read -p "Select option [1-3]: " -n 1 -r REMOTE_OPTION
        echo ""
        
        case $REMOTE_OPTION in
            1)
                setup_cloudflare_tunnel
                ;;
            2)
                setup_tailscale
                ;;
            *)
                log_info "Skipping remote access setup"
                ;;
        esac
    fi
}

# Setup Cloudflare Tunnel
setup_cloudflare_tunnel() {
    log_info "Setting up Cloudflare Tunnel..."
    
    if [ "$DEPLOYMENT_METHOD" = "docker" ]; then
        log_info "To enable Cloudflare Tunnel with Docker:"
        echo "1. Get your tunnel token from https://one.dash.cloudflare.com/"
        echo "2. Add CLOUDFLARE_TUNNEL_TOKEN to .env file"
        echo "3. Run: $COMPOSE_CMD --profile remote-access up -d cloudflare-tunnel"
    else
        log_info "Install Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
    fi
}

# Setup Tailscale
setup_tailscale() {
    log_info "Setting up Tailscale..."
    
    if command -v tailscale &> /dev/null; then
        log_success "Tailscale is already installed"
        log_info "Run: sudo tailscale up"
    else
        log_info "Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
    fi
}

# Display access information with testing guide
show_access_info() {
    echo ""
    log_success "Deployment complete!"
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Access Information${NC}"
    echo -e "${GREEN}============================================${NC}"
    
    # Get local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || echo "localhost")
    
    if [ "$DEPLOYMENT_METHOD" = "docker" ]; then
        WEB_PORT=$(grep WEB_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "8080")
        LOG_PORT=$(grep LOG_PORT .env 2>/dev/null | cut -d'=' -f2 || echo "8081")
        
        echo ""
        echo "Web UI:         http://localhost:$WEB_PORT"
        if [ "$LOCAL_IP" != "localhost" ]; then
            echo "                http://$LOCAL_IP:$WEB_PORT"
        fi
        echo ""
        echo "Container Logs: http://localhost:$LOG_PORT"
        if [ "$LOCAL_IP" != "localhost" ]; then
            echo "                http://$LOCAL_IP:$LOG_PORT"
        fi
        echo ""
        echo "Management:"
        echo "  Status:  $COMPOSE_CMD ps"
        echo "  Logs:    $COMPOSE_CMD logs -f"
        echo "  Stop:    $COMPOSE_CMD down"
        echo "  Restart: $COMPOSE_CMD restart"
    else
        echo ""
        echo "Web UI: http://localhost:8080"
        if [ "$LOCAL_IP" != "localhost" ]; then
            echo "        http://$LOCAL_IP:8080"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    log_info "Configuration files:"
    echo "  Environment: .env"
    echo "  OpenClaw:    .env.openclaw"
    echo ""
    
    # Check if credentials are configured
    if ! grep -q "GMAIL_CLIENT_ID=.\+" .env.openclaw 2>/dev/null; then
        echo -e "${YELLOW}============================================${NC}"
        echo -e "${YELLOW}  📋 Next Steps - Testing Guide${NC}"
        echo -e "${YELLOW}============================================${NC}"
        echo ""
        echo "To start testing, you'll need:"
        echo ""
        echo "1. 📧 Create a test Gmail account"
        echo "   └─ Never use your personal account!"
        echo ""
        echo "2. 🔑 Set up Gmail API credentials"
        echo "   └─ Follow: docs/TESTING_GUIDE.md"
        echo ""
        echo "3. ⚙️  Configure credentials"
        echo "   └─ Edit .env.openclaw with your test account"
        echo ""
        echo "4. 🔄 Restart OpenClaw"
        echo "   └─ Run: $COMPOSE_CMD restart openclaw"
        echo ""
        echo "5. 🧪 Start testing!"
        echo "   └─ Open: http://localhost:$WEB_PORT"
        echo ""
        echo -e "${BLUE}📖 Complete testing guide:${NC} docs/TESTING_GUIDE.md"
        echo ""
        echo -e "${YELLOW}============================================${NC}"
        echo ""
    else
        log_success "Credentials configured! Ready to test."
        echo ""
        echo -e "${BLUE}🎯 Quick Start Testing:${NC}"
        echo ""
        echo "1. Open Web UI: http://localhost:$WEB_PORT"
        echo "2. Navigate to 'Testing' section"
        echo "3. Click 'Start Test' on any test case"
        echo "4. Monitor logs: http://localhost:$LOG_PORT"
        echo "5. Document findings with Ctrl/Cmd + K"
        echo ""
        echo -e "${BLUE}📖 Full testing guide:${NC} docs/TESTING_GUIDE.md"
        echo ""
    fi
}

# Cleanup function
cleanup() {
    if [ -f /tmp/agent-sandbox-server.pid ]; then
        PID=$(cat /tmp/agent-sandbox-server.pid)
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            rm /tmp/agent-sandbox-server.pid
        fi
    fi
}

# Main deployment flow
main() {
    show_banner
    
    # Detect environment
    check_requirements
    detect_environment
    
    # Setup environment files
    setup_environment
    
    # Deploy based on method
    case $DEPLOYMENT_METHOD in
        docker)
            deploy_docker
            ;;
        proxmox)
            deploy_proxmox
            return
            ;;
        standalone)
            deploy_standalone
            ;;
    esac
    
    # Optional remote access
    if [ "$DEPLOYMENT_METHOD" = "docker" ]; then
        setup_remote_access
    fi
    
    # Show access information
    show_access_info
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
