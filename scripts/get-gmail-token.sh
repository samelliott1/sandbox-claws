#!/bin/bash

# ============================================
# Gmail OAuth Token Helper for Sandbox Claws
# ============================================
# Helps you get OAuth refresh token for Gmail API

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Gmail OAuth Token Helper${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Python 3 is required but not found."
    echo "Please install Python 3 and try again."
    exit 1
fi

echo -e "${YELLOW}This script will help you get OAuth credentials for Gmail API.${NC}"
echo ""
echo "Prerequisites:"
echo "  1. ✅ You have a test Gmail account"
echo "  2. ✅ You've enabled Gmail API in Google Cloud Console"
echo "  3. ✅ You've created OAuth 2.0 credentials (Desktop app)"
echo ""
echo "If you haven't done these steps, see: docs/TESTING_GUIDE.md"
echo ""

read -p "Press Enter to continue or Ctrl+C to exit..."

# Prompt for Client ID and Secret
echo ""
echo -e "${BLUE}Enter your OAuth credentials:${NC}"
echo ""
read -p "Client ID: " CLIENT_ID
read -p "Client Secret: " CLIENT_SECRET

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo -e "${RED}[ERROR]${NC} Client ID and Secret cannot be empty."
    exit 1
fi

# Create temporary Python script
cat > /tmp/gmail_token_helper.py << 'PYTHON_SCRIPT'
import json
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

CLIENT_ID = sys.argv[1]
CLIENT_SECRET = sys.argv[2]
REDIRECT_URI = "http://localhost:8090"
SCOPES = "https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/calendar"

auth_code = None

class OAuthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global auth_code
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        
        if 'code' in query:
            auth_code = query['code'][0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"""
            <html>
            <body style="font-family: Arial; text-align: center; padding: 50px;">
                <h1 style="color: green;">✅ Authorization Successful!</h1>
                <p>You can close this window and return to your terminal.</p>
            </body>
            </html>
            """)
        else:
            self.send_response(400)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Suppress HTTP server logs

# Build authorization URL
auth_url = (
    f"https://accounts.google.com/o/oauth2/v2/auth?"
    f"client_id={CLIENT_ID}&"
    f"redirect_uri={urllib.parse.quote(REDIRECT_URI)}&"
    f"response_type=code&"
    f"scope={urllib.parse.quote(SCOPES)}&"
    f"access_type=offline&"
    f"prompt=consent"
)

print("\n" + "="*50)
print("Opening browser for authorization...")
print("="*50 + "\n")

# Open browser
webbrowser.open(auth_url)

# Start local server to receive callback
server = HTTPServer(('localhost', 8090), OAuthHandler)
print("Waiting for authorization...")
server.handle_request()
server.server_close()

if not auth_code:
    print("\n❌ Authorization failed. No code received.")
    sys.exit(1)

print("\n✅ Authorization code received!")
print("Exchanging code for refresh token...\n")

# Exchange code for tokens
token_data = urllib.parse.urlencode({
    'code': auth_code,
    'client_id': CLIENT_ID,
    'client_secret': CLIENT_SECRET,
    'redirect_uri': REDIRECT_URI,
    'grant_type': 'authorization_code'
}).encode()

token_request = urllib.request.Request(
    'https://oauth2.googleapis.com/token',
    data=token_data,
    headers={'Content-Type': 'application/x-www-form-urlencoded'}
)

try:
    with urllib.request.urlopen(token_request) as response:
        tokens = json.loads(response.read())
        
    if 'refresh_token' in tokens:
        print("="*50)
        print("🎉 SUCCESS! Here are your credentials:")
        print("="*50)
        print(f"\nGMAIL_CLIENT_ID={CLIENT_ID}")
        print(f"GMAIL_CLIENT_SECRET={CLIENT_SECRET}")
        print(f"GMAIL_REFRESH_TOKEN={tokens['refresh_token']}")
        print(f"\nGOOGLE_CALENDAR_CLIENT_ID={CLIENT_ID}")
        print(f"GOOGLE_CALENDAR_CLIENT_SECRET={CLIENT_SECRET}")
        print(f"GOOGLE_CALENDAR_REFRESH_TOKEN={tokens['refresh_token']}")
        print("\n" + "="*50)
        print("\n💾 Copy these to your .env.openclaw file")
        print("="*50 + "\n")
    else:
        print("\n❌ No refresh token received. Make sure you:")
        print("   1. Selected 'Desktop app' when creating OAuth credentials")
        print("   2. Granted all requested permissions")
        print("   3. Haven't previously authorized this app (revoke and try again)")
        sys.exit(1)
        
except Exception as e:
    print(f"\n❌ Error exchanging code for token: {e}")
    sys.exit(1)
PYTHON_SCRIPT

# Run Python script
echo ""
echo -e "${BLUE}Starting OAuth flow...${NC}"
echo ""

python3 /tmp/gmail_token_helper.py "$CLIENT_ID" "$CLIENT_SECRET"
RESULT=$?

# Clean up
rm /tmp/gmail_token_helper.py

if [ $RESULT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Tokens generated successfully!"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Copy the credentials above to .env.openclaw"
    echo "  2. Save the file"
    echo "  3. Restart OpenClaw: docker compose restart openclaw"
    echo "  4. Start testing!"
    echo ""
else
    echo ""
    echo -e "${RED}[ERROR]${NC} Token generation failed."
    echo "See docs/TESTING_GUIDE.md for detailed setup instructions."
    echo ""
    exit 1
fi
