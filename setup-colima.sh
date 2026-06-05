#!/bin/bash
set -e

echo "Setting up Colima container environment..."

# Detect OS
OS="$(uname -s)"

install_colima() {
    case "$OS" in
        Darwin)
            brew install colima
            ;;
        Linux)
            # Colima isn't packaged in apt; it's distributed via Homebrew, which
            # also works on Linux. Native Docker is usually the better choice on
            # Linux, so require brew rather than pulling in a download fallback.
            if command -v brew &> /dev/null; then
                brew install colima
            else
                echo "Colima on Linux requires Homebrew (https://brew.sh)."
                echo "On Linux, prefer installing Docker Engine directly instead."
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# Colima provides the Docker engine inside a VM, but not the client. Install the
# docker CLI plus the compose plugin so `docker` and `docker compose` work.
install_docker_cli() {
    case "$OS" in
        Darwin|Linux)
            command -v brew &> /dev/null || { echo "Homebrew required for the docker CLI."; exit 1; }
            brew install docker docker-compose
            ;;
    esac
}

# Brew installs docker-compose as a standalone binary; wiring it into the docker
# CLI plugins dir is what makes `docker compose ...` (v2 syntax) work.
link_compose_plugin() {
    local plugin_dir="$HOME/.docker/cli-plugins"
    local compose_bin
    compose_bin="$(brew --prefix)/opt/docker-compose/bin/docker-compose"
    [ -x "$compose_bin" ] || return 0
    mkdir -p "$plugin_dir"
    if [ -L "$plugin_dir/docker-compose" ]; then
        echo "docker compose plugin already linked."
    else
        echo "Linking docker compose plugin..."
        ln -sfn "$compose_bin" "$plugin_dir/docker-compose"
    fi
}

# Rosetta lets the Colima VM run amd64 images quickly on Apple Silicon. It's only
# relevant on arm64 Macs; Intel Macs run amd64 natively. Colima activates Rosetta
# itself via the vz VM type (--vz-rosetta), so we just need it installed.
install_rosetta() {
    if [ "$OS" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
        return
    fi
    if [ -d "/Library/Apple/usr/share/rosetta" ] || /usr/bin/pgrep -q oahd; then
        echo "Rosetta already installed."
    else
        echo "Installing Rosetta (needed to run amd64 images on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
    fi
}

# Install Colima
if ! command -v colima &> /dev/null; then
    echo "Installing Colima..."
    install_colima
else
    echo "Colima already installed."
fi

# Install Docker CLI + compose
if ! command -v docker &> /dev/null; then
    echo "Installing Docker CLI..."
    install_docker_cli
else
    echo "Docker CLI already installed."
fi
link_compose_plugin

# Start Colima with resources sized for containers (incl. SQL Server, which
# requires >=2GB RAM). On Apple Silicon use the vz VM type with Rosetta so amd64
# images run fast instead of falling back to slow QEMU emulation.
if ! colima status &> /dev/null; then
    echo "Starting Colima..."
    install_rosetta

    # Leave one host core free; size the rest for the containers.
    if [ "$OS" = "Darwin" ]; then
        cpus=$(( $(sysctl -n hw.ncpu) - 1 ))
    else
        cpus=$(( $(nproc) - 1 ))
    fi
    [ "$cpus" -lt 1 ] && cpus=1

    start_args=(--cpu "$cpus" --memory 8 --disk 100)
    if [ "$OS" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
        start_args+=(--vm-type vz --vz-rosetta)
    fi
    colima start "${start_args[@]}"
else
    echo "Colima already running."
fi

echo ""
echo "=== Colima setup complete! ==="
echo ""
if colima status &> /dev/null; then
    echo "Colima is running and ready."
else
    echo "Start it with: colima start"
fi
echo "Use 'docker' and 'docker compose' as usual; Colima provides the engine."
