#!/bin/bash

# Build and Push Docker Images to Docker Hub
# Usage: ./build-and-push-docker.sh [dockerhub-username]

set -e

DOCKERHUB_USERNAME=${1:-vanshp17}
BACKEND_IMAGE="${DOCKERHUB_USERNAME}/bags-luggage-backend:latest"
FRONTEND_IMAGE="${DOCKERHUB_USERNAME}/bags-luggage-frontend:latest"

echo "=========================================="
echo "Building and Pushing Docker Images"
echo "Docker Hub Username: $DOCKERHUB_USERNAME"
echo "=========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Login to Docker Hub
echo ""
echo "Step 1: Logging in to Docker Hub..."
echo "Please enter your Docker Hub credentials:"
docker login -u $DOCKERHUB_USERNAME

# Build Backend Image
echo ""
echo "Step 2: Building backend image..."
cd ../app/backend
docker build -t $BACKEND_IMAGE .
echo "✓ Backend image built successfully"

# Push Backend Image
echo ""
echo "Step 3: Pushing backend image to Docker Hub..."
docker push $BACKEND_IMAGE
echo "✓ Backend image pushed successfully"

# Build Frontend Image
echo ""
echo "Step 4: Building frontend image..."
cd ../frontend
# Note: REACT_APP_API_URL will be set at runtime in Azure, using placeholder for build
docker build --build-arg REACT_APP_API_URL=https://backend-url.azurecontainerapps.io -t $FRONTEND_IMAGE .
echo "✓ Frontend image built successfully"

# Push Frontend Image
echo ""
echo "Step 5: Pushing frontend image to Docker Hub..."
docker push $FRONTEND_IMAGE
echo "✓ Frontend image pushed successfully"

echo ""
echo "=========================================="
echo "✓ All images built and pushed successfully!"
echo "Backend:  $BACKEND_IMAGE"
echo "Frontend: $FRONTEND_IMAGE"
echo "=========================================="

cd ../../scripts


