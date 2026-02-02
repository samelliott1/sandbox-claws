FROM node:22-slim

# Security: Run as non-root user
RUN groupadd -r openclaw && useradd -r -g openclaw openclaw

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone OpenClaw repository
RUN git clone https://github.com/openclaw/openclaw.git /tmp/openclaw && \
    cp -r /tmp/openclaw/* /app/ && \
    rm -rf /tmp/openclaw

# Install Node dependencies
RUN npm install -g openclaw@latest || \
    (cd /app && npm install)

# Create necessary directories with proper permissions
RUN mkdir -p /app/data /app/logs /app/config /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /app /home/openclaw

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER openclaw

# Set HOME environment variable
ENV HOME=/home/openclaw

# Expose default gateway port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "process.exit(0)"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "--port", "18789", "--verbose"]
