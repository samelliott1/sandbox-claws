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

# Ensure directories exist
mkdir -p /app/logs
mkdir -p /app/data
mkdir -p /home/openclaw/.openclaw

# Check if OpenClaw is installed globally
if command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw is installed globally"
elif [ -f "/app/packages/cli/dist/index.js" ]; then
    echo "Using OpenClaw from source"
    export PATH="/app/packages/cli/dist:$PATH"
else
    echo "Warning: OpenClaw not found, attempting to run anyway..."
fi

echo "Starting OpenClaw gateway..."
exec "$@"
