# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository managing a complete development environment for Ubuntu 24.04 LTS. Configurations are symlinked from this repo to their expected locations.

## Setup

Run `./setup.sh` to install tools and dependencies. The script is idempotent (safe to run multiple times) and will:
- Install core tools: gh, claude CLI, starship, nvim, zsh, node (via nvm), python3, tmux
- Prompt for git identity if not configured
- Set zsh as default shell

After running setup, create symlinks:
```bash
ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/tmux.conf ~/.tmux.conf
```

## Configuration Files

| File | Purpose |
|------|---------|
| `nvim/init.lua` | Neovim config with Lazy.nvim plugin management |
| `zshrc` | Zsh shell config with aliases, PATH, vi-mode |
| `starship.toml` | Cross-shell prompt with git status |
| `tmux.conf` | Terminal multiplexer (prefix: Ctrl+a) |
| `.claude/settings.json` | Claude Code permission allowlist |

## Neovim Details

Uses Lazy.nvim for plugin management. After modifying `nvim/init.lua`, run `:Lazy sync` in Neovim to update plugins.

Key plugins: Catppuccin theme, Telescope (fuzzy finder), Neo-tree (file explorer), LSP with Mason, Treesitter, Rustaceanvim.

Leader key is Space. Common bindings: `<leader>ff` find files, `<leader>fg` live grep, `<leader>e` file explorer.

## Adding New Tools

Follow the pattern in `setup.sh`:
1. Check if tool is already installed
2. Install if missing
3. Keep the script idempotent

## Theme

All configs use Catppuccin Mocha colorscheme for visual consistency across tmux, Neovim, and Starship.
