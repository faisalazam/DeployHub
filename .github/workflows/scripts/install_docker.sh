#!/bin/sh

# Step 1: Update package index and install dependencies
echo "Updating package index and installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Step 2: Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo tee /etc/apt/keyrings/docker.asc > /dev/null

# Step 3: Add Docker's official repository
echo "Adding Docker's official repository..."
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 4: Update package index again and install Docker using the Docker installation script
echo "Updating package index and installing Docker..."
sudo apt-get update
curl -fsSL https://get.docker.com | VERSION=${DOCKER_VERSION} sh

# Step 5: Verify Docker installation
echo "Verifying Docker installation..."
docker --version
