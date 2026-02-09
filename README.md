# Azure Batch Image Workflow

An example workflow for creating and managing custom Ubuntu 24.04 images for Azure Batch using Packer. This repository demonstrates how to build Generation 2/Secure Launch enabled images with pre-installed applications and vulnerability scanning.

## Overview

This repository provides a complete workflow for:
- Creating custom Ubuntu 24.04 LTS images using HashiCorp Packer
- Installing specific applications (stress and fio) for batch workload testing
- Running vulnerability scans with Trivy
- Applying system hardening and security configurations
- Publishing images to Azure Compute Gallery
- Automating the build process with GitHub Actions

## Features

### Image Specifications
- **Base OS**: Ubuntu 24.04 LTS (Noble Numbat)
- **Generation**: Generation 2 with Secure Launch support
- **Security**: Secure Boot and vTPM enabled
- **Pre-installed Applications**:
  - `stress` - CPU and memory stress testing tool
  - `fio` - Flexible I/O tester for storage benchmarking
  - Additional monitoring tools (htop, iotop, sysstat, etc.)

### Security Features
- Automated vulnerability scanning with Trivy
- System hardening configurations
- Secure SSH settings
- Automatic security updates configuration
- Firewall setup (UFW)
- Security-focused sysctl parameters

## Prerequisites

### Local Development
- [Packer](https://www.packer.io/downloads) >= 1.10.0
- Azure CLI (for authentication)
- Azure subscription with appropriate permissions

### Azure Resources
Before building images, you need to create:

1. **Resource Group**:
   ```bash
   az group create --name rg-packer-images --location eastus
   ```

2. **Azure Compute Gallery**:
   ```bash
   az sig create \
     --resource-group rg-packer-images \
     --gallery-name BatchImageGallery \
     --location eastus
   ```

3. **Gallery Image Definition**:
   ```bash
   az sig image-definition create \
     --resource-group rg-packer-images \
     --gallery-name BatchImageGallery \
     --gallery-image-definition Ubuntu2404Batch \
     --publisher CustomImages \
     --offer Ubuntu \
     --sku 24.04-LTS \
     --os-type Linux \
     --os-state Generalized \
     --hyper-v-generation V2 \
     --features SecurityType=TrustedLaunch
   ```

4. **Service Principal** (for authentication):
   ```bash
   az ad sp create-for-rbac \
     --name packer-service-principal \
     --role Contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/rg-packer-images
   ```

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/mrhoads/azure-batch-image-workflow.git
cd azure-batch-image-workflow
```

### 2. Configure Variables
Copy the example variables file and customize:
```bash
cp variables.pkrvars.hcl.example variables.pkrvars.hcl
# Edit variables.pkrvars.hcl with your values
```

### 3. Set Azure Credentials
Export Azure credentials as environment variables:
```bash
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

### 4. Initialize Packer
```bash
packer init ubuntu-24.04.pkr.hcl
```

### 5. Validate Configuration
```bash
packer validate ubuntu-24.04.pkr.hcl
```

### 6. Build Image
```bash
packer build ubuntu-24.04.pkr.hcl
```

Or with custom variables:
```bash
packer build -var-file=variables.pkrvars.hcl ubuntu-24.04.pkr.hcl
```

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── build-image.yml      # GitHub Actions workflow
├── scripts/
│   ├── install-apps.sh          # Install stress, fio, and utilities
│   ├── harden-system.sh         # System hardening configuration
│   ├── scan-vulnerabilities.sh  # Trivy vulnerability scanning
│   └── cleanup.sh               # Pre-image cleanup tasks
├── ubuntu-24.04.pkr.hcl         # Main Packer template
├── variables.pkrvars.hcl.example # Example variables file
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## Packer Template Details

### Variables
The Packer template accepts the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `client_id` | Azure Service Principal Client ID | From `ARM_CLIENT_ID` env var |
| `client_secret` | Azure Service Principal Secret | From `ARM_CLIENT_SECRET` env var |
| `subscription_id` | Azure Subscription ID | From `ARM_SUBSCRIPTION_ID` env var |
| `tenant_id` | Azure Tenant ID | From `ARM_TENANT_ID` env var |
| `resource_group` | Resource group for images | `rg-packer-images` |
| `location` | Azure region | `eastus` |
| `image_name` | Managed image name | `ubuntu-2404-batch` |
| `image_version` | Image version | `1.0.0` |
| `gallery_name` | Compute Gallery name | `BatchImageGallery` |
| `gallery_image_name` | Gallery image definition name | `Ubuntu2404Batch` |
| `gallery_image_version` | Gallery image version | `1.0.0` |
| `vm_size` | Build VM size | `Standard_D2s_v3` |

### Build Process
The Packer build follows these steps:

1. **Provision VM**: Creates a temporary Azure VM from Ubuntu 24.04 base image
2. **Wait for cloud-init**: Ensures cloud-init completes before provisioning
3. **System Update**: Updates all packages to latest versions
4. **Install Applications**: Runs `install-apps.sh` to install stress, fio, and utilities
5. **System Hardening**: Runs `harden-system.sh` for security configurations
6. **Vulnerability Scan**: Runs `scan-vulnerabilities.sh` using Trivy
7. **Cleanup**: Runs `cleanup.sh` to prepare image for capture
8. **Generalize**: Deprovisiones the VM using waagent
9. **Capture Image**: Creates managed image and publishes to Compute Gallery

## GitHub Actions Workflow

The repository includes a CI/CD workflow (`.github/workflows/build-image.yml`) that:

- Validates Packer template on all commits
- Builds and publishes images on pushes to `main` branch
- Supports manual builds with custom image versions
- Uploads build manifests as artifacts
- Provides build summaries in GitHub Actions UI

### Required GitHub Secrets

Configure these secrets in your GitHub repository:

- `AZURE_CREDENTIALS`: JSON output from `az ad sp create-for-rbac`
- `ARM_CLIENT_ID`: Service Principal Application ID
- `ARM_CLIENT_SECRET`: Service Principal Secret
- `ARM_SUBSCRIPTION_ID`: Azure Subscription ID
- `ARM_TENANT_ID`: Azure AD Tenant ID

Example `AZURE_CREDENTIALS` format:
```json
{
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

## Using the Custom Image

### With Azure Batch

1. Create a Batch pool using the custom image:
```bash
az batch pool create \
  --id ubuntu-batch-pool \
  --vm-size Standard_D2s_v3 \
  --image "/subscriptions/<sub-id>/resourceGroups/rg-packer-images/providers/Microsoft.Compute/galleries/BatchImageGallery/images/Ubuntu2404Batch/versions/1.0.0" \
  --node-agent-sku-id "batch.node.ubuntu 24.04"
```

2. Submit jobs to the pool as usual

### With Azure Virtual Machines

1. Create a VM from the gallery image:
```bash
az vm create \
  --resource-group <your-rg> \
  --name my-vm \
  --image "/subscriptions/<sub-id>/resourceGroups/rg-packer-images/providers/Microsoft.Compute/galleries/BatchImageGallery/images/Ubuntu2404Batch/versions/1.0.0" \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --security-type TrustedLaunch \
  --enable-secure-boot true \
  --enable-vtpm true
```

## Customization

### Adding More Applications

Edit `scripts/install-apps.sh` to install additional packages:

```bash
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    your-package-1 \
    your-package-2
```

### Modifying Security Settings

Edit `scripts/harden-system.sh` to adjust security configurations.

### Changing Base Image

Modify the `source "azure-arm" "ubuntu"` block in `ubuntu-24.04.pkr.hcl`:

```hcl
image_publisher = "Canonical"
image_offer     = "ubuntu-24_04-lts"
image_sku       = "server"
```

## Troubleshooting

### Build Fails During Provisioning

- Check Azure service principal permissions
- Verify resource group and gallery exist
- Review Packer logs: `export PACKER_LOG=1`

### Script Failures

- Test scripts individually on a test VM
- Check for package availability in Ubuntu repositories
- Verify network connectivity during build

### Generation 2 / Secure Launch Issues

- Ensure your Azure subscription supports Trusted Launch VMs
- Verify the VM size supports Generation 2
- Check that the gallery image definition has correct security type

## Security Considerations

- Store Azure credentials securely (use GitHub Secrets, Azure Key Vault)
- Review vulnerability scan results before deploying images
- Regularly update base images and rebuild
- Follow principle of least privilege for service principals
- Enable Azure Defender for Cloud for additional protection

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the Packer build
5. Submit a pull request

## License

This project is provided as-is for demonstration purposes.

## Resources

- [HashiCorp Packer Documentation](https://www.packer.io/docs)
- [Azure Compute Gallery](https://docs.microsoft.com/azure/virtual-machines/shared-image-galleries)
- [Azure Batch Documentation](https://docs.microsoft.com/azure/batch/)
- [Ubuntu 24.04 LTS Release Notes](https://releases.ubuntu.com/24.04/)
- [Trivy Vulnerability Scanner](https://github.com/aquasecurity/trivy)
