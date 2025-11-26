# Available Portal Pages

This directory contains different captive portal page templates that you can use with WiFi Spawn.

## Available Pages:

### 1. `portal.html` (Default)
- **Style**: Generic WiFi portal
- **Theme**: Blue/Purple gradient
- **Use case**: General purpose fake WiFi access
- **Fields**: Username/Email, Password

### 2. `starbucks.html`
- **Style**: Starbucks-themed portal
- **Theme**: Green Starbucks branding
- **Use case**: Coffee shop WiFi simulation
- **Fields**: Email, Password

### 3. `hotel.html`
- **Style**: Luxury hotel portal
- **Theme**: Gold/Dark elegant design
- **Use case**: Hotel WiFi access simulation
- **Fields**: Room Number/Email, Last Name/Access Code

### 4. `airport.html`
- **Style**: Airport WiFi portal
- **Theme**: Blue aviation theme
- **Use case**: Airport/travel WiFi simulation
- **Fields**: Email/Frequent Flyer Number, Password/Last Name

## Usage Examples:

```bash
# Use default portal page
sudo ./wifispawn.sh "FreeWiFi" wlan0

# Use specific page
sudo ./wifispawn.sh "FreeWiFi" wlan0 portal
sudo ./wifispawn.sh "Starbucks_WiFi" wlan0 starbucks
sudo ./wifispawn.sh "Hotel_Guest" wlan0 hotel
sudo ./wifispawn.sh "Airport_WiFi" wlan0 airport

# List available pages
sudo ./wifispawn.sh --list-pages
```

## Creating Custom Pages:

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

## Template Structure:

Each portal page should include:
- Responsive design for mobile devices
- Professional appearance matching the target environment
- Form validation and loading states
- Proper error handling
- Realistic branding and styling

The form data will be automatically captured and logged by the WiFi Spawn system.