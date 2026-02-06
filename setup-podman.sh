#!/bin/bash
set -e

echo "Setting up Podman container environment..."

# Install Podman
if ! command -v podman &> /dev/null; then
    echo "Installing Podman..."
    sudo apt-get update
    sudo apt-get install -y podman
else
    echo "Podman already installed."
fi

# Install Podman Compose
if ! command -v podman-compose &> /dev/null; then
    echo "Installing Podman Compose..."
    sudo apt-get install -y podman-compose
else
    echo "Podman Compose already installed."
fi

# Create docker symlink to podman (if docker is not already installed)
if command -v docker &> /dev/null; then
    # Check if docker is the real thing or already a symlink to podman
    if [ -L "$(which docker)" ]; then
        echo "Docker symlink already exists."
    else
        echo "WARNING: Real Docker is installed. Skipping symlink creation."
        echo "         Remove Docker first if you want to use Podman as docker."
    fi
else
    echo "Creating docker -> podman symlink..."
    sudo ln -sf $(which podman) /usr/local/bin/docker
    echo "Docker commands will now use Podman."
fi

echo ""
echo "=== Podman setup complete! ==="
echo ""
echo "You can now use 'podman' or 'docker' commands interchangeably."
echo "For docker-compose, use 'podman-compose' instead."
