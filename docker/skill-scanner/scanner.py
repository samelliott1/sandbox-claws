#!/usr/bin/env python3
"""
Sandbox Claws - Skill Marketplace Scanner
Detects malicious patterns in OpenClaw/ClawHub skills

Based on Reddit security research:
- Credential access patterns
- Data exfiltration attempts
- Obfuscation techniques
- Destructive commands
"""

import os
import re
import json
import time
import logging
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime
from flask import Flask, jsonify, request
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Load malicious patterns
with open('/app/patterns.json', 'r') as f:
    PATTERNS = json.load(f)

class SkillScanner:
    """Scanner for detecting malicious patterns in skills."""
    
    def __init__(self):
        self.scan_results = {}
        self.total_scanned = 0
        self.total_blocked = 0
    
    def scan_content(self, content: str, skill_name: str = "unknown") -> Dict[str, Any]:
        """
        Scan skill content for malicious patterns.
        
        Args:
            content: The skill file content (markdown or code)
            skill_name: Name of the skill being scanned
            
        Returns:
            Dictionary with scan results
        """
        findings = []
        severity_score = 0
        
        # Check each pattern category
        for category, patterns in PATTERNS.items():
            for pattern_def in patterns:
                pattern = pattern_def["pattern"]
                severity = pattern_def.get("severity", "MEDIUM")
                description = pattern_def.get("description", "")
                
                # Search for pattern
                matches = re.finditer(pattern, content, re.IGNORECASE | re.MULTILINE)
                for match in matches:
                    # Calculate line number
                    line_num = content[:match.start()].count('\n') + 1
                    
                    findings.append({
                        "category": category,
                        "severity": severity,
                        "description": description,
                        "pattern": pattern,
                        "line": line_num,
                        "match": match.group(0)[:100],  # Truncate long matches
                    })
                    
                    # Add to severity score
                    severity_score += {
                        "CRITICAL": 10,
                        "HIGH": 5,
                        "MEDIUM": 2,
                        "LOW": 1
                    }.get(severity, 0)
        
        # Determine if skill should be blocked
        blocked = severity_score >= 10 or any(
            f["severity"] == "CRITICAL" for f in findings
        )
        
        result = {
            "skill_name": skill_name,
            "timestamp": datetime.utcnow().isoformat(),
            "safe": len(findings) == 0,
            "blocked": blocked,
            "severity_score": severity_score,
            "findings_count": len(findings),
            "findings": findings,
            "recommendation": self._get_recommendation(blocked, severity_score, findings)
        }
        
        self.total_scanned += 1
        if blocked:
            self.total_blocked += 1
        
        return result
    
    def _get_recommendation(self, blocked: bool, score: int, findings: List[Dict]) -> str:
        """Generate security recommendation."""
        if blocked:
            return "🚨 BLOCK - Critical security risk detected. DO NOT EXECUTE."
        elif score >= 5:
            return "⚠️ WARN - High risk patterns detected. Review carefully before use."
        elif score >= 2:
            return "⚠️ CAUTION - Medium risk patterns detected. Proceed with caution."
        elif len(findings) > 0:
            return "ℹ️ INFO - Low risk patterns detected. Review recommended."
        else:
            return "✅ SAFE - No malicious patterns detected."
    
    def scan_file(self, file_path: str) -> Dict[str, Any]:
        """Scan a skill file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            skill_name = Path(file_path).name
            result = self.scan_content(content, skill_name)
            
            # Save result
            self.scan_results[skill_name] = result
            
            # Log result
            if result["blocked"]:
                logger.warning(f"🚨 BLOCKED: {skill_name} - {result['findings_count']} issues found")
            elif result["severity_score"] > 0:
                logger.info(f"⚠️ WARNING: {skill_name} - {result['findings_count']} issues found")
            else:
                logger.info(f"✅ SAFE: {skill_name}")
            
            return result
            
        except Exception as e:
            logger.error(f"Error scanning {file_path}: {e}")
            return {
                "skill_name": Path(file_path).name,
                "error": str(e),
                "safe": False,
                "blocked": True,
                "recommendation": "🚨 ERROR - Could not scan file"
            }
    
    def scan_directory(self, directory: str) -> List[Dict[str, Any]]:
        """Scan all skill files in a directory."""
        results = []
        skill_dir = Path(directory)
        
        if not skill_dir.exists():
            logger.warning(f"Directory not found: {directory}")
            return results
        
        # Scan all .md and .txt files
        for file_path in skill_dir.rglob("*.md"):
            result = self.scan_file(str(file_path))
            results.append(result)
        
        for file_path in skill_dir.rglob("*.txt"):
            result = self.scan_file(str(file_path))
            results.append(result)
        
        return results
    
    def get_stats(self) -> Dict[str, Any]:
        """Get scanner statistics."""
        return {
            "total_scanned": self.total_scanned,
            "total_blocked": self.total_blocked,
            "block_rate": round(self.total_blocked / max(self.total_scanned, 1) * 100, 2),
            "scan_results_count": len(self.scan_results)
        }

# Global scanner instance
scanner = SkillScanner()

# Flask API endpoints
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": "skill-scanner"})

@app.route('/scan', methods=['POST'])
def scan_skill():
    """
    Scan skill content via API.
    
    Body:
        {
            "content": "skill content here",
            "skill_name": "optional-name"
        }
    """
    data = request.get_json()
    content = data.get('content', '')
    skill_name = data.get('skill_name', 'api-submission')
    
    if not content:
        return jsonify({"error": "No content provided"}), 400
    
    result = scanner.scan_content(content, skill_name)
    return jsonify(result)

@app.route('/scan-file', methods=['POST'])
def scan_file_endpoint():
    """
    Scan a skill file.
    
    Body:
        {
            "file_path": "/path/to/skill.md"
        }
    """
    data = request.get_json()
    file_path = data.get('file_path', '')
    
    if not file_path:
        return jsonify({"error": "No file_path provided"}), 400
    
    result = scanner.scan_file(file_path)
    return jsonify(result)

@app.route('/results', methods=['GET'])
def get_results():
    """Get all scan results."""
    return jsonify({
        "results": list(scanner.scan_results.values()),
        "stats": scanner.get_stats()
    })

@app.route('/results/<skill_name>', methods=['GET'])
def get_result(skill_name):
    """Get result for a specific skill."""
    result = scanner.scan_results.get(skill_name)
    if result:
        return jsonify(result)
    else:
        return jsonify({"error": "Skill not found"}), 404

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get scanner statistics."""
    return jsonify(scanner.get_stats())

# File watcher for automatic scanning
class SkillFileHandler(FileSystemEventHandler):
    """Watch for new skill files and scan them automatically."""
    
    def on_created(self, event):
        if not event.is_directory and (event.src_path.endswith('.md') or event.src_path.endswith('.txt')):
            logger.info(f"New skill file detected: {event.src_path}")
            scanner.scan_file(event.src_path)
    
    def on_modified(self, event):
        if not event.is_directory and (event.src_path.endswith('.md') or event.src_path.endswith('.txt')):
            logger.info(f"Skill file modified: {event.src_path}")
            scanner.scan_file(event.src_path)

def start_file_watcher(watch_dir: str):
    """Start watching directory for skill files."""
    if not os.path.exists(watch_dir):
        logger.warning(f"Watch directory does not exist: {watch_dir}")
        return None
    
    event_handler = SkillFileHandler()
    observer = Observer()
    observer.schedule(event_handler, watch_dir, recursive=True)
    observer.start()
    logger.info(f"📂 Watching directory: {watch_dir}")
    return observer

if __name__ == '__main__':
    logger.info("🚀 Starting Sandbox Claws Skill Scanner...")
    
    # Scan existing skills on startup
    skills_dir = os.getenv('SKILLS_DIR', '/skills')
    if os.path.exists(skills_dir):
        logger.info(f"🔍 Scanning existing skills in {skills_dir}...")
        results = scanner.scan_directory(skills_dir)
        logger.info(f"✅ Initial scan complete: {len(results)} skills scanned")
        logger.info(f"📊 Stats: {scanner.get_stats()}")
    
    # Start file watcher
    observer = start_file_watcher(skills_dir)
    
    # Start Flask API
    port = int(os.getenv('SCANNER_PORT', 5001))
    logger.info(f"🌐 Starting API server on port {port}")
    
    try:
        app.run(host='0.0.0.0', port=port, debug=False)
    except KeyboardInterrupt:
        if observer:
            observer.stop()
            observer.join()
        logger.info("👋 Skill Scanner stopped")
