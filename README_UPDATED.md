# WiFiSpawn - Fake Access Point with Captive Portal

**Optimized for Kali Linux with Alfa AWUS036AXML (Single Antenna Mode)**

A professional WiFi captive portal framework for penetration testing and security research. This version is designed for **single antenna mode** - it creates a fake access point and captures credentials but does **NOT** provide internet access to connected users.

## ⚠️ Legal Disclaimer

This tool is for **educational purposes and authorized penetration testing only**. Only use on networks you own or have explicit written permission to test. Unauthorized use may be illegal in your jurisdiction.

## Features

- ✅ Creates fake WiFi access point
- ✅ Professional captive portal pages (Starbucks, Airport, Hotel, Generic)
- ✅ Credential capture and logging
- ✅ Automatic traffic redirection to portal
- ✅ Optimized for Kali Linux
- ✅ Single antenna mode (no internet sharing)
- ✅ Clean credential logging (text + JSON)

## Requirements

- **Kali Linux** (or Debian-based distro)
- **Alfa AWUS036AXML** (or compatible WiFi adapter with AP mode)
- Root privileges

## Installation

1. **Clone or download this repository**
2. **Run the setup script:**

```bash
sudo ./setup.sh
```

This will:
- Install required dependencies (hostapd, dnsmasq, aircrack-ng, etc.)
- Configure system services
- Set up scripts
- Detect your wireless adapter

## Quick Start

### 1. Check your wireless interface

```bash
iwconfig
```

Look for your Alfa adapter (usually `wlan0` or `wlan1`)

### 2. List available portal pages

```bash
sudo ./wifispawn.sh --list-pages
```

### 3. Start the fake access point

```bash
sudo ./wifispawn.sh "FreeWiFi" wlan0
```

Or with a specific portal page:

```bash
sudo ./wifispawn.sh "Starbucks WiFi" wlan0 starbucks
```

### 4. Monitor captured credentials

Credentials are logged in real-time to:
- `/tmp/wifispawn/logs/credentials.log` (plain text)
- `/tmp/wifispawn/logs/credentials.json` (JSON format)

### 5. Stop the attack

Press `Ctrl+C` to stop and cleanup automatically.

## Usage

### Basic Usage

```bash
sudo ./wifispawn.sh <SSID> <INTERFACE> [PAGE]
```

**Parameters:**
- `SSID`: WiFi network name (e.g., "Free WiFi")
- `INTERFACE`: Your wireless interface (e.g., wlan0)
- `PAGE`: Portal page type (optional, default: portal)

### Available Portal Pages

- `portal` - Generic WiFi login portal
- `starbucks` - Starbucks-themed portal
- `airport` - Airport WiFi portal
- `hotel` - Hotel WiFi portal

### Examples

```bash
# Generic portal
sudo ./wifispawn.sh "Free WiFi" wlan0

# Starbucks portal
sudo ./wifispawn.sh "Starbucks WiFi" wlan0 starbucks

# Airport portal
sudo ./wifispawn.sh "Airport_Free_WiFi" wlan0 airport

# Hotel portal  
sudo ./wifispawn.sh "Hotel Guest WiFi" wlan0 hotel
```

## How It Works

1. **Setup Phase:**
   - Kills interfering processes (NetworkManager, wpa_supplicant)
   - Configures wireless adapter in AP mode
   - Starts hostapd (access point)
   - Starts dnsmasq (DHCP + DNS)

2. **Traffic Redirection:**
   - All HTTP/HTTPS traffic redirected to captive portal
   - DNS requests return gateway IP for all domains
   - iptables rules prevent internet access

3. **Credential Capture:**
   - Users connect to fake AP
   - Browser shows captive portal
   - Users enter credentials (captured and logged)
   - Portal shows "success" but no internet provided

4. **Cleanup:**
   - Ctrl+C stops all services
   - Restores iptables rules
   - Resets wireless interface

## File Structure

```
WifiSpawn/
├── wifispawn.sh              # Main script
├── wifispawn-advanced.sh     # Advanced options wrapper
├── setup.sh                  # Installation script
├── generate_configs.sh       # Config file generator
├── server.py                 # Credentials capture server
├── README.md                 # This file
└── pages/                    # Portal HTML pages
    ├── portal.html           # Generic portal
    ├── starbucks.html        # Starbucks theme
    ├── airport.html          # Airport theme
    └── hotel.html            # Hotel theme
```

## Troubleshooting

### Interface not found
```bash
# Check available interfaces
iwconfig

# Check if adapter is recognized
lsusb | grep -i alfa
```

### hostapd fails to start
```bash
# Kill interfering processes
sudo airmon-ng check kill

# Try manual interface reset
sudo ip link set wlan0 down
sudo iw dev wlan0 set type managed
sudo ip link set wlan0 up
```

### No clients connecting
- Ensure adapter supports AP mode
- Check channel 6 isn't too congested
- Verify hostapd is running: `ps aux | grep hostapd`

### Credentials not being captured
- Check server is running: `ps aux | grep python3`
- Check logs: `tail -f /tmp/wifispawn/logs/server.log`
- Verify iptables rules: `sudo iptables -t nat -L`

## Important Notes

### Single Antenna Mode

This version is configured for **single antenna operation**:
- ❌ Does NOT provide internet to users
- ❌ Cannot share internet connection
- ✅ Captures credentials only
- ✅ Shows realistic portal pages
- ✅ Simulates authentication success

If users complain about "no internet after login", this is expected behavior.

### Alfa AWUS036AXML Compatibility

The Alfa AWUS036AXML is fully supported in Kali Linux:
- Chipset: MediaTek MT7921AU
- Driver: Built into kernel
- AP Mode: ✅ Supported
- Monitor Mode: ✅ Supported

### Differences from Multi-Antenna Setup

Multi-antenna setups can:
- Share internet from eth0/wlan1 to fake AP clients
- Provide authenticated internet access
- Act as real working hotspot

This single-antenna version:
- Only captures credentials
- Does not provide internet
- Requires only one wireless adapter

## Security Research Use Cases

- Testing user awareness of fake hotspots
- Demonstrating social engineering attacks
- Training exercises for security teams
- Red team operations (with authorization)

## Credits

- Original concept inspired by WiFi Pineapple
- Portal pages: Custom designed for realism
- Testing platform: Kali Linux

## License

For educational and authorized security testing only.

## Support

Having issues? Check:
1. Ran `sudo ./setup.sh`?
2. Running as root (`sudo`)?
3. Wireless adapter connected and detected?
4. Kali Linux up to date?

---

**Remember:** Only use on networks you own or have explicit permission to test!
