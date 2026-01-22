# Build and Push Docker Images to Docker Hub
# Usage: .\build-and-push-docker.ps1 [dockerhub-username]

param(
    [string]$DockerHubUsername = "vanshp17"
)

$ErrorActionPreference = "Stop"

# Save the original script location
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot

$BackendImage = "${DockerHubUsername}/bags-luggage-backend:latest"
$FrontendImage = "${DockerHubUsername}/bags-luggage-frontend:latest"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Building and Pushing Docker Images" -ForegroundColor Cyan
Write-Host "Docker Hub Username: $DockerHubUsername" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Login to Docker Hub
Write-Host ""
Write-Host "Step 1: Logging in to Docker Hub..." -ForegroundColor Yellow
Write-Host "Please enter your Docker Hub credentials:" -ForegroundColor Yellow
docker login -u $DockerHubUsername

# Build Backend Image
Write-Host ""
Write-Host "Step 2: Building backend image..." -ForegroundColor Yellow
$BackendPath = Join-Path $ProjectRoot "app\backend"
Set-Location $BackendPath
docker build -t $BackendImage .
Write-Host "[OK] Backend image built successfully" -ForegroundColor Green

# Push Backend Image
Write-Host ""
Write-Host "Step 3: Pushing backend image to Docker Hub..." -ForegroundColor Yellow
docker push $BackendImage
Write-Host "[OK] Backend image pushed successfully" -ForegroundColor Green

# Build Frontend Image
Write-Host ""
Write-Host "Step 4: Building frontend image..." -ForegroundColor Yellow
$FrontendPath = Join-Path $ProjectRoot "app\frontend"
Set-Location $FrontendPath
# Note: REACT_APP_API_URL will be set at runtime in Azure, using placeholder for build
docker build --build-arg REACT_APP_API_URL=https://backend-url.azurecontainerapps.io -t $FrontendImage .
Write-Host "[OK] Frontend image built successfully" -ForegroundColor Green

# Push Frontend Image
Write-Host ""
Write-Host "Step 5: Pushing frontend image to Docker Hub..." -ForegroundColor Yellow
docker push $FrontendImage
Write-Host "[OK] Frontend image pushed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] All images built and pushed successfully!" -ForegroundColor Green
Write-Host "Backend:  $BackendImage" -ForegroundColor White
Write-Host "Frontend: $FrontendImage" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan

# Return to original location
Set-Location $ScriptRoot

