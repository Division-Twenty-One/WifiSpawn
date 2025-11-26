#!/bin/bash

# WiFi Spawn Setup Script
# Installs dependencies and prepares the system for fake AP operations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "██╗    ██╗██╗███████╗██╗███████╗██████╗  █████╗ ██╗    ██╗███╗   ██╗"
    echo "██║    ██║██║██╔════╝██║██╔════╝██╔══██╗██╔══██╗██║    ██║████╗  ██║"
    echo "██║ █╗ ██║██║█████╗  ██║███████╗██████╔╝███████║██║ █╗ ██║██╔██╗ ██║"
    echo "██║███╗██║██║██╔══╝  ██║╚════██║██╔═══╝ ██╔══██║██║███╗██║██║╚██╗██║"
    echo "╚███╔███╔╝██║██║     ██║███████║██║     ██║  ██║╚███╔███╔╝██║ ╚████║"
    echo " ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Setup & Installation Script${NC}"
    echo "============================"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        echo "Usage: sudo ./setup.sh"
        exit 1
    fi
}

check_kali() {
    echo -e "${YELLOW}[+] Checking if running on Kali Linux...${NC}"
    
    if ! grep -q "Kali" /etc/os-release 2>/dev/null; then
        echo -e "${YELLOW}Warning: Not detected as Kali Linux${NC}"
        echo -e "${YELLOW}This script is optimized for Kali, but may work on other Debian-based systems${NC}"
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}[+] Kali Linux detected${NC}"
    fi
}

update_system() {
    echo -e "${YELLOW}[+] Updating package lists...${NC}"
    apt update -q
    echo -e "${GREEN}[+] Package lists updated${NC}"
}

install_dependencies() {
    echo -e "${YELLOW}[+] Installing required packages...${NC}"
    
    local packages=(
        "hostapd"
        "dnsmasq" 
        "iptables"
        "aircrack-ng"
        "python3"
        "python3-pip"
        "net-tools"
        "iproute2"
        "wireless-tools"
        "iw"
    )
    
    for package in "${packages[@]}"; do
        echo -e "${BLUE}Installing $package...${NC}"
        apt install -y "$package" || {
            echo -e "${RED}Failed to install $package${NC}"
            exit 1
        }
    done
    
    echo -e "${GREEN}[+] All packages installed successfully${NC}"
}

check_wireless_interface() {
    echo -e "${YELLOW}[+] Checking wireless interfaces...${NC}"
    
    # Check for wireless interfaces
    if ! iwconfig 2>/dev/null | grep -q "IEEE 802.11"; then
        echo -e "${RED}No wireless interfaces found!${NC}"
        echo -e "${RED}Please ensure your AWUS036AXML is connected${NC}"
        exit 1
    fi
    
    # List available interfaces
    echo -e "${GREEN}[+] Available wireless interfaces:${NC}"
    iwconfig 2>/dev/null | grep "IEEE 802.11" -B 1 | grep -o "^[a-z0-9]*" | while read -r iface; do
        echo -e "${GREEN}  - $iface${NC}"
        # if mediatek, patch drivers
        if iwconfig "$iface" 2>/dev/null | grep -q "MT7961"; then
            echo -e "${YELLOW}Patching drivers for MT7961 on interface $iface...${NC}"
            sudo bash ./patches.sh
            echo -e "${GREEN}Driver patches applied for $iface${NC}"
        fi
    done
    
    echo -e "${BLUE}Note: Use the interface name with wifispawn.sh${NC}"
}

setup_directories() {
    echo -e "${YELLOW}[+] Setting up directories...${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Make scripts executable
    chmod +x "$script_dir/wifispawn.sh"
    chmod +x "$script_dir/generate_configs.sh"
    chmod +x "$script_dir/server.py"
    
    # Create symlinks in /usr/local/bin for easy access
    ln -sf "$script_dir/wifispawn.sh" /usr/local/bin/wifispawn
    
    echo -e "${GREEN}[+] Scripts configured and made executable${NC}"
    echo -e "${GREEN}[+] You can now run 'sudo wifispawn' from anywhere${NC}"
}

configure_services() {
    echo -e "${YELLOW}[+] Configuring services...${NC}"
    
    # Stop NetworkManager temporarily (airmon-ng will handle this)
    systemctl stop NetworkManager 2>/dev/null || true
    
    # Stop wpa_supplicant
    systemctl stop wpa_supplicant 2>/dev/null || true
    
    echo -e "${GREEN}[+] Services configured${NC}"
    echo -e "${YELLOW}Note: NetworkManager will be stopped by airmon-ng when needed${NC}"
}

create_sample_files() {
    echo -e "${YELLOW}[+] Creating sample files...${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy portal pages to a safe location
    mkdir -p /opt/wifispawn/pages
    if [[ -d "$script_dir/pages" ]]; then
        cp -r "$script_dir/pages"/* /opt/wifispawn/pages/ 2>/dev/null || true
        echo -e "${GREEN}[+] Portal pages copied to /opt/wifispawn/pages/${NC}"
    fi
    
    # Copy server.py and generate_configs.sh
    if [[ -f "$script_dir/server.py" ]]; then
        cp "$script_dir/server.py" /opt/wifispawn/server.py
        echo -e "${GREEN}[+] server.py copied to /opt/wifispawn/${NC}"
    fi
    
    if [[ -f "$script_dir/generate_configs.sh" ]]; then
        cp "$script_dir/generate_configs.sh" /opt/wifispawn/generate_configs.sh
        chmod +x /opt/wifispawn/generate_configs.sh
        echo -e "${GREEN}[+] generate_configs.sh copied to /opt/wifispawn/${NC}"
    fi
    
    # Create example usage file
    cat > "$script_dir/USAGE.md" << 'EOF'
# WiFi Spawn Usage

## Quick Start

1. **Connect your AWUS036AXML adapter**
2. **Run the setup script (first time only):**
   ```bash
   sudo ./setup.sh
   ```

3. **Start the fake access point:**
   ```bash
   sudo wifispawn "FreeWiFi" wlan0
   ```

## Commands

- **Basic usage:**
  ```bash
  sudo wifispawn [SSID] [INTERFACE]
  ```

- **Example with custom SSID:**
  ```bash
  sudo wifispawn "Starbucks_WiFi" wlan0
  ```

- **Check available interfaces:**
  ```bash
  iwconfig
  ```

## Features

- Creates fake WiFi access point
- Captive portal with custom login page
- Logs all credentials to `/tmp/wifispawn/logs/`
- Redirects all traffic to captive portal
- Professional-looking login interface

## Files Created

- `/tmp/wifispawn/logs/credentials.log` - Plain text log
- `/tmp/wifispawn/logs/credentials.json` - JSON formatted log
- `/tmp/wifispawn/logs/server.log` - Server debug log

## Stopping

Press `Ctrl+C` to stop the fake access point and clean up automatically.

## Legal Notice

This tool is for educational and authorized penetration testing purposes only.
Ensure you have explicit permission before testing on any network.
EOF

    echo -e "${GREEN}[+] Sample files created${NC}"
}

run_tests() {
    echo -e "${YELLOW}[+] Running basic tests...${NC}"
    
    # Test Python
    if ! python3 -c "import http.server, json, threading" 2>/dev/null; then
        echo -e "${RED}Python dependencies missing${NC}"
        exit 1
    fi
    
    # Test hostapd
    if ! which hostapd >/dev/null; then
        echo -e "${RED}hostapd not found${NC}"
        exit 1
    fi
    
    # Test dnsmasq
    if ! which dnsmasq >/dev/null; then
        echo -e "${RED}dnsmasq not found${NC}"
        exit 1
    fi
    
    # Test aircrack-ng tools
    if ! which airmon-ng >/dev/null; then
        echo -e "${RED}airmon-ng not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] All tests passed${NC}"
}

show_summary() {
    echo -e "\n${GREEN}===========================================${NC}"
    echo -e "${GREEN}         WiFi Spawn Setup Complete!        ${NC}"
    echo -e "${GREEN}===========================================${NC}"
    echo ""
    echo -e "${YELLOW}Usage Examples:${NC}"
    echo -e "  sudo wifispawn 'FreeWiFi' wlan0"
    echo -e "  sudo wifispawn 'Starbucks_WiFi' wlan0 starbucks"
    echo -e "  sudo wifispawn --list-pages"
    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo -e "  ${RED}• Single antenna mode - NO internet access provided${NC}"
    echo -e "  ${RED}• Credentials are captured but users won't get WiFi${NC}"
    echo -e "  ${YELLOW}• Optimized for Kali Linux with Alfa AWUS036AXML${NC}"
    echo ""
    echo -e "${YELLOW}Files:${NC}"
    echo -e "  📄 Main script: ./wifispawn.sh"
    echo -e "  📁 Portal pages: ./pages/ (portal, starbucks, hotel, airport)"
    echo -e "  🖥️  Server: ./server.py"
    echo -e "  ⚙️  Config generator: ./generate_configs.sh"
    echo -e "  📖 Usage guide: ./USAGE.md"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Connect your Alfa AWUS036AXML adapter"
    echo -e "  2. Check interface name: ${BLUE}iwconfig${NC}"
    echo -e "  3. List portal pages: ${BLUE}sudo wifispawn --list-pages${NC}"
    echo -e "  4. Run: ${BLUE}sudo wifispawn 'YourSSID' wlan0 [page]${NC}"
    echo ""
    echo -e "${RED}Legal Reminder:${NC}"
    echo -e "  Only use on networks you own or have explicit permission to test!"
    echo ""
}

main() {
    print_banner
    check_root
    check_kali
    update_system
    install_dependencies
    check_wireless_interface
    setup_directories
    configure_services
    create_sample_files
    run_tests
    show_summary
}

main "$@"