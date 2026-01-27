# dotfiles

My personal configuration files.

## Contents

- `nvim/` - Neovim configuration
- `zshrc` - Zsh shell configuration
- `starship.toml` - Starship prompt configuration
- `setup.sh` - Tool installation script (Ubuntu 24.04)

## Quick Start (Ubuntu 24.04)

```bash
# Clone the repo
git clone https://github.com/bethmaloney/dotfiles.git ~/dotfiles

# Install tools (gh, claude, starship, nvim, zsh)
chmod +x ~/dotfiles/setup.sh
~/dotfiles/setup.sh

# Symlink configs
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
```

## Tools Installed

The setup script installs:

- **gh** - GitHub CLI
- **claude** - Claude Code CLI
- **starship** - Cross-shell prompt
- **nvim** - Neovim (latest stable)
- **zsh** - Z shell
- **node** - Node.js (required for Claude Code)
