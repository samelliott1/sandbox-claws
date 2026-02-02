#!/usr/bin/env python3
"""
Data Loss Prevention Scanner for Sandbox Claws
Monitors OpenClaw logs for sensitive data patterns
"""

import re
import os
import time
import json
from datetime import datetime
from pathlib import Path

# Configuration
SCAN_INTERVAL = int(os.getenv('SCAN_INTERVAL', '5'))
ACTION = os.getenv('ACTION', 'alert')  # 'alert' or 'block'
LOG_DIR = Path('/logs')

# Load patterns
PATTERNS_FILE = Path('/config/patterns.json')
if PATTERNS_FILE.exists():
    with open(PATTERNS_FILE) as f:
        PATTERNS = json.load(f)
else:
    # Default patterns
    PATTERNS = {
        'credit_card': r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
        'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
        'api_key': r'(sk|pk)[-_][A-Za-z0-9]{32,}',
        'private_key': r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
        'aws_key': r'AKIA[0-9A-Z]{16}',
        'password': r'password["\']?\s*[:=]\s*["\']?[^\s"\']+',
        'email': r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Z|a-z]{2,}',
    }

def alert(finding_type, content, filename, line_number):
    """Alert on sensitive data detection"""
    timestamp = datetime.now().isoformat()
    alert_msg = {
        'timestamp': timestamp,
        'severity': 'CRITICAL',
        'type': 'DATA_EXFILTRATION_ATTEMPT',
        'finding': finding_type,
        'file': str(filename),
        'line': line_number,
        'content_preview': content[:100] + '...' if len(content) > 100 else content
    }
    
    print(f"\n{'='*60}")
    print(f"🚨 DLP ALERT: {finding_type.upper()} DETECTED")
    print(f"{'='*60}")
    print(f"Time: {timestamp}")
    print(f"File: {filename}")
    print(f"Line: {line_number}")
    print(f"Pattern: {finding_type}")
    print(f"Preview: {alert_msg['content_preview']}")
    print(f"{'='*60}\n")
    
    # Write to alert log
    with open('/logs/dlp-alerts.log', 'a') as f:
        f.write(json.dumps(alert_msg) + '\n')
    
    # If ACTION is 'block', could stop container here
    if ACTION == 'block':
        print("🛑 BLOCKING: Would stop OpenClaw container (not implemented)")
        # os.system('docker stop sandbox-claws-openclaw')

def scan_file(filepath):
    """Scan a file for sensitive patterns"""
    try:
        with open(filepath, 'r', errors='ignore') as f:
            for line_num, line in enumerate(f, 1):
                for pattern_name, pattern in PATTERNS.items():
                    matches = re.finditer(pattern, line, re.IGNORECASE)
                    for match in matches:
                        alert(pattern_name, line.strip(), filepath.name, line_num)
    except Exception as e:
        print(f"Error scanning {filepath}: {e}")

def scan_logs():
    """Scan all log files"""
    if not LOG_DIR.exists():
        print(f"Log directory {LOG_DIR} not found, waiting...")
        return
    
    for logfile in LOG_DIR.glob('*.log'):
        # Skip our own alert log
        if logfile.name == 'dlp-alerts.log':
            continue
        scan_file(logfile)

def main():
    print("="*60)
    print("🔒 Sandbox Claws DLP Scanner")
    print("="*60)
    print(f"Scan interval: {SCAN_INTERVAL} seconds")
    print(f"Action mode: {ACTION}")
    print(f"Monitoring patterns: {', '.join(PATTERNS.keys())}")
    print(f"Log directory: {LOG_DIR}")
    print("="*60)
    print("\nStarting monitoring...\n")
    
    # Track file positions to avoid re-scanning
    file_positions = {}
    
    while True:
        try:
            scan_logs()
            time.sleep(SCAN_INTERVAL)
        except KeyboardInterrupt:
            print("\n\nStopping DLP scanner...")
            break
        except Exception as e:
            print(f"Error in main loop: {e}")
            time.sleep(SCAN_INTERVAL)

if __name__ == '__main__':
    main()
