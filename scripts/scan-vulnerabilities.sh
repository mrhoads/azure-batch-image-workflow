#!/bin/bash
set -e

echo "========================================="
echo "Running Vulnerability Scan with Trivy"
echo "========================================="

# Install Trivy
echo "Installing Trivy vulnerability scanner..."
# Use modern GPG keyring method (apt-key is deprecated in Ubuntu 22.04+)
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# Update Trivy database
echo ""
echo "Updating Trivy vulnerability database..."
trivy --version
sudo trivy image --download-db-only

# Scan the root filesystem for vulnerabilities
echo ""
echo "Scanning system for vulnerabilities..."
SCAN_OUTPUT="/tmp/trivy-scan-results.json"
SCAN_TABLE="/tmp/trivy-scan-results.txt"

# Run scan and save results
sudo trivy rootfs --format json --output ${SCAN_OUTPUT} / || true
sudo trivy rootfs --format table --output ${SCAN_TABLE} / || true

# Display scan summary
echo ""
echo "========================================="
echo "Vulnerability Scan Summary"
echo "========================================="

if [ -f "${SCAN_TABLE}" ]; then
    # Show high and critical vulnerabilities only
    echo "High and Critical vulnerabilities found:"
    sudo grep -E "(HIGH|CRITICAL)" ${SCAN_TABLE} | head -20 || echo "No HIGH or CRITICAL vulnerabilities found in top results"
fi

# Parse JSON results for summary
if [ -f "${SCAN_OUTPUT}" ]; then
    echo ""
    echo "Detailed scan results saved to: ${SCAN_OUTPUT}"
    
    # Count vulnerabilities by severity
    CRITICAL=$(sudo jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' ${SCAN_OUTPUT} 2>/dev/null || echo "0")
    HIGH=$(sudo jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' ${SCAN_OUTPUT} 2>/dev/null || echo "0")
    MEDIUM=$(sudo jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' ${SCAN_OUTPUT} 2>/dev/null || echo "0")
    LOW=$(sudo jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' ${SCAN_OUTPUT} 2>/dev/null || echo "0")
    
    echo ""
    echo "Vulnerability counts by severity:"
    echo "  CRITICAL: ${CRITICAL}"
    echo "  HIGH:     ${HIGH}"
    echo "  MEDIUM:   ${MEDIUM}"
    echo "  LOW:      ${LOW}"
fi

echo ""
echo "========================================="
echo "Vulnerability scan completed!"
echo "========================================="
echo ""
echo "Note: This scan provides visibility into vulnerabilities."
echo "Review and remediate critical/high severity issues as needed."
echo "Some vulnerabilities may require system updates or application patches."

# Clean up Trivy (optional - reduces image size)
# Uncomment if you don't want Trivy in the final image
# sudo apt-get remove -y trivy
# sudo rm -rf /var/lib/apt/lists/trivy*
