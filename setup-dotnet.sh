#!/bin/bash
set -e

echo "Setting up .NET development environment..."

# Detect OS
OS="$(uname -s)"

# Ensure brew is on PATH for this session on macOS (Apple Silicon vs Intel)
if [ "$OS" = "Darwin" ]; then
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

DOTNET_DIR="$HOME/.dotnet"
DOTNET_CHANNEL="10.0"

# --- .NET 10 SDK ---
# Installed to ~/.dotnet via the official script so the version can be pinned
# to the 10.0 channel consistently across macOS and Linux. The zshrc already
# adds ~/.dotnet and ~/.dotnet/tools to PATH.
install_dotnet() {
    echo "Installing .NET SDK ($DOTNET_CHANNEL)..."
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    chmod +x /tmp/dotnet-install.sh
    /tmp/dotnet-install.sh --channel "$DOTNET_CHANNEL" --install-dir "$DOTNET_DIR"
    rm -f /tmp/dotnet-install.sh
}

# Make the freshly installed SDK visible to this session
export PATH="$DOTNET_DIR:$DOTNET_DIR/tools:$PATH"
export DOTNET_ROOT="$DOTNET_DIR"

if command -v dotnet &> /dev/null && dotnet --list-sdks 2>/dev/null | grep -q "^${DOTNET_CHANNEL%.*}\."; then
    echo ".NET SDK $DOTNET_CHANNEL already installed."
else
    install_dotnet
fi

# --- SQL command-line tools (sqlcmd) ---
install_sqlcmd() {
    case "$OS" in
        Linux)
            echo "Installing mssql-tools18 (sqlcmd)..."
            # Add the Microsoft package repository for the detected Ubuntu release
            local ubuntu_release
            ubuntu_release="$(lsb_release -rs)"
            curl -sSL -O "https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb"
            sudo dpkg -i packages-microsoft-prod.deb
            rm -f packages-microsoft-prod.deb
            sudo apt-get update
            sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
            ;;
        Darwin)
            echo "Installing sqlcmd..."
            brew install sqlcmd
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# sqlcmd may be on PATH (brew/go-sqlcmd) or at the mssql-tools18 location
if command -v sqlcmd &> /dev/null || [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
    echo "sqlcmd already installed."
else
    install_sqlcmd
fi

echo ""
echo "=== .NET setup complete! ==="
echo ""
echo "Installed:"
echo "  - .NET SDK ($DOTNET_CHANNEL) at $DOTNET_DIR"
echo "  - sqlcmd (SQL Server command-line tool)"
echo ""
echo "Restart your shell or run 'source ~/.zshrc' so 'dotnet' and 'sqlcmd' are on PATH."
