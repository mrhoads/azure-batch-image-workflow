#!/bin/bash
set -e

echo "========================================="
echo "Installing stress and fio applications"
echo "========================================="

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install stress (CPU and memory stress testing tool)
echo "Installing stress..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y stress

# Install fio (Flexible I/O tester)
echo "Installing fio..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fio

# Verify installations
echo ""
echo "Verifying installations..."
stress --version || echo "stress version not available"
fio --version

# Install additional useful tools for batch workloads
echo ""
echo "Installing additional monitoring and diagnostic tools..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    htop \
    iotop \
    sysstat \
    net-tools \
    curl \
    wget \
    jq \
    unzip

echo ""
echo "========================================="
echo "Application installation completed!"
echo "========================================="

# Display installed versions
echo ""
echo "Installed packages:"
echo "- stress: $(stress --version 2>&1 | head -n1 || echo 'installed')"
echo "- fio: $(fio --version)"
echo "- htop: $(htop --version | head -n1)"
echo "- sysstat: $(sar -V | head -n1)"
