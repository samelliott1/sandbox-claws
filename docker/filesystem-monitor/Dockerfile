# Filesystem Monitor - Detect suspicious file access patterns
FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    procps \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 fsmonitor

WORKDIR /app

# Copy requirements
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy monitor application
COPY monitor.py /app/
COPY suspicious_patterns.json /app/

# Create alerts directory
RUN mkdir -p /app/alerts && chown fsmonitor:fsmonitor /app/alerts

# Switch to non-root user
USER fsmonitor

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/app/monitor.py') else 1)"

# Run monitor
CMD ["python", "-u", "monitor.py"]
