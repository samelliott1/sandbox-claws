#!/bin/bash

# ============================================
# Sandbox Claws - Uninstall Script
# ============================================
# Safely removes all components with optional Docker removal

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}    Sandbox Claws - Uninstall${NC}"
    echo -e "${RED}============================================${NC}"
    echo ""
}

# Check for docker-compose
get_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    elif docker compose version &> /dev/null 2>&1; then
        echo "docker compose"
    else
        echo ""
    fi
}

# Stop and remove containers
remove_containers() {
    log_info "Stopping and removing Sandbox Claws containers..."
    
    COMPOSE_CMD=$(get_compose_cmd)
    
    if [ -n "$COMPOSE_CMD" ]; then
        # Stop all running containers
        $COMPOSE_CMD down --volumes --remove-orphans 2>/dev/null || true
        
        # Force remove any remaining containers
        docker ps -a --filter "label=com.sandbox-claws.component" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
        
        log_success "Containers removed"
    else
        log_warning "Docker Compose not found, skipping container removal"
    fi
}

# Remove Docker images
remove_images() {
    echo ""
    read -p "$(echo -e ${YELLOW}Remove Sandbox Claws Docker images? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing Docker images..."
        
        # Remove custom built images
        docker images --filter "reference=sandbox-claws*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
        docker images --filter "reference=*openclaw*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
        docker images --filter "reference=*dlp-scanner*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
        
        log_success "Images removed"
    else
        log_info "Keeping Docker images"
    fi
}

# Remove Docker volumes
remove_volumes() {
    echo ""
    read -p "$(echo -e ${YELLOW}Remove data volumes (this deletes all OpenClaw data)? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing Docker volumes..."
        
        docker volume ls --filter "name=sandbox-claws" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
        docker volume ls --filter "name=openclaw" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
        docker volume ls --filter "name=squid" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
        
        log_success "Volumes removed"
    else
        log_info "Keeping data volumes"
    fi
}

# Remove Docker networks
remove_networks() {
    log_info "Removing Docker networks..."
    
    docker network ls --filter "name=sandbox-claws" --format "{{.ID}}" | xargs -r docker network rm 2>/dev/null || true
    
    log_success "Networks removed"
}

# Remove configuration files
remove_config() {
    echo ""
    read -p "$(echo -e ${YELLOW}Remove configuration files (.env, .env.openclaw)? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing configuration files..."
        
        [ -f .env ] && rm .env && echo "  ✓ Removed .env"
        [ -f .env.openclaw ] && rm .env.openclaw && echo "  ✓ Removed .env.openclaw"
        
        log_success "Configuration files removed"
    else
        log_info "Keeping configuration files"
    fi
}

# Uninstall Docker
uninstall_docker() {
    echo ""
    read -p "$(echo -e ${RED}Uninstall Docker completely? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "This will uninstall Docker and all containers/images from ALL projects!"
        echo ""
        read -p "$(echo -e ${RED}Are you absolutely sure? [y/N]:${NC} )" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Uninstalling Docker..."
            
            # Detect OS
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                if [ -d "/Applications/Docker.app" ]; then
                    log_info "Removing Docker Desktop..."
                    
                    # Quit Docker Desktop
                    osascript -e 'quit app "Docker"' 2>/dev/null || true
                    sleep 2
                    
                    # Remove Docker.app
                    sudo rm -rf /Applications/Docker.app
                    
                    # Remove Docker data
                    rm -rf ~/Library/Group\ Containers/group.com.docker
                    rm -rf ~/Library/Containers/com.docker.docker
                    rm -rf ~/.docker
                    
                    # Remove CLI symlinks
                    sudo rm -f /usr/local/bin/docker
                    sudo rm -f /usr/local/bin/docker-compose
                    sudo rm -f /usr/local/bin/docker-credential-desktop
                    sudo rm -f /usr/local/bin/docker-credential-ecr-login
                    sudo rm -f /usr/local/bin/docker-credential-osxkeychain
                    
                    log_success "Docker Desktop uninstalled"
                else
                    log_warning "Docker Desktop not found in /Applications"
                fi
                
                # Uninstall via Homebrew if installed that way
                if command -v brew &> /dev/null; then
                    if brew list --cask docker &> /dev/null 2>&1; then
                        log_info "Uninstalling Docker via Homebrew..."
                        brew uninstall --cask docker 2>/dev/null || true
                        log_success "Docker uninstalled via Homebrew"
                    fi
                fi
                
            elif [[ -f /etc/debian_version ]]; then
                # Debian/Ubuntu
                log_info "Uninstalling Docker on Debian/Ubuntu..."
                sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                sudo apt-get autoremove -y
                sudo rm -rf /var/lib/docker
                sudo rm -rf /var/lib/containerd
                log_success "Docker uninstalled"
                
            elif [[ -f /etc/redhat-release ]]; then
                # RHEL/CentOS/Fedora
                log_info "Uninstalling Docker on RHEL/CentOS/Fedora..."
                sudo yum remove -y docker-ce docker-ce-cli containerd.io
                sudo rm -rf /var/lib/docker
                sudo rm -rf /var/lib/containerd
                log_success "Docker uninstalled"
                
            else
                log_warning "Unsupported OS. Please uninstall Docker manually."
            fi
        else
            log_info "Docker uninstall cancelled"
        fi
    else
        log_info "Keeping Docker installed"
    fi
}

# Clean up dangling resources
cleanup_dangling() {
    if command -v docker &> /dev/null && docker ps &> /dev/null 2>&1; then
        echo ""
        read -p "$(echo -e ${YELLOW}Clean up dangling Docker resources (unused images, volumes)? [y/N]:${NC} )" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleaning up dangling resources..."
            
            docker system prune -f 2>/dev/null || true
            docker volume prune -f 2>/dev/null || true
            
            log_success "Dangling resources cleaned"
        fi
    fi
}

# Main uninstall flow
main() {
    show_banner
    
    log_warning "This will uninstall Sandbox Claws components."
    echo ""
    read -p "$(echo -e ${YELLOW}Continue with uninstall? [y/N]:${NC} )" -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    echo ""
    log_info "Starting uninstall process..."
    echo ""
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_warning "Docker not found, skipping container cleanup"
    else
        # Stop and remove containers
        remove_containers
        
        # Remove images (optional)
        remove_images
        
        # Remove volumes (optional)
        remove_volumes
        
        # Remove networks
        remove_networks
        
        # Clean up dangling resources (optional)
        cleanup_dangling
    fi
    
    # Remove config files (optional)
    remove_config
    
    # Uninstall Docker (optional)
    uninstall_docker
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Uninstall Complete${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    
    log_success "Sandbox Claws has been uninstalled"
    echo ""
    
    log_info "What was kept (if you chose to keep them):"
    echo "  • Configuration files (.env, .env.openclaw)"
    echo "  • Data volumes (OpenClaw data, logs)"
    echo "  • Docker installation"
    echo "  • This repository folder"
    echo ""
    
    log_info "To completely remove this repository:"
    echo "  cd .."
    echo "  rm -rf sandbox-claws"
    echo ""
}

# Run main function
main "$@"
