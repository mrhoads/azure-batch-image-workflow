# Azure Setup Guide

This guide walks through setting up the Azure resources needed for the Packer image build.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Appropriate Azure subscription permissions (Contributor or Owner)
- Bash shell (Linux, macOS, or WSL on Windows)

## Step 1: Set Variables

```bash
# Set your variables
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP="rg-packer-images"
LOCATION="eastus"
GALLERY_NAME="BatchImageGallery"
IMAGE_DEFINITION="Ubuntu2404Batch"
SP_NAME="packer-service-principal"

# Set the subscription
az account set --subscription "${SUBSCRIPTION_ID}"
```

## Step 2: Create Resource Group

```bash
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}"
```

## Step 3: Create Azure Compute Gallery

```bash
az sig create \
  --resource-group "${RESOURCE_GROUP}" \
  --gallery-name "${GALLERY_NAME}" \
  --location "${LOCATION}" \
  --description "Gallery for custom Azure Batch images"
```

## Step 4: Create Image Definition

```bash
az sig image-definition create \
  --resource-group "${RESOURCE_GROUP}" \
  --gallery-name "${GALLERY_NAME}" \
  --gallery-image-definition "${IMAGE_DEFINITION}" \
  --publisher "CustomImages" \
  --offer "Ubuntu" \
  --sku "24.04-LTS" \
  --os-type "Linux" \
  --os-state "Generalized" \
  --hyper-v-generation "V2" \
  --features SecurityType=TrustedLaunch \
  --description "Ubuntu 24.04 LTS with stress and fio for Azure Batch"
```

## Step 5: Create Service Principal

```bash
# Create service principal with Contributor role on resource group
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "${SP_NAME}" \
  --role "Contributor" \
  --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
  --sdk-auth)

# Display the output (save this securely!)
echo "${SP_OUTPUT}"
```

**Important**: Save the JSON output from the service principal creation. You'll need it for:
- GitHub Secrets (`AZURE_CREDENTIALS`)
- Local environment variables

## Step 6: Extract Credentials

From the service principal JSON output, extract:

```bash
# Example JSON output:
# {
#   "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#   "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   ...
# }

# Set environment variables for local builds
export ARM_CLIENT_ID="<clientId>"
export ARM_CLIENT_SECRET="<clientSecret>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
export ARM_TENANT_ID="<tenantId>"
```

## Step 7: Configure GitHub Secrets (Optional)

If using GitHub Actions, add these secrets to your repository:

1. Go to repository Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `AZURE_CREDENTIALS`: The complete JSON output from Step 5
   - `ARM_CLIENT_ID`: The clientId from the JSON
   - `ARM_CLIENT_SECRET`: The clientSecret from the JSON
   - `ARM_SUBSCRIPTION_ID`: Your subscription ID
   - `ARM_TENANT_ID`: The tenantId from the JSON

## Step 8: Verify Setup

```bash
# List the gallery
az sig show \
  --resource-group "${RESOURCE_GROUP}" \
  --gallery-name "${GALLERY_NAME}"

# List image definitions
az sig image-definition list \
  --resource-group "${RESOURCE_GROUP}" \
  --gallery-name "${GALLERY_NAME}" \
  --output table

# Test service principal authentication
az login --service-principal \
  -u "${ARM_CLIENT_ID}" \
  -p "${ARM_CLIENT_SECRET}" \
  --tenant "${ARM_TENANT_ID}"

az account show
```

## Cleanup (Optional)

To delete all resources when you're done:

```bash
# Delete the resource group (includes all resources)
az group delete --name "${RESOURCE_GROUP}" --yes --no-wait

# Delete the service principal
az ad sp delete --id "${ARM_CLIENT_ID}"
```

## Troubleshooting

### Permission Issues
If you get permission errors:
- Verify you have Contributor or Owner role on the subscription/resource group
- Check service principal permissions: `az role assignment list --assignee "${ARM_CLIENT_ID}"`

### Gallery Creation Fails
- Ensure the gallery name is unique within the subscription
- Verify the location is valid: `az account list-locations -o table`

### Image Definition Issues
- Trusted Launch requires Generation 2 (V2) and specific security features
- Not all VM sizes support Trusted Launch - use sizes like Standard_D2s_v3

## Next Steps

After completing this setup:
1. Return to the main README.md for Packer build instructions
2. Test with: `packer validate ubuntu-24.04.pkr.hcl`
3. Build with: `packer build ubuntu-24.04.pkr.hcl`
