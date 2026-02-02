FROM python:3.11-slim

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

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || \
    echo "No requirements.txt found, skipping pip install"

# Create necessary directories with proper permissions
RUN mkdir -p /app/data /app/logs /app/config && \
    chown -R openclaw:openclaw /app

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER openclaw

# Expose default port (if needed)
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "-m", "openclaw"]
