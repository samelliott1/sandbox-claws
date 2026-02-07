# Cost Tracker - Monitor and limit AI agent costs
FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 costtracker

WORKDIR /app

# Copy requirements
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY tracker.py /app/
COPY pricing.json /app/

# Create data directory
RUN mkdir -p /app/data && chown costtracker:costtracker /app/data

# Switch to non-root user
USER costtracker

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5003/health || exit 1

# Expose port
EXPOSE 5003

# Run tracker
CMD ["python", "-u", "tracker.py"]
