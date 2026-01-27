#!/bin/bash
set -e

echo "Setting up development environment on Ubuntu 24.04..."

# Update package list
sudo apt-get update

# Install common dependencies
sudo apt-get install -y \
    curl \
    git \
    unzip \
    build-essential

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    (type -p wget >/dev/null || sudo apt-get install wget -y) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update \
    && sudo apt-get install gh -y
    echo "GitHub CLI installed. Run 'gh auth login' to authenticate."
else
    echo "GitHub CLI already installed."
fi

# Install Node.js (required for Claude Code)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js already installed."
fi

# Install Claude Code
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed. Run 'claude' to authenticate and start."
else
    echo "Claude Code already installed."
fi

# Install Starship prompt
if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship already installed."
fi

# Install Neovim (latest stable)
if ! command -v nvim &> /dev/null; then
    echo "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
else
    echo "Neovim already installed."
fi

# Install Zsh if not present
if ! command -v zsh &> /dev/null; then
    echo "Installing Zsh..."
    sudo apt-get install -y zsh
else
    echo "Zsh already installed."
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run 'gh auth login' to authenticate with GitHub"
echo "  2. Run 'claude' to authenticate with Anthropic"
echo "  3. Symlink your configs:"
echo "     ln -sf ~/dotfiles/nvim ~/.config/nvim"
echo "     ln -sf ~/dotfiles/zshrc ~/.zshrc"
echo "     ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml"
echo "  4. Restart your shell or run 'source ~/.zshrc'"
