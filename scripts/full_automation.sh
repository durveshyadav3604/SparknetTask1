#!/bin/bash
set -e

echo "🚀 Starting Full Automated DevOps Flow (Bags Luggage App)..."

# -------------------------------
# 🔹 STEP 1: Set Variables
# -------------------------------
DOCKERHUB_USER="vanshp17"
RESOURCE_GROUP="devops-rg"
LOCATION="centralindia"

FRONTEND_IMAGE="$DOCKERHUB_USER/bags-luggage-frontend:latest"
BACKEND_IMAGE="$DOCKERHUB_USER/bags-luggage-backend:latest"

echo "📦 Resource Group: $RESOURCE_GROUP"
echo "🌍 Location: $LOCATION"
echo "🐳 DockerHub User: $DOCKERHUB_USER"

# -------------------------------
# 🔹 STEP 2: Azure Login & Resource Setup
# -------------------------------
echo "🔹 Logging into Azure..."
az login --output none

echo "🔹 Creating Resource Group if not exists..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output none

# -------------------------------
# 🔹 STEP 3: Docker Build & Push
# -------------------------------
echo "🔹 Logging into DockerHub..."
docker login -u $DOCKERHUB_USER

BACKEND_URL="http://$(
  az container show \
    --resource-group $RESOURCE_GROUP \
    --name backend-app \
    --query "ipAddress.ip" -o tsv 2>/dev/null || echo "localhost"
):5000"

echo "🔗 Using backend URL: $BACKEND_URL"

echo "🔹 Building Docker images..."
docker build -t $FRONTEND_IMAGE \
  --build-arg REACT_APP_API_URL=$BACKEND_URL ./app/frontend

docker build -t $BACKEND_IMAGE ./app/backend

echo "🔹 Pushing Docker images to DockerHub..."
docker push $FRONTEND_IMAGE
docker push $BACKEND_IMAGE

# -------------------------------
# 🔹 STEP 4: Terraform Infrastructure Deployment
# -------------------------------
echo "🔹 Initializing Terraform deployment..."

mkdir -p terraform
cd terraform

cat > main.tf <<'EOF'
variable "dockerhub_user" {}
variable "resource_group" {}
variable "location" {}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

resource "azurerm_container_group" "backend" {
  name                = "backend-app"
  location            = var.location
  resource_group_name = var.resource_group
  os_type             = "Linux"

  container {
    name   = "backend"
    image  = "${var.dockerhub_user}/bags-luggage-backend:latest"
    cpu    = "0.5"
    memory = "1.0"
    ports {
      port     = 5000
      protocol = "TCP"
    }
  }

  ip_address_type = "Public"
  dns_name_label  = "backend-${random_string.suffix.result}"
}

resource "azurerm_container_group" "frontend" {
  name                = "frontend-app"
  location            = var.location
  resource_group_name = var.resource_group
  os_type             = "Linux"

  container {
    name   = "frontend"
    image  = "${var.dockerhub_user}/bags-luggage-frontend:latest"
    cpu    = "0.5"
    memory = "1.0"
    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      REACT_APP_API_URL = "http://${azurerm_container_group.backend.ip_address}:5000"
    }
  }

  ip_address_type = "Public"
  dns_name_label  = "frontend-${random_string.suffix.result}"
}
EOF

echo "🔹 Preparing Azure authentication for Terraform..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_USE_AZURECLI_AUTH=true

terraform init -input=false

terraform apply -auto-approve \
  -var "dockerhub_user=$DOCKERHUB_USER" \
  -var "resource_group=$RESOURCE_GROUP" \
  -var "location=$LOCATION"

cd ..

# -------------------------------
# 🔹 STEP 5: Completion Message
# -------------------------------
echo "✅ Deployment Successful!"
echo "🎯 Bags Luggage Frontend & Backend are running in Azure using DockerHub images."
