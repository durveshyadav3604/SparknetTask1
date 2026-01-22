# Deploy Bags Luggage Application to Azure
# This script builds Docker images, pushes to Docker Hub, and deploys to Azure

param(
    [string]$DockerHubUsername = "vanshp17",
    [string]$MongoDBConnectionString = "",
    [string]$Location = "eastus"
)

$ErrorActionPreference = "Stop"

# Save the original script location
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Bags Luggage - Azure Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host ""
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check Azure CLI
try {
    az account show | Out-Null
    Write-Host "✓ Azure CLI is logged in" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
}

# Check Terraform
try {
    terraform version | Out-Null
    Write-Host "✓ Terraform is installed" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Terraform is not installed. Please install Terraform." -ForegroundColor Red
    exit 1
}

# Step 2: Build and push Docker images
Write-Host ""
Write-Host "Step 2: Building and pushing Docker images..." -ForegroundColor Yellow
$BuildScript = Join-Path $ScriptRoot "build-and-push-docker.ps1"
& $BuildScript -DockerHubUsername $DockerHubUsername

# Step 3: Configure Terraform
Write-Host ""
Write-Host "Step 3: Configuring Terraform..." -ForegroundColor Yellow
$TerraformPath = Join-Path $ProjectRoot "terraform"
Set-Location $TerraformPath

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "Creating terraform.tfvars from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    
    # Update terraform.tfvars with Docker Hub images
    $tfvars = Get-Content "terraform.tfvars" -Raw
    $tfvars = $tfvars -replace 'backend_image = ""', "backend_image = `"${DockerHubUsername}/bags-luggage-backend:latest`""
    $tfvars = $tfvars -replace 'frontend_image = ""', "frontend_image = `"${DockerHubUsername}/bags-luggage-frontend:latest`""
    $tfvars = $tfvars -replace 'location = "eastus"', "location = `"$Location`""
    
    if ($MongoDBConnectionString -ne "") {
        $tfvars = $tfvars + "`n`nmongodb_connection_string = `"$MongoDBConnectionString`""
    }
    
    Set-Content "terraform.tfvars" $tfvars
    Write-Host "✓ terraform.tfvars configured" -ForegroundColor Green
} else {
    Write-Host "✓ terraform.tfvars already exists" -ForegroundColor Green
}

# Step 4: Initialize Terraform
Write-Host ""
Write-Host "Step 4: Initializing Terraform..." -ForegroundColor Yellow
terraform init
Write-Host "✓ Terraform initialized" -ForegroundColor Green

# Step 5: Plan deployment
Write-Host ""
Write-Host "Step 5: Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan
Write-Host "✓ Plan created" -ForegroundColor Green

# Step 6: Apply deployment
Write-Host ""
Write-Host "Step 6: Deploying to Azure..." -ForegroundColor Yellow
Write-Host "This will create Azure resources. Continue? (Y/N): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

terraform apply tfplan
Write-Host "✓ Deployment completed" -ForegroundColor Green

# Step 7: Get outputs
Write-Host ""
Write-Host "Step 7: Retrieving deployment information..." -ForegroundColor Yellow
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
terraform output

Write-Host ""
Write-Host "Your application URLs:" -ForegroundColor Cyan
$backendUrl = terraform output -raw backend_url
$frontendUrl = terraform output -raw frontend_url
Write-Host "Backend:  $backendUrl" -ForegroundColor White
Write-Host "Frontend: $frontendUrl" -ForegroundColor White
Write-Host ""
Write-Host "Note: It may take a few minutes for the apps to start." -ForegroundColor Yellow
Write-Host "You can check the status in Azure Portal." -ForegroundColor Yellow

Set-Location $ProjectRoot

