#!/bin/sh
set -e

echo "============================================"
echo "  OpenClaw Agent Sandbox - Starting"
echo "============================================"
echo "Environment: ${OPENCLAW_ENV}"
echo "Log Level: ${OPENCLAW_LOG_LEVEL}"
echo "============================================"

# Check if config file exists
if [ -f "/app/config/.env" ]; then
    echo "Loading configuration from /app/config/.env"
    export $(grep -v '^#' /app/config/.env | xargs)
fi

# Ensure log directory exists
mkdir -p /app/logs
mkdir -p /app/data

echo "Starting OpenClaw..."
exec "$@"
