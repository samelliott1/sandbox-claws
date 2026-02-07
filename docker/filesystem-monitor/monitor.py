#!/usr/bin/env python3
"""
Sandbox Claws - Filesystem Monitor
Detects suspicious file access patterns to prevent credential theft

Monitors for access to:
- SSH keys (~/.ssh/)
- AWS credentials (~/.aws/)
- OpenClaw config (~/.openclaw/)
- Docker credentials (~/.docker/)
- System password files (/etc/passwd, /etc/shadow)
"""

import os
import re
import json
import time
import psutil
import logging
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime
from flask import Flask, jsonify
from collections import defaultdict

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Load suspicious patterns
with open('/app/suspicious_patterns.json', 'r') as f:
    SUSPICIOUS_PATTERNS = json.load(f)

class FilesystemMonitor:
    """Monitor filesystem access for suspicious patterns."""
    
    def __init__(self):
        self.alerts = []
        self.access_counts = defaultdict(int)
        self.blocked_count = 0
        self.scan_interval = int(os.getenv('SCAN_INTERVAL', 5))
    
    def check_process_files(self, proc: psutil.Process) -> List[Dict[str, Any]]:
        """
        Check open files for a process against suspicious patterns.
        
        Args:
            proc: psutil.Process object
            
        Returns:
            List of suspicious file access findings
        """
        findings = []
        
        try:
            # Get command line
            cmdline = ' '.join(proc.cmdline()) if proc.cmdline() else proc.name()
            
            # Check open files
            for f in proc.open_files():
                file_path = f.path
                
                # Check against each pattern category
                for category, patterns in SUSPICIOUS_PATTERNS.items():
                    for pattern_def in patterns:
                        pattern = pattern_def["pattern"]
                        severity = pattern_def["severity"]
                        description = pattern_def["description"]
                        action = pattern_def.get("action", "ALERT")
                        
                        if re.search(pattern, file_path, re.IGNORECASE):
                            finding = {
                                "timestamp": datetime.utcnow().isoformat(),
                                "category": category,
                                "severity": severity,
                                "description": description,
                                "file_path": file_path,
                                "process_name": proc.name(),
                                "process_pid": proc.pid,
                                "command_line": cmdline,
                                "action": action,
                            }
                            findings.append(finding)
                            self.access_counts[file_path] += 1
                            
                            if action == "BLOCK":
                                self.blocked_count += 1
                            
                            # Log finding
                            if severity == "CRITICAL":
                                logger.critical(
                                    f"🚨 {action}: {proc.name()} (PID {proc.pid}) "
                                    f"accessing {file_path} - {description}"
                                )
                            elif severity == "HIGH":
                                logger.warning(
                                    f"⚠️ {action}: {proc.name()} (PID {proc.pid}) "
                                    f"accessing {file_path} - {description}"
                                )
                            else:
                                logger.info(
                                    f"ℹ️ {action}: {proc.name()} (PID {proc.pid}) "
                                    f"accessing {file_path}"
                                )
        
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
        
        return findings
    
    def scan_processes(self) -> List[Dict[str, Any]]:
        """Scan all running processes for suspicious file access."""
        all_findings = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                findings = self.check_process_files(proc)
                all_findings.extend(findings)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        # Store alerts
        for finding in all_findings:
            self.alerts.append(finding)
        
        # Keep only last 1000 alerts
        if len(self.alerts) > 1000:
            self.alerts = self.alerts[-1000:]
        
        return all_findings
    
    def get_alerts(self, severity: str = None, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent alerts, optionally filtered by severity."""
        alerts = self.alerts
        
        if severity:
            alerts = [a for a in alerts if a["severity"] == severity]
        
        return alerts[-limit:]
    
    def get_stats(self) -> Dict[str, Any]:
        """Get monitoring statistics."""
        severity_counts = defaultdict(int)
        for alert in self.alerts:
            severity_counts[alert["severity"]] += 1
        
        return {
            "total_alerts": len(self.alerts),
            "blocked_count": self.blocked_count,
            "severity_counts": dict(severity_counts),
            "most_accessed_files": dict(sorted(
                self.access_counts.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]),
        }
    
    def monitor_loop(self):
        """Main monitoring loop."""
        logger.info("🚀 Starting Filesystem Monitor...")
        logger.info(f"🔍 Scan interval: {self.scan_interval} seconds")
        
        while True:
            try:
                findings = self.scan_processes()
                if findings:
                    logger.info(f"📊 Found {len(findings)} suspicious file accesses")
                
                time.sleep(self.scan_interval)
            
            except KeyboardInterrupt:
                logger.info("👋 Filesystem Monitor stopped")
                break
            except Exception as e:
                logger.error(f"Error in monitor loop: {e}")
                time.sleep(self.scan_interval)

# Global monitor instance
monitor = FilesystemMonitor()

# Flask API endpoints
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": "filesystem-monitor"})

@app.route('/alerts', methods=['GET'])
def get_alerts():
    """Get recent alerts."""
    severity = request.args.get('severity')
    limit = int(request.args.get('limit', 100))
    
    alerts = monitor.get_alerts(severity, limit)
    return jsonify({
        "alerts": alerts,
        "count": len(alerts)
    })

@app.route('/alerts/critical', methods=['GET'])
def get_critical_alerts():
    """Get critical alerts only."""
    alerts = monitor.get_alerts("CRITICAL", 100)
    return jsonify({
        "alerts": alerts,
        "count": len(alerts)
    })

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get monitoring statistics."""
    return jsonify(monitor.get_stats())

@app.route('/scan', methods=['POST'])
def trigger_scan():
    """Manually trigger a scan."""
    findings = monitor.scan_processes()
    return jsonify({
        "findings": findings,
        "count": len(findings)
    })

if __name__ == '__main__':
    import threading
    
    # Start monitoring in background thread
    monitor_thread = threading.Thread(target=monitor.monitor_loop, daemon=True)
    monitor_thread.start()
    
    # Start Flask API
    port = int(os.getenv('MONITOR_PORT', 5002))
    logger.info(f"🌐 Starting API server on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
