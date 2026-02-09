.PHONY: help init validate format build clean test

# Default target
help:
	@echo "Azure Batch Image Workflow - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  help       - Show this help message"
	@echo "  init       - Initialize Packer plugins"
	@echo "  validate   - Validate Packer template"
	@echo "  format     - Format Packer template"
	@echo "  build      - Build the image (requires Azure credentials)"
	@echo "  test       - Test provisioning scripts syntax"
	@echo "  clean      - Clean up build artifacts"
	@echo ""
	@echo "Environment variables required for build:"
	@echo "  ARM_CLIENT_ID       - Azure Service Principal Client ID"
	@echo "  ARM_CLIENT_SECRET   - Azure Service Principal Secret"
	@echo "  ARM_SUBSCRIPTION_ID - Azure Subscription ID"
	@echo "  ARM_TENANT_ID       - Azure Tenant ID"

# Initialize Packer plugins
init:
	@echo "Initializing Packer plugins..."
	packer init ubuntu-24.04.pkr.hcl

# Validate Packer template
validate: init
	@echo "Validating Packer template..."
	packer validate ubuntu-24.04.pkr.hcl
	@echo "✓ Template is valid"

# Format Packer template
format:
	@echo "Formatting Packer template..."
	packer fmt ubuntu-24.04.pkr.hcl
	@echo "✓ Template formatted"

# Test provisioning scripts
test:
	@echo "Testing provisioning scripts..."
	./test-scripts.sh

# Build the image
build: validate
	@echo "Building image..."
	@if [ -z "$$ARM_CLIENT_ID" ]; then \
		echo "Error: ARM_CLIENT_ID not set"; \
		exit 1; \
	fi
	@if [ -z "$$ARM_CLIENT_SECRET" ]; then \
		echo "Error: ARM_CLIENT_SECRET not set"; \
		exit 1; \
	fi
	@if [ -z "$$ARM_SUBSCRIPTION_ID" ]; then \
		echo "Error: ARM_SUBSCRIPTION_ID not set"; \
		exit 1; \
	fi
	@if [ -z "$$ARM_TENANT_ID" ]; then \
		echo "Error: ARM_TENANT_ID not set"; \
		exit 1; \
	fi
	packer build ubuntu-24.04.pkr.hcl

# Clean up build artifacts
clean:
	@echo "Cleaning up build artifacts..."
	rm -rf packer_cache/
	rm -f manifest.json
	rm -f crash.log
	@echo "✓ Cleanup complete"
