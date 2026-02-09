#!/bin/bash
set -e

echo "========================================="
echo "Cleaning up system before image capture"
echo "========================================="

# Clean package manager cache
echo "Cleaning package manager cache..."
sudo apt-get clean
sudo apt-get autoremove -y

# Remove package lists (will be refreshed on first boot)
echo "Removing package lists..."
sudo rm -rf /var/lib/apt/lists/*

# Clean up log files
echo "Cleaning up log files..."
sudo find /var/log -type f -exec truncate -s 0 {} \;
sudo rm -rf /var/log/*.gz
sudo rm -rf /var/log/*.[0-9]

# Remove temporary files
echo "Removing temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clean up bash history
echo "Cleaning up bash history..."
cat /dev/null > ~/.bash_history
history -c

# Remove SSH host keys (will be regenerated on first boot)
echo "Removing SSH host keys..."
sudo rm -f /etc/ssh/ssh_host_*

# Clean up cloud-init
echo "Cleaning up cloud-init..."
sudo cloud-init clean --logs --seed

# Remove machine-id (will be regenerated)
echo "Truncating machine-id..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Sync filesystem
echo "Syncing filesystem..."
sync

echo ""
echo "========================================="
echo "Cleanup completed!"
echo "========================================="
