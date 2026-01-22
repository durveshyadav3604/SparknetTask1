#!/bin/bash

# Terraform Automation Script for Bag Luggage Azure Deployment
# This script automates the Terraform setup and deployment process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
BACKEND_DIR="app/backend"
FRONTEND_DIR="app/frontend"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Docker is needed for building images."
    fi
    
    print_info "Prerequisites check passed!"
}

# Azure login check
check_azure_login() {
    print_info "Checking Azure login status..."
    
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Attempting login..."
        az login
    else
        print_info "Already logged in to Azure"
    fi
}

# Initialize Terraform
init_terraform() {
    print_info "Initializing Terraform..."
    cd "$TERRAFORM_DIR"
    terraform init
    cd ..
}

# Validate Terraform configuration
validate_terraform() {
    print_info "Validating Terraform configuration..."
    cd "$TERRAFORM_DIR"
    terraform validate
    cd ..
}

# Plan Terraform deployment
plan_terraform() {
    print_info "Creating Terraform execution plan..."
    cd "$TERRAFORM_DIR"
    terraform plan -out=tfplan
    cd ..
}

# Apply Terraform deployment
apply_terraform() {
    print_info "Applying Terraform configuration..."
    cd "$TERRAFORM_DIR"
    
    read -p "Do you want to proceed with the deployment? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
    
    terraform apply tfplan
    cd ..
}

# Get Terraform outputs
get_outputs() {
    print_info "Retrieving Terraform outputs..."
    cd "$TERRAFORM_DIR"
    terraform output
    cd ..
}

# Main execution
main() {
    print_info "Starting Terraform automation script..."
    
    check_prerequisites
    check_azure_login
    
    case "${1:-all}" in
        init)
            init_terraform
            ;;
        validate)
            validate_terraform
            ;;
        plan)
            init_terraform
            plan_terraform
            ;;
        apply)
            init_terraform
            plan_terraform
            apply_terraform
            get_outputs
            ;;
        destroy)
            print_warning "This will destroy all infrastructure!"
            read -p "Are you sure? Type 'yes' to confirm: " confirm
            if [ "$confirm" = "yes" ]; then
                cd "$TERRAFORM_DIR"
                terraform destroy
                cd ..
            else
                print_info "Destroy cancelled"
            fi
            ;;
        outputs)
            get_outputs
            ;;
        all)
            init_terraform
            validate_terraform
            plan_terraform
            apply_terraform
            get_outputs
            ;;
        *)
            echo "Usage: $0 {init|validate|plan|apply|destroy|outputs|all}"
            echo ""
            echo "Commands:"
            echo "  init      - Initialize Terraform"
            echo "  validate  - Validate Terraform configuration"
            echo "  plan      - Create execution plan"
            echo "  apply     - Apply Terraform configuration"
            echo "  destroy   - Destroy all infrastructure"
            echo "  outputs   - Show Terraform outputs"
            echo "  all       - Run init, validate, plan, apply, and show outputs"
            exit 1
            ;;
    esac
    
    print_info "Script completed successfully!"
}

# Run main function
main "$@"


