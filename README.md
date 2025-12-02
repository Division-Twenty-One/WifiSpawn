
# 🎯 WifiSpawn

**Advanced Fake Access Point Framework with Captive Portal**  
Professional-grade WiFi penetration testing tool for credential harvesting and social engineering assessments

## **Requirements**

### **Hardware**
- **Wireless Adapter**: Must support **monitor mode** and **AP mode**
  - ✅ Recommended: **Alfa AWUS036AXML** (MT7961 chipset)
  - ✅ Alfa AWUS036ACH, AWUS036AC
  - ✅ TP-Link TL-WN722N v1/v2
  - ℹ️ You can use the built-in antenna on Raspberry Pi 4 or newer.

### **Operating System**
- **Kali Linux** : Tested on 2025.3
- Root/sudo access required

### **Dependencies**
- `hostapd` - Access Point daemon
- `dnsmasq` - DNS/DHCP server
- `aircrack-ng` - Wireless tools (airmon-ng)
- `python3` - Web server and credential logging
- `iptables` - Traffic redirection
- `iw` - Wireless configuration

## **Installation**

Install WifiSpawn on Kali

```bash
  git clone https://github.com/Division-Twenty-One/WifiSpawn/
  cd WifiSpawn
  sudo ./setup.sh
```
## **Usage**

### **Basic Syntax**
```bash
sudo wifispawn <SSID> <INTERFACE> [PAGE]
```

### **Quick Start**
```bash
# 1. Check your wireless interface
iwconfig

# 2. List available portal pages
sudo wifispawn --list-pages

# 3. Launch fake google access point
sudo wifispawn "Free_WiFi" wlan0 google
```


**Default Portal Page**
```bash
sudo wifispawn "Public_WiFi" wlan0
```

### **Command Options**
| Option | Description |
|--------|-------------|
| `-h, --help` | Display help and usage examples |
| `-l, --list-pages` | List all available portal templates |

### **Monitoring Credentials**
Captured credentials are logged in real-time to:
```
/tmp/wifispawn/logs/credentials.log
```

Format: `timestamp | client_ip | username | password | user_agent`

### **Stopping the Attack**
Press `Ctrl+C` to cleanly shutdown services and restore network settings.


## **Available Pages**:

- **Portal** (**default**)
- **Hotel** (hotel)
- **Airport** (airport)
- **Google Login** (google)


## **Creating Custom Pages**:

To create a new portal page:

1. Create a new HTML file in this directory (e.g., `custom.html`)
2. Include the required form elements:
   - Form with `action="/submit"` and `method="POST"`
   - Username field with `name="username"`
   - Password field with `name="password"`
   - JavaScript to handle form submission via fetch API

3. Use the page:
   ```bash
   sudo ./wifispawn.sh "CustomSSID" wlan0 custom
   ```

