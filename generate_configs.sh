#!/bin/bash

# Generate configuration files for WiFi Spawn
# Usage: ./generate_configs.sh <SSID> <INTERFACE> <GATEWAY_IP> <DHCP_RANGE>

SSID="$1"
INTERFACE="$2" 
GATEWAY_IP="$3"
DHCP_RANGE="$4"

WORK_DIR="/tmp/wifispawn"
WEB_DIR="$WORK_DIR/www"

# Generate hostapd.conf
cat > "$WORK_DIR/hostapd.conf" << EOF
interface=$INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Generate dnsmasq.conf
cat > "$WORK_DIR/dnsmasq.conf" << EOF
interface=$INTERFACE
dhcp-range=$DHCP_RANGE,12h
dhcp-option=3,$GATEWAY_IP
dhcp-option=6,$GATEWAY_IP
server=$GATEWAY_IP
log-queries
log-dhcp
address=/#/$GATEWAY_IP
EOF

# Generate nginx configuration
cat > "$WORK_DIR/nginx.conf" << EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80 default_server;
        server_name _;
        root $WEB_DIR;
        index portal.html;
        
        # Captive portal detection endpoints
        location /generate_204 {
            return 302 http://$GATEWAY_IP/portal;
        }
        
        location /hotspot-detect.html {
            return 302 http://$GATEWAY_IP/portal;
        }
        
        location /connecttest.txt {
            return 302 http://$GATEWAY_IP/portal;
        }
        
        location /ncsi.txt {
            return 302 http://$GATEWAY_IP/portal;
        }
        
        # Main portal routes
        location / {
            try_files \$uri \$uri/ /portal.html;
        }
        
        location /portal {
            try_files /portal.html =404;
        }
        
        # Handle form submissions
        location /submit {
            proxy_pass http://$GATEWAY_IP:8080/submit;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }
}
EOF

echo "Configuration files generated successfully!"