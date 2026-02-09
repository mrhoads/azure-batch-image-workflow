#!/bin/bash
set -e

echo "========================================="
echo "System Hardening and Security Configuration"
echo "========================================="

# Configure automatic security updates
echo "Configuring automatic security updates..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure firewall (UFW)
echo "Configuring firewall..."
sudo apt-get install -y ufw
# Allow SSH (important for Azure)
sudo ufw allow 22/tcp
# Note: UFW is installed but not enabled by default to avoid issues with Azure networking
echo "UFW installed but not enabled (Azure manages network security)"

# Disable unnecessary services
echo "Disabling unnecessary services..."
# Check if services exist before disabling to avoid silent failures
if sudo systemctl list-units --full --all | grep -q snapd.service; then
  echo "Disabling snapd.service..."
  sudo systemctl disable --now snapd.service
else
  echo "snapd.service not found, skipping"
fi

if sudo systemctl list-units --full --all | grep -q snapd.socket; then
  echo "Disabling snapd.socket..."
  sudo systemctl disable --now snapd.socket
else
  echo "snapd.socket not found, skipping"
fi

# Set secure permissions
echo "Setting secure permissions on system files..."
sudo chmod 600 /etc/ssh/sshd_config

# Configure sysctl for security
echo "Applying security-related sysctl settings..."
sudo tee /etc/sysctl.d/99-security.conf > /dev/null <<EOF
# IP Forwarding
net.ipv4.ip_forward = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Enable TCP SYN Cookie Protection
net.ipv4.tcp_syncookies = 1

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1

# Log Martians
net.ipv4.conf.all.log_martians = 1
EOF

sudo sysctl -p /etc/sysctl.d/99-security.conf

# Configure SSH hardening (preserve Azure requirements)
echo "Hardening SSH configuration..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Apply hardening while maintaining Azure compatibility
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config
sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config

echo ""
echo "========================================="
echo "System hardening completed!"
echo "========================================="
