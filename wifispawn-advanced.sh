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
INTERNET_INTERFACE=""
PROVIDE_INTERNET="false"
REQUIRE_AUTH="true"
GATEWAY_IP="192.168.4.1"
DHCP_RANGE="192.168.4.2,192.168.4.50"

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
    echo "  -I, --internet IFACE      Internet interface for sharing"
    echo "  -a, --auto-internet       Auto-detect internet interface"
    echo "  -n, --no-auth             Skip authentication for internet access"
    echo "  -c, --captive-only        Captive portal only (no internet)"
    echo "  -h, --help                Show this help"
    echo ""
    echo "Examples:"
    echo "  # Basic captive portal only"
    echo "  $0 -s 'FreeWiFi' -i wlan0"
    echo ""
    echo "  # With internet sharing via eth0"
    echo "  $0 -s 'FreeWiFi' -i wlan0 -I eth0"
    echo ""
    echo "  # Auto-detect internet, no auth required"
    echo "  $0 -s 'Starbucks_WiFi' -i wlan0 -p starbucks -a -n"
    echo ""
    echo "Internet Sharing Modes:"
    echo "  1. Captive Portal Only: Users see portal but no internet"
    echo "  2. Auth Required: Users must enter credentials to get internet"
    echo "  3. Free Access: Portal captures credentials but gives immediate internet"
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
            -I|--internet)
                INTERNET_INTERFACE="$2"
                PROVIDE_INTERNET="true"
                shift 2
                ;;
            -a|--auto-internet)
                AUTO_DETECT="true"
                shift
                ;;
            -n|--no-auth)
                REQUIRE_AUTH="false"
                shift
                ;;
            -c|--captive-only)
                PROVIDE_INTERNET="false"
                INTERNET_INTERFACE=""
                shift
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
    echo -e "    Internet Sharing: $PROVIDE_INTERNET"
    if [[ "$PROVIDE_INTERNET" == "true" ]]; then
        echo -e "    Internet Interface: ${INTERNET_INTERFACE:-auto-detect}"
        echo -e "    Require Auth: $REQUIRE_AUTH"
    fi
    echo ""
    
    # Set environment variables for the main script
    export PROVIDE_INTERNET="$PROVIDE_INTERNET"
    export REQUIRE_AUTH_FOR_INTERNET="$REQUIRE_AUTH"
    
    if [[ -n "$INTERNET_INTERFACE" ]]; then
        # Run main script with specified internet interface
        ./wifispawn.sh "$SSID" "$INTERFACE" "$PAGE_TYPE" "$INTERNET_INTERFACE"
    else
        # Run main script with auto-detection
        ./wifispawn.sh "$SSID" "$INTERFACE" "$PAGE_TYPE"
    fi
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