#!/bin/bash

# WiFi Spawn Advanced - With Internet Sharing Options
# Usage: sudo ./wifispawn-advanced.sh [options]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
SSID="FreeWiFi"
INTERFACE="wlan0"
PAGE_TYPE="portal"
GATEWAY_IP="192.168.4.1"
DHCP_RANGE="192.168.4.2,192.168.4.50"

# Internet sharing DISABLED (single antenna mode)
INTERNET_INTERFACE=""
PROVIDE_INTERNET="false"
REQUIRE_AUTH="false"

print_banner() {
    echo -e "${GREEN}"
    echo "██╗    ██╗██╗███████╗██╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗"
    echo "██║    ██║██║██╔════╝██║██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║"
    echo "██║ █╗ ██║██║█████╗  ██║███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║"
    echo "██║███╗██║██║██╔══╝  ██║╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║"
    echo "╚███╔███╔╝██║██║     ██║███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║"
    echo " ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Advanced WiFi Spawn with Internet Sharing${NC}"
    echo "=============================================="
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -s, --ssid SSID           WiFi network name"
    echo "  -i, --interface IFACE     WiFi interface (e.g., wlan0)"
    echo ""
    echo "Optional:"
    echo "  -p, --page PAGE           Portal page (portal/starbucks/hotel/airport)"
    echo "  -h, --help                Show this help"
    echo ""
    echo "Examples:"
    echo "  # Basic captive portal (credentials capture only)"
    echo "  $0 -s 'FreeWiFi' -i wlan0"
    echo ""
    echo "  # With custom portal page"
    echo "  $0 -s 'Starbucks_WiFi' -i wlan0 -p starbucks"
    echo ""
    echo "Note: This version is for single antenna mode (no internet sharing)"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--ssid)
                SSID="$2"
                shift 2
                ;;
            -i|--interface)
                INTERFACE="$2"
                shift 2
                ;;
            -p|--page)
                PAGE_TYPE="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$SSID" || -z "$INTERFACE" ]]; then
        echo -e "${RED}Error: SSID and interface are required${NC}"
        print_usage
        exit 1
    fi
}

run_wifispawn() {
    echo -e "${BLUE}[+] Starting WiFi Spawn with configuration:${NC}"
    echo -e "    SSID: $SSID"
    echo -e "    Interface: $INTERFACE"
    echo -e "    Page: $PAGE_TYPE"
    echo -e "    Mode: Captive Portal Only (No Internet)"
    echo ""
    
    # Run main script (internet sharing disabled by default)
    ./wifispawn.sh "$SSID" "$INTERFACE" "$PAGE_TYPE"
}

main() {
    print_banner
    
    if [[ $# -eq 0 ]]; then
        print_usage
        exit 0
    fi
    
    parse_arguments "$@"
    run_wifispawn
}

main "$@"