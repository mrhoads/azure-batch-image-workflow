# Contributing to Azure Batch Image Workflow

Thank you for your interest in contributing! This guide will help you get started with modifying and extending the image build workflow.

## Development Setup

### Prerequisites
- Ubuntu 22.04 or later (or compatible Linux distribution)
- Packer >= 1.10.0
- Azure CLI
- Make (optional, for convenience)
- Git

### Quick Start
```bash
# Clone the repository
git clone https://github.com/mrhoads/azure-batch-image-workflow.git
cd azure-batch-image-workflow

# Install Packer (if not already installed)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer

# Initialize Packer
packer init ubuntu-24.04.pkr.hcl

# Validate template
packer validate ubuntu-24.04.pkr.hcl
```

## Project Structure

```
.
├── .github/workflows/     # GitHub Actions CI/CD
├── scripts/               # Provisioning scripts
│   ├── install-apps.sh    # Application installation
│   ├── harden-system.sh   # Security hardening
│   ├── scan-vulnerabilities.sh  # Trivy scanning
│   └── cleanup.sh         # Pre-image cleanup
├── ubuntu-24.04.pkr.hcl   # Main Packer template
├── Makefile               # Build automation
├── test-scripts.sh        # Script testing utility
└── README.md              # Main documentation
```

## Making Changes

### Adding New Applications

To add applications to the image, edit `scripts/install-apps.sh`:

```bash
# Add your packages here
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    your-package-1 \
    your-package-2
```

After editing:
```bash
# Test syntax
./test-scripts.sh

# Validate Packer template still works
make validate
```

### Modifying Security Settings

Edit `scripts/harden-system.sh` to change security configurations:

```bash
# Example: Add custom sysctl settings
sudo tee -a /etc/sysctl.d/99-security.conf > /dev/null <<EOF
# Your custom settings
net.ipv4.tcp_keepalive_time = 600
EOF
```

### Changing Base Image

To use a different Ubuntu version or SKU, modify `ubuntu-24.04.pkr.hcl`:

```hcl
source "azure-arm" "ubuntu" {
  # Change these values
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"
  image_version   = "latest"
}
```

To find available images:
```bash
az vm image list --publisher Canonical --offer ubuntu-24_04-lts --all --output table
```

### Adding Provisioning Steps

Add new provisioner blocks in `ubuntu-24.04.pkr.hcl`:

```hcl
build {
  # ... existing provisioners ...
  
  # Add your custom provisioner
  provisioner "shell" {
    script = "${path.root}/scripts/your-script.sh"
  }
}
```

## Testing Changes

### 1. Syntax Validation
```bash
# Test script syntax
./test-scripts.sh

# Validate Packer template
packer validate ubuntu-24.04.pkr.hcl

# Check formatting
packer fmt -check ubuntu-24.04.pkr.hcl
```

### 2. Local Testing
Test scripts on a local Ubuntu 24.04 VM:
```bash
# Start a test VM (using multipass, vagrant, or Azure)
multipass launch noble -n test-vm

# Copy scripts
multipass transfer scripts/ test-vm:/home/ubuntu/

# SSH and test
multipass shell test-vm
cd scripts
sudo ./install-apps.sh
sudo ./harden-system.sh
# etc.
```

### 3. Full Build Test
Only run a full build after validating scripts:
```bash
# Set Azure credentials
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# Run build
make build
```

## Code Style Guidelines

### Shell Scripts
- Use `set -e` at the beginning of scripts
- Add descriptive echo statements for each major step
- Use `sudo` explicitly for privileged commands
- Use `DEBIAN_FRONTEND=noninteractive` for apt-get
- Include error handling where appropriate

Example:
```bash
#!/bin/bash
set -e

echo "Installing custom application..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y myapp

echo "Configuring application..."
sudo systemctl enable myapp
sudo systemctl start myapp

echo "Installation complete!"
```

### Packer Templates (HCL)
- Use consistent indentation (2 spaces)
- Format with `packer fmt`
- Add comments for non-obvious configurations
- Group related settings together

### Documentation
- Keep README.md up to date
- Add comments to complex scripts
- Update AZURE_SETUP.md if Azure requirements change

## Submitting Changes

### 1. Create a Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes
- Make your modifications
- Test thoroughly
- Update documentation

### 3. Commit
```bash
git add .
git commit -m "Description of your changes"
```

### 4. Push and Create PR
```bash
git push origin feature/your-feature-name
```
Then create a Pull Request on GitHub.

## Common Customizations

### Adding Custom Package Repositories

In `scripts/install-apps.sh`:
```bash
# Add custom repository
wget -qO - https://example.com/key.gpg | sudo apt-key add -
echo "deb https://example.com/repo $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/custom.list
sudo apt-get update
sudo apt-get install -y custom-package
```

### Installing from Source

Create a new script `scripts/install-custom.sh`:
```bash
#!/bin/bash
set -e

echo "Building custom software..."
cd /tmp
git clone https://github.com/example/software.git
cd software
make
sudo make install
cd /tmp
rm -rf software
```

Add to Packer template:
```hcl
provisioner "shell" {
  script = "${path.root}/scripts/install-custom.sh"
}
```

### Custom Tags and Metadata

Modify tags in `ubuntu-24.04.pkr.hcl`:
```hcl
azure_tags = {
  Environment = "Production"
  CostCenter  = "Engineering"
  Owner       = "team@example.com"
  # Add your custom tags
}
```

## Troubleshooting

### Build Fails During Provisioning
- Check script execution with `./test-scripts.sh`
- Review Packer logs: `export PACKER_LOG=1; packer build ...`
- Test scripts individually on test VM

### Azure Authentication Issues
- Verify service principal has correct permissions
- Check credential environment variables are set
- Test Azure CLI login: `az login --service-principal ...`

### Generation 2 / Trusted Launch Issues
- Verify VM size supports Gen 2 (most modern sizes do)
- Check gallery image definition has correct features
- Ensure `secure_boot_enabled` and `vtpm_enabled` are both true

## Resources

- [Packer Azure ARM Builder](https://developer.hashicorp.com/packer/plugins/builders/azure/arm)
- [Azure Compute Gallery](https://docs.microsoft.com/azure/virtual-machines/shared-image-galleries)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

## Questions?

If you have questions or need help:
1. Check existing issues on GitHub
2. Review the documentation
3. Open a new issue with details about your problem

Thank you for contributing!
