#!/bin/sh

# Step 1: Update package index and install dependencies
echo "Updating package index and installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Step 2: Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 3: Add Docker's official repository
echo "Adding Docker's official repository..."
UBUNTU_VERSION=$(lsb_release -cs 2>/dev/null || echo "noble")  # Use 'noble' for Ubuntu 24.04
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu ${UBUNTU_VERSION} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 4: Update package index again
echo "Updating package index again..."
sudo apt-get update -qq

# Step 5: Install Docker (specific version if set, latest if not)
if [ -n "$DOCKER_VERSION" ]; then
  echo "Installing Docker version ${DOCKER_VERSION}..."
  sudo apt-get install -y -qq \
         docker-ce="${DOCKER_VERSION}" \
         docker-ce-cli="${DOCKER_VERSION}" \
         containerd.io \
         docker-buildx-plugin \
         docker-compose-plugin
else
  echo "Installing the latest Docker version..."
  sudo apt-get install -y -qq \
           docker-ce \
           docker-ce-cli \
           containerd.io \
           docker-buildx-plugin \
           docker-compose-plugin
fi

# Step 6: Verify Docker installation
echo "Verifying Docker installation..."
docker --version
docker compose version
