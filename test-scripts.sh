#!/bin/bash
# Test script to validate the provisioning scripts locally
# Run this on an Ubuntu 24.04 system to test scripts before building image

set -e

echo "========================================="
echo "Testing Provisioning Scripts"
echo "========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

test_script() {
    local script_name=$1
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    echo "Testing ${script_name}..."
    
    if [ ! -f "${script_path}" ]; then
        echo -e "${RED}✗ Script not found: ${script_path}${NC}"
        return 1
    fi
    
    if [ ! -x "${script_path}" ]; then
        echo -e "${RED}✗ Script not executable: ${script_path}${NC}"
        return 1
    fi
    
    # Run syntax check
    bash -n "${script_path}" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Syntax check passed${NC}"
    else
        echo -e "${RED}✗ Syntax check failed${NC}"
        return 1
    fi
    
    echo ""
}

# Test all scripts
echo "Checking script syntax..."
echo ""

test_script "scripts/install-apps.sh"
test_script "scripts/harden-system.sh"
test_script "scripts/scan-vulnerabilities.sh"
test_script "scripts/cleanup.sh"

echo "========================================="
echo -e "${GREEN}All scripts passed syntax validation!${NC}"
echo "========================================="
echo ""
echo "Note: This only validates syntax."
echo "To fully test scripts, run them on an Ubuntu 24.04 VM:"
echo "  sudo ./scripts/install-apps.sh"
echo "  sudo ./scripts/harden-system.sh"
echo "  sudo ./scripts/scan-vulnerabilities.sh"
echo "  sudo ./scripts/cleanup.sh"
