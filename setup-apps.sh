#!/bin/bash
set -e

echo "Setting up GUI applications..."

# Detect OS
OS="$(uname -s)"

# These apps are GUI applications installed via Homebrew Cask. They live in
# /Applications once installed. Casks are macOS-only.
CASKS=(
    claude              # Claude desktop app
    ghostty             # Terminal emulator
    microsoft-edge      # Browser
    microsoft-outlook   # Email (toggle "New Outlook" in-app for the OWA experience)
    microsoft-teams     # Chat / meetings
    visual-studio-code  # Editor
)

if [ "$OS" != "Darwin" ]; then
    echo "Homebrew Casks are macOS-only; nothing to do on $OS."
    exit 0
fi

command -v brew &> /dev/null || { echo "Homebrew required (https://brew.sh)."; exit 1; }

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &> /dev/null; then
        echo "$cask already installed."
    else
        echo "Installing $cask..."
        brew install --cask "$cask"
    fi
done

echo ""
echo "=== App setup complete! ==="
echo ""
# Company Portal is distributed through Microsoft Intune (org MDM), not Homebrew,
# so it can't be scripted here. It's usually pushed by IT or installed from the
# company portal / App Store.
echo "Note: Company Portal is managed by Intune/IT and is not installed by this script."
