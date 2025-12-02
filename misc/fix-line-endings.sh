#!/bin/bash
# Fix line endings for all scripts
# Run this if you get "$'\r': command not found" errors

echo "Installing dos2unix..."
sudo apt install dos2unix -y

echo "Converting line endings to Unix format..."
dos2unix setup.sh
dos2unix wifispawn.sh
dos2unix wifispawn-advanced.sh
dos2unix generate_configs.sh
dos2unix server.py

echo "Making scripts executable..."
chmod +x setup.sh wifispawn.sh wifispawn-advanced.sh generate_configs.sh server.py

echo "✓ Line endings fixed!"
echo "You can now run: sudo ./setup.sh"
