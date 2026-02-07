# Skill Scanner - Detect malicious patterns in OpenClaw skills
FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 scanner

WORKDIR /app

# Copy requirements
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy scanner application
COPY scanner.py /app/
COPY patterns.json /app/

# Create output directory
RUN mkdir -p /app/scan-results && chown scanner:scanner /app/scan-results

# Switch to non-root user
USER scanner

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/app/scanner.py') else 1)"

# Run scanner
CMD ["python", "-u", "scanner.py"]
