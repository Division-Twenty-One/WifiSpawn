# WiFi Spawn 🔥

A professional fake access point toolkit for penetration testing and security research using the AWUS036AXML adapter on Kali Linux.

## ⚡ Features

- **Multiple Portal Pages**: Choose from different themed portals (Generic, Starbucks, Hotel, Airport)
- **Fake Access Point**: Creates convincing WiFi hotspots with custom SSIDs
- **Captive Portal**: Professional-looking login pages that capture credentials
- **Traffic Redirection**: Automatically redirects all traffic to the captive portal
- **Credential Logging**: Logs captured credentials in multiple formats
- **Easy Setup**: One-command installation and deployment
- **AWUS036AXML Optimized**: Specifically designed for this popular adapter

## 🚀 Quick Start

### 1. Setup (First Time Only)
```bash
git clone <this-repo>
cd WifiSpawn
sudo ./setup.sh
```

### 2. Run the Attack
```bash
# Basic usage (default portal)
sudo ./wifispawn.sh "FreeWiFi" wlan0

# With specific portal page
sudo ./wifispawn.sh "Starbucks_WiFi" wlan0 starbucks
sudo ./wifispawn.sh "Hotel_Guest" wlan0 hotel
sudo ./wifispawn.sh "Airport_WiFi" wlan0 airport

# List available portal pages
sudo ./wifispawn.sh --list-pages
```

### 3. Monitor Credentials
The script will display captured credentials in real-time. Press `Ctrl+C` to stop.

## 📋 Requirements

- **Hardware**: AWUS036AXML WiFi adapter (or compatible)
- **OS**: Kali Linux (recommended) or Debian-based system
- **Privileges**: Root access required

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `wifispawn.sh` | Main script that orchestrates the fake AP |
| `setup.sh` | Installation and dependency setup |
| `generate_configs.sh` | Generates hostapd and dnsmasq configs |
| `pages/` | Directory containing portal page templates |
| `server.py` | Python server for handling credentials |

## 🎨 Available Portal Pages

| Page | Theme | Best For | Preview |
|------|-------|----------|---------|
| `portal` | Generic WiFi | General use | Blue/purple gradient design |
| `starbucks` | Coffee shop | Starbucks WiFi simulation | Green Starbucks-style branding |
| `hotel` | Luxury hotel | Hotel guest WiFi | Gold/dark elegant design |
| `airport` | Airport/travel | Airport WiFi simulation | Blue aviation theme |

**Usage**: `sudo ./wifispawn.sh "SSID" wlan0 [page_name]`

## 🔧 How It Works

1. **Access Point Creation**: Uses `hostapd` to create a fake WiFi access point
2. **DHCP/DNS Services**: Uses `dnsmasq` to assign IPs and redirect DNS
3. **Traffic Interception**: Uses `iptables` to redirect all HTTP/HTTPS traffic
4. **Captive Portal**: Serves selected themed login page via nginx
5. **Credential Capture**: Python server logs all submitted credentials

## 📊 Output Files

All logs are saved to `/tmp/wifispawn/logs/`:
- `credentials.log` - Plain text format
- `credentials.json` - JSON format for parsing
- `server.log` - Debug information

## ⚙️ Configuration

The script automatically configures:
- **Gateway IP**: `192.168.4.1`
- **DHCP Range**: `192.168.4.2-192.168.4.50`
- **Web Server**: Port 80 (nginx)
- **Credentials Server**: Port 8080 (Python)

## 🛡️ Legal & Ethical Use

**⚠️ IMPORTANT LEGAL NOTICE ⚠️**

This tool is provided for educational purposes and authorized penetration testing only. 

**You MUST:**
- Have explicit written permission before testing any network
- Only use on networks you own or are authorized to test
- Comply with all local, state, and federal laws
- Use responsibly and ethically

**Unauthorized use of this tool may violate:**
- Computer Fraud and Abuse Act (CFAA)
- Local cybersecurity laws
- Terms of service agreements

The authors are not responsible for any misuse or illegal activities.

## 🔍 Troubleshooting

### Common Issues

1. **No wireless interfaces found**
   ```bash
   # Check if adapter is recognized
   lsusb | grep -i wireless
   iwconfig
   ```

2. **Permission denied errors**
   ```bash
   # Ensure running as root
   sudo ./wifispawn.sh
   ```

3. **Port already in use**
   ```bash
   # Kill conflicting processes
   sudo pkill hostapd
   sudo pkill dnsmasq
   sudo systemctl stop nginx
   ```

4. **Interface busy**
   ```bash
   # Stop NetworkManager
   sudo systemctl stop NetworkManager
   # Or put interface in monitor mode first
   sudo airmon-ng start wlan0
   ```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided for educational purposes. Use responsibly and in accordance with applicable laws.

---

**Remember**: With great power comes great responsibility. Use this tool ethically! 🕷️
