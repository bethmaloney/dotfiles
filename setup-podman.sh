#!/bin/bash
set -e

echo "Setting up Podman container environment..."

# Detect OS
OS="$(uname -s)"

install_podman() {
    case "$OS" in
        Linux)
            sudo apt-get update
            sudo apt-get install -y podman
            ;;
        Darwin)
            brew install podman
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

install_podman_compose() {
    case "$OS" in
        Linux)
            sudo apt-get install -y podman-compose
            ;;
        Darwin)
            brew install podman-compose
            ;;
    esac
}

# Install Podman
if ! command -v podman &> /dev/null; then
    echo "Installing Podman..."
    install_podman
else
    echo "Podman already installed."
fi

# Install Podman Compose
if ! command -v podman-compose &> /dev/null; then
    echo "Installing Podman Compose..."
    install_podman_compose
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
    sudo mkdir -p /usr/local/bin
    sudo ln -sf "$(which podman)" /usr/local/bin/docker
    echo "Docker commands will now use Podman."
fi

# Initialize Podman machine on macOS (Podman runs in a VM on Mac)
if [ "$OS" = "Darwin" ]; then
    if ! podman machine list --format "{{.Name}}" 2>/dev/null | grep -q .; then
        echo "Initializing Podman machine..."
        podman machine init
        echo "Start the machine with: podman machine start"
    else
        echo "Podman machine already initialized."
    fi
fi

echo ""
echo "=== Podman setup complete! ==="
echo ""
echo "You can now use 'podman' or 'docker' commands interchangeably."
echo "For docker-compose, use 'podman-compose' instead."
