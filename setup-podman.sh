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

# Rosetta lets the Podman VM run amd64 images quickly on Apple Silicon under
# the default applehv provider. It's only relevant on arm64 Macs; Intel Macs
# run amd64 natively.
install_rosetta() {
    if [ "$(uname -m)" != "arm64" ]; then
        return
    fi
    if [ -d "/Library/Apple/usr/share/rosetta" ] || /usr/bin/pgrep -q oahd; then
        echo "Rosetta already installed."
    else
        echo "Installing Rosetta (needed to run amd64 images on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
    fi
}

# Having Rosetta installed on the host is not enough: on kernel >=6.13 Podman's
# VM image ships with Rosetta gated OFF behind the marker file
# /etc/containers/enable-rosetta, so amd64 images fall back to QEMU. Under QEMU
# the amd64 SQL Server binary segfaults, so we opt back in. Creating the marker
# makes rosetta-activation.service register the Rosetta binfmt handler on every
# boot; a one-off restart activates it cleanly without racing systemd-binfmt.
enable_rosetta_in_vm() {
    [ "$(uname -m)" = "arm64" ] || return 0

    # The guest must be running so we can configure it (init does not start it).
    podman machine start >/dev/null 2>&1 || true

    if podman machine ssh 'test -e /proc/sys/fs/binfmt_misc/rosetta' 2>/dev/null; then
        echo "Rosetta already active in the VM."
        return 0
    fi

    echo "Enabling Rosetta inside the Podman VM (amd64 SQL Server needs it)..."
    podman machine ssh 'sudo touch /etc/containers/enable-rosetta'
    echo "Restarting machine to activate Rosetta..."
    podman machine stop
    podman machine start

    if podman machine ssh 'test -e /proc/sys/fs/binfmt_misc/rosetta' 2>/dev/null; then
        echo "Rosetta is active in the VM."
    else
        echo "WARNING: Rosetta did not activate; amd64 images will run under slow QEMU."
    fi
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
    # Install Rosetta before the machine starts so the VM can use it for amd64
    install_rosetta

    if ! podman machine list --format "{{.Name}}" 2>/dev/null | grep -q .; then
        echo "Initializing Podman machine..."
        # SQL Server requires >=2GB RAM (the default is too low) and a roomy
        # disk; leave one host core free and size the rest for the containers.
        cpus=$(( $(sysctl -n hw.ncpu) - 1 ))
        [ "$cpus" -lt 1 ] && cpus=1
        podman machine init --cpus "$cpus" --memory 8192 --disk-size 100
    else
        echo "Podman machine already initialized."
    fi

    # Wire Rosetta into the VM (idempotent; fixes existing machines too).
    enable_rosetta_in_vm
fi

echo ""
echo "=== Podman setup complete! ==="
echo ""
if podman machine inspect --format '{{.State}}' 2>/dev/null | grep -q running; then
    echo "Podman machine is running and ready."
else
    echo "Start the machine with: podman machine start"
fi
echo "You can now use 'podman' or 'docker' commands interchangeably."
echo "For docker-compose, use 'podman-compose' instead."
