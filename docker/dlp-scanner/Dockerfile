FROM python:3.11-slim

# DLP Scanner for Sandbox Claws
# Monitors logs for sensitive data patterns and alerts/blocks

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir watchdog pyyaml

# Copy scanner script
COPY scanner.py /app/scanner.py

# Run as non-root
RUN useradd -r dlp && chown -R dlp:dlp /app
USER dlp

CMD ["python", "-u", "scanner.py"]
