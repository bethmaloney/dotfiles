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

# Set git pull merge strategy if not configured
if ! git config --global pull.rebase &> /dev/null; then
    echo "Setting git pull strategy to merge..."
    git config --global pull.rebase false
else
    echo "Git pull strategy already configured."
fi

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

# Install nvm and Node.js 24
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo "Installing Node.js 24..."
    nvm install 24
    nvm alias default 24
else
    echo "nvm already installed."
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Python 3
if ! command -v python3 &> /dev/null; then
    echo "Installing Python 3..."
    sudo apt-get install -y python3 python3-pip python3-venv
else
    echo "Python 3 already installed."
fi

# Install Claude Code (native installer, auto-updates)
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    echo "Claude Code installed. Run 'claude' to authenticate and start."
else
    echo "Claude Code already installed."
fi

# Configure Claude Code status line if not already set
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
if [ ! -f "$CLAUDE_SETTINGS" ]; then
    echo '{}' > "$CLAUDE_SETTINGS"
fi
if ! jq -e '.statusLine' "$CLAUDE_SETTINGS" &> /dev/null; then
    echo "Configuring Claude Code status line..."
    jq '. + {"statusLine": {"type": "command", "command": "'"$HOME"'/dotfiles/claude-statusline.sh"}}' \
        "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
else
    echo "Claude Code status line already configured."
fi

# Install Atlassian CLI (acli)
if ! command -v acli &> /dev/null; then
    echo "Installing Atlassian CLI..."
    sudo apt-get install -y wget gnupg2
    wget -nv -O- https://acli.atlassian.com/gpg/public-key.asc | sudo gpg --dearmor -o /etc/apt/keyrings/acli-archive-keyring.gpg
    sudo chmod go+r /etc/apt/keyrings/acli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/acli-archive-keyring.gpg] https://acli.atlassian.com/linux/deb stable main" | sudo tee /etc/apt/sources.list.d/acli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y acli
else
    echo "Atlassian CLI already installed."
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

# Install tmux
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    sudo apt-get install -y tmux
else
    echo "tmux already installed."
fi

# Install Zsh if not present
if ! command -v zsh &> /dev/null; then
    echo "Installing Zsh..."
    sudo apt-get install -y zsh
else
    echo "Zsh already installed."
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell..."
    sudo chsh -s $(which zsh) $USER
else
    echo "Zsh is already the default shell."
fi

# Configure git identity if not set
if [ -z "$(git config --global user.email)" ]; then
    echo ""
    read -p "Enter your git email: " git_email
    git config --global user.email "$git_email"
fi

if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your git name: " git_name
    git config --global user.name "$git_name"
fi

# Create config symlinks
echo "Creating config symlinks..."
mkdir -p ~/.config
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/tmux.conf ~/.tmux.conf
mkdir -p ~/bin
ln -sf ~/dotfiles/bin/dev ~/bin/dev

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run 'gh auth login' to authenticate with GitHub"
echo "  2. Run 'claude' to authenticate with Anthropic"
echo "  3. Restart your shell or run 'source ~/.zshrc'"
