#!/bin/bash
set -e

echo "Setting up Maestro (mobile UI test runner)..."

# Detect OS
OS="$(uname -s)"

MAESTRO_BIN="$HOME/.maestro/bin/maestro"
BREW_JDK="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

# Maestro is a JVM app and won't start without a JDK on PATH. setup.sh installs
# OpenJDK 21 on macOS and zshrc exports JAVA_HOME for it, but this script runs
# under bash, which never sources zshrc - so check the keg-only path too.
ensure_java() {
    if command -v java &> /dev/null; then
        echo "Java already available: $(java -version 2>&1 | head -1)"
        return
    fi
    if [ -x "$BREW_JDK/bin/java" ]; then
        echo "Using Homebrew OpenJDK 21."
        export JAVA_HOME="$BREW_JDK"
        export PATH="$JAVA_HOME/bin:$PATH"
        return
    fi
    echo "Maestro requires a JDK (11+), which is missing."
    if [ "$OS" = "Darwin" ]; then
        echo "Run ./setup.sh to install OpenJDK 21, then re-run this script."
    else
        echo "Install one first, e.g. sudo apt-get install -y openjdk-21-jdk"
    fi
    exit 1
}

# The official installer drops the CLI in ~/.maestro/bin, which zshrc adds to
# PATH. Re-running it upgrades in place, so only install when it's missing.
install_maestro() {
    if [ -x "$MAESTRO_BIN" ]; then
        echo "Maestro already installed (version $("$MAESTRO_BIN" --version 2>/dev/null | tail -1))."
        echo "Upgrade later with: maestro update"
        return
    fi
    echo "Installing Maestro..."
    curl -fsSL "https://get.maestro.mobile.dev" | bash
}

# iOS flows need Xcode and its simulators. Maestro drives the simulator through
# its own XCTest runner, so no separate idb_companion install is required.
check_ios_deps() {
    [ "$OS" = "Darwin" ] || return 0
    if xcode-select -p &> /dev/null; then
        echo "Xcode found at $(xcode-select -p)."
    else
        echo "Xcode not found - install it from the App Store to run iOS flows."
    fi
}

# Android flows talk to devices over adb, which ships with the Android platform
# tools. Advisory only: not every machine using Maestro targets Android.
check_android_deps() {
    if command -v adb &> /dev/null; then
        echo "adb found at $(command -v adb)."
    elif [ "$OS" = "Darwin" ]; then
        echo "adb not found - for Android flows: brew install --cask android-platform-tools"
    else
        echo "adb not found - for Android flows, install the Android platform tools."
    fi
}

ensure_java
install_maestro
check_ios_deps
check_android_deps

echo ""
echo "=== Maestro setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Restart your shell (or 'source ~/.zshrc') to pick up ~/.maestro/bin"
echo "  2. Boot a simulator/emulator, then run a flow: maestro test <flow>.yaml"
echo "  3. Explore a running app interactively with: maestro studio"
