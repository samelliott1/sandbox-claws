#!/usr/bin/env python3
"""
Sandbox Claws - Cost Tracker
Monitors and limits AI agent API costs

Features:
- Budget limits (per session, per hour, per day)
- Rate limiting (calls per minute)
- Token counting and cost estimation
- Real-time cost tracking
- Alerts and notifications
"""

import os
import json
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from collections import deque
from flask import Flask, jsonify, request
from flask_cors import CORS

# Try to import tiktoken for accurate token counting
try:
    import tiktoken
    TIKTOKEN_AVAILABLE = True
except ImportError:
    TIKTOKEN_AVAILABLE = False
    logging.warning("tiktoken not available, using approximate token counting")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for web UI

# Load pricing data
with open('/app/pricing.json', 'r') as f:
    PRICING = json.load(f)

class CostTracker:
    """Track and limit AI agent costs."""
    
    def __init__(self):
        # Configuration from environment
        self.max_session_cost = float(os.getenv('MAX_COST_PER_SESSION_USD', 10.00))
        self.max_hourly_cost = float(os.getenv('MAX_COST_PER_HOUR_USD', 50.00))
        self.max_daily_cost = float(os.getenv('MAX_COST_PER_DAY_USD', 200.00))
        self.max_calls_per_minute = int(os.getenv('MAX_API_CALLS_PER_MINUTE', 30))
        self.max_tokens_per_request = int(os.getenv('MAX_TOKENS_PER_REQUEST', 8000))
        self.alert_threshold = float(os.getenv('ALERT_AT_PERCENT', 80.0))
        
        # Session tracking
        self.session_cost = 0.0
        self.session_calls = 0
        self.session_tokens = {"input": 0, "output": 0}
        self.session_start = datetime.utcnow()
        
        # Hourly tracking
        self.hourly_cost = 0.0
        self.hourly_reset = datetime.utcnow() + timedelta(hours=1)
        
        # Daily tracking
        self.daily_cost = 0.0
        self.daily_reset = datetime.utcnow() + timedelta(days=1)
        
        # Rate limiting
        self.call_times = deque()
        
        # Call history
        self.call_history = []
        self.alerts = []
        
        # Initialize tiktoken if available
        if TIKTOKEN_AVAILABLE:
            try:
                self.encoding = tiktoken.encoding_for_model("gpt-4")
            except:
                self.encoding = tiktoken.get_encoding("cl100k_base")
        
        logger.info("💰 Cost Tracker initialized")
        logger.info(f"   Session budget: ${self.max_session_cost:.2f}")
        logger.info(f"   Hourly budget: ${self.max_hourly_cost:.2f}")
        logger.info(f"   Daily budget: ${self.max_daily_cost:.2f}")
        logger.info(f"   Rate limit: {self.max_calls_per_minute} calls/minute")
    
    def count_tokens(self, text: str) -> int:
        """Count tokens in text."""
        if TIKTOKEN_AVAILABLE and self.encoding:
            try:
                return len(self.encoding.encode(text))
            except:
                pass
        
        # Approximate: ~1.3 words per token
        return int(len(text.split()) * 1.3)
    
    def estimate_cost(self, prompt: str, model: str = "default", 
                     expected_output_tokens: Optional[int] = None) -> Dict[str, Any]:
        """
        Estimate cost for an API call.
        
        Args:
            prompt: Input prompt text
            model: Model name (e.g., "claude-opus-4.5")
            expected_output_tokens: Expected output length (if known)
            
        Returns:
            Dictionary with cost estimate and token counts
        """
        # Get pricing for model
        pricing = PRICING.get(model, PRICING["default"])
        
        # Count input tokens
        input_tokens = self.count_tokens(prompt)
        
        # Estimate output tokens (default: 50% of input length)
        if expected_output_tokens is None:
            output_tokens = int(input_tokens * 0.5)
        else:
            output_tokens = expected_output_tokens
        
        # Calculate costs
        input_cost = (input_tokens / 1_000_000) * pricing["input_per_million"]
        output_cost = (output_tokens / 1_000_000) * pricing["output_per_million"]
        total_cost = input_cost + output_cost
        
        return {
            "model": model,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens,
            "input_cost": input_cost,
            "output_cost": output_cost,
            "total_cost": total_cost,
            "pricing": pricing
        }
    
    def check_rate_limit(self) -> Dict[str, Any]:
        """Check if rate limit would be exceeded."""
        now = time.time()
        
        # Remove calls older than 1 minute
        while self.call_times and self.call_times[0] < now - 60:
            self.call_times.popleft()
        
        calls_this_minute = len(self.call_times)
        
        if calls_this_minute >= self.max_calls_per_minute:
            return {
                "allowed": False,
                "reason": "rate_limit_exceeded",
                "calls_this_minute": calls_this_minute,
                "max_per_minute": self.max_calls_per_minute,
                "retry_after_seconds": 60 - (now - self.call_times[0])
            }
        
        return {
            "allowed": True,
            "calls_this_minute": calls_this_minute,
            "max_per_minute": self.max_calls_per_minute,
            "remaining": self.max_calls_per_minute - calls_this_minute
        }
    
    def check_budget(self, estimated_cost: float) -> Dict[str, Any]:
        """
        Check if making a call would exceed budget limits.
        
        Args:
            estimated_cost: Estimated cost of the call
            
        Returns:
            Dictionary with allowed status and details
        """
        # Reset hourly/daily if needed
        now = datetime.utcnow()
        if now >= self.hourly_reset:
            self.hourly_cost = 0.0
            self.hourly_reset = now + timedelta(hours=1)
        if now >= self.daily_reset:
            self.daily_cost = 0.0
            self.daily_reset = now + timedelta(days=1)
        
        # Check session budget
        if self.session_cost + estimated_cost > self.max_session_cost:
            return {
                "allowed": False,
                "reason": "session_budget_exceeded",
                "current_cost": self.session_cost,
                "estimated_cost": estimated_cost,
                "max_budget": self.max_session_cost,
                "would_exceed_by": (self.session_cost + estimated_cost) - self.max_session_cost
            }
        
        # Check hourly budget
        if self.hourly_cost + estimated_cost > self.max_hourly_cost:
            return {
                "allowed": False,
                "reason": "hourly_budget_exceeded",
                "current_cost": self.hourly_cost,
                "estimated_cost": estimated_cost,
                "max_budget": self.max_hourly_cost,
                "would_exceed_by": (self.hourly_cost + estimated_cost) - self.max_hourly_cost
            }
        
        # Check daily budget
        if self.daily_cost + estimated_cost > self.max_daily_cost:
            return {
                "allowed": False,
                "reason": "daily_budget_exceeded",
                "current_cost": self.daily_cost,
                "estimated_cost": estimated_cost,
                "max_budget": self.max_daily_cost,
                "would_exceed_by": (self.daily_cost + estimated_cost) - self.max_daily_cost
            }
        
        # Check for alert threshold
        session_percent = (self.session_cost + estimated_cost) / self.max_session_cost * 100
        alert = session_percent >= self.alert_threshold
        
        return {
            "allowed": True,
            "current_session_cost": self.session_cost,
            "estimated_cost": estimated_cost,
            "session_percent": session_percent,
            "alert": alert,
            "alert_message": f"Approaching budget limit: {session_percent:.1f}%" if alert else None
        }
    
    def track_call(self, actual_cost: float, input_tokens: int, output_tokens: int,
                   model: str, duration_ms: float) -> Dict[str, Any]:
        """
        Track an actual API call.
        
        Args:
            actual_cost: Actual cost of the call
            input_tokens: Actual input tokens used
            output_tokens: Actual output tokens used
            model: Model used
            duration_ms: Call duration in milliseconds
            
        Returns:
            Updated tracking statistics
        """
        now = time.time()
        
        # Update costs
        self.session_cost += actual_cost
        self.hourly_cost += actual_cost
        self.daily_cost += actual_cost
        
        # Update call count
        self.session_calls += 1
        self.call_times.append(now)
        
        # Update tokens
        self.session_tokens["input"] += input_tokens
        self.session_tokens["output"] += output_tokens
        
        # Add to history
        call_record = {
            "timestamp": datetime.utcnow().isoformat(),
            "model": model,
            "cost": actual_cost,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "duration_ms": duration_ms
        }
        self.call_history.append(call_record)
        
        # Keep only last 1000 calls
        if len(self.call_history) > 1000:
            self.call_history = self.call_history[-1000:]
        
        # Check for alerts
        session_percent = (self.session_cost / self.max_session_cost) * 100
        if session_percent >= self.alert_threshold and session_percent < self.alert_threshold + 5:
            alert = {
                "timestamp": datetime.utcnow().isoformat(),
                "type": "budget_warning",
                "message": f"⚠️ Budget at {session_percent:.1f}%",
                "session_cost": self.session_cost,
                "session_budget": self.max_session_cost
            }
            self.alerts.append(alert)
            logger.warning(alert["message"])
        
        logger.info(f"💰 Call tracked: ${actual_cost:.4f} (session: ${self.session_cost:.2f})")
        
        return self.get_stats()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get current tracking statistics."""
        session_duration = (datetime.utcnow() - self.session_start).total_seconds()
        avg_cost_per_call = self.session_cost / max(self.session_calls, 1)
        
        # Calculate remaining budget at current rate
        calls_per_hour = (self.session_calls / max(session_duration / 3600, 0.01))
        cost_per_hour = (self.session_cost / max(session_duration / 3600, 0.01))
        remaining_hours = (self.max_session_cost - self.session_cost) / max(cost_per_hour, 0.01)
        
        return {
            "session": {
                "cost": self.session_cost,
                "budget": self.max_session_cost,
                "percent": (self.session_cost / self.max_session_cost) * 100,
                "remaining": self.max_session_cost - self.session_cost,
                "calls": self.session_calls,
                "duration_seconds": session_duration,
                "avg_cost_per_call": avg_cost_per_call
            },
            "hourly": {
                "cost": self.hourly_cost,
                "budget": self.max_hourly_cost,
                "percent": (self.hourly_cost / self.max_hourly_cost) * 100,
                "remaining": self.max_hourly_cost - self.hourly_cost
            },
            "daily": {
                "cost": self.daily_cost,
                "budget": self.max_daily_cost,
                "percent": (self.daily_cost / self.max_daily_cost) * 100,
                "remaining": self.max_daily_cost - self.daily_cost
            },
            "tokens": {
                "input": self.session_tokens["input"],
                "output": self.session_tokens["output"],
                "total": self.session_tokens["input"] + self.session_tokens["output"]
            },
            "rate": {
                "calls_this_minute": len([t for t in self.call_times if t > time.time() - 60]),
                "max_per_minute": self.max_calls_per_minute,
                "calls_per_hour": calls_per_hour,
                "cost_per_hour": cost_per_hour
            },
            "projections": {
                "remaining_hours_at_current_rate": remaining_hours,
                "estimated_total_if_continues": self.session_cost + (cost_per_hour * remaining_hours) if remaining_hours > 0 else self.session_cost
            }
        }
    
    def reset_session(self):
        """Reset session tracking."""
        logger.info(f"💰 Session reset. Final cost: ${self.session_cost:.2f}")
        
        self.session_cost = 0.0
        self.session_calls = 0
        self.session_tokens = {"input": 0, "output": 0}
        self.session_start = datetime.utcnow()
        self.call_times.clear()
        self.call_history.clear()
        self.alerts.clear()
        
        logger.info("💰 New session started")

# Global tracker instance
tracker = CostTracker()

# Flask API endpoints
@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "service": "cost-tracker"})

@app.route('/estimate', methods=['POST'])
def estimate():
    """
    Estimate cost for a prompt.
    
    Body:
        {
            "prompt": "text",
            "model": "claude-opus-4.5",
            "expected_output_tokens": 100
        }
    """
    data = request.get_json()
    prompt = data.get('prompt', '')
    model = data.get('model', 'default')
    expected_output = data.get('expected_output_tokens')
    
    if not prompt:
        return jsonify({"error": "No prompt provided"}), 400
    
    estimate = tracker.estimate_cost(prompt, model, expected_output)
    return jsonify(estimate)

@app.route('/check', methods=['POST'])
def check():
    """
    Check if a call is allowed (rate limit + budget).
    
    Body:
        {
            "prompt": "text",
            "model": "claude-opus-4.5"
        }
    """
    data = request.get_json()
    prompt = data.get('prompt', '')
    model = data.get('model', 'default')
    
    if not prompt:
        return jsonify({"error": "No prompt provided"}), 400
    
    # Estimate cost
    estimate = tracker.estimate_cost(prompt, model)
    
    # Check rate limit
    rate_check = tracker.check_rate_limit()
    if not rate_check["allowed"]:
        return jsonify({
            "allowed": False,
            "reason": "rate_limit",
            "details": rate_check
        })
    
    # Check budget
    budget_check = tracker.check_budget(estimate["total_cost"])
    
    return jsonify({
        "allowed": budget_check["allowed"],
        "estimate": estimate,
        "rate_limit": rate_check,
        "budget": budget_check
    })

@app.route('/track', methods=['POST'])
def track():
    """
    Track an actual API call.
    
    Body:
        {
            "cost": 0.05,
            "input_tokens": 100,
            "output_tokens": 50,
            "model": "claude-opus-4.5",
            "duration_ms": 1500
        }
    """
    data = request.get_json()
    cost = float(data.get('cost', 0))
    input_tokens = int(data.get('input_tokens', 0))
    output_tokens = int(data.get('output_tokens', 0))
    model = data.get('model', 'unknown')
    duration_ms = float(data.get('duration_ms', 0))
    
    stats = tracker.track_call(cost, input_tokens, output_tokens, model, duration_ms)
    return jsonify(stats)

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get current tracking statistics."""
    return jsonify(tracker.get_stats())

@app.route('/history', methods=['GET'])
def get_history():
    """Get call history."""
    limit = int(request.args.get('limit', 100))
    return jsonify({
        "calls": tracker.call_history[-limit:],
        "count": len(tracker.call_history)
    })

@app.route('/alerts', methods=['GET'])
def get_alerts():
    """Get alerts."""
    return jsonify({
        "alerts": tracker.alerts,
        "count": len(tracker.alerts)
    })

@app.route('/reset', methods=['POST'])
def reset():
    """Reset session tracking."""
    tracker.reset_session()
    return jsonify({
        "success": True,
        "message": "Session reset"
    })

@app.route('/pricing', methods=['GET'])
def get_pricing():
    """Get pricing information."""
    return jsonify(PRICING)

if __name__ == '__main__':
    port = int(os.getenv('COST_TRACKER_PORT', 5003))
    logger.info(f"🌐 Starting Cost Tracker API on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
