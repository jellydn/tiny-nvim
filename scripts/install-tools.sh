#!/bin/bash

# Check if mise is installed, if not install it
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    curl https://mise.run | sh
    # Add mise to shell
    echo '' >> ~/.bashrc
    echo 'eval "$(mise activate)"' >> ~/.bashrc
    echo '' >> ~/.zshrc  
    echo 'eval "$(mise activate)"' >> ~/.zshrc
    mkdir -p ~/.config/fish
    echo '' >> ~/.config/fish/config.fish
    echo 'eval "mise activate fish | source"' >> ~/.config/fish/config.fish
    # Activate mise for current session
    eval "$(mise activate)"
fi

# Install tools with mise first (per package installation)
echo "Installing tools with mise..."
mise use -g bat@latest
mise use -g biome@latest
mise use -g black@latest
mise use -g bun@latest
mise use -g delta@latest
mise use -g difftastic@latest
mise use -g deno@latest
mise use -g dprint@latest
mise use -g fzf@latest
mise use -g fd@latest
mise use -g go@latest
mise use -g hurl@latest
mise use -g lazygit@latest
mise use -g lua-language-server@latest
mise use -g neovim@nightly
mise use -g node@lts
mise use -g rg@latest
mise use -g ruby@latest
mise use -g ruff@latest
mise use -g rye@latest
mise use -g stylua@latest
mise use -g ffmpeg@latest
mise use -g usage@latest
mise use -g uv@latest
mise use -g zoxide@latest
mise use -g yarn@1.22.22

# Note: Most tools are now handled by mise, removing manual Go tool installations

# Install system dependencies (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo "Installing system dependencies..."
    sudo apt update
    sudo apt install -y \
        trash-cli \
        imagemagick \
        ghostscript \
        tree-sitter-cli
fi

# Install tree-sitter CLI (required for nvim-treesitter on Neovim 0.11+)
echo "Installing tree-sitter CLI..."
if ! command -v tree-sitter &> /dev/null; then
  if command -v cargo &> /dev/null; then
    cargo install tree-sitter-cli
  elif command -v npm &> /dev/null; then
    npm install -g tree-sitter-cli
  else
    echo "Warning: Neither cargo nor npm found. Please install tree-sitter-cli manually."
  fi
fi

# Install gopls (Go language server) via Go
echo "Installing gopls..."
if command -v go &> /dev/null; then
  go install golang.org/x/tools/gopls@latest
else
  echo "Warning: Go not found, skipping gopls installation"
fi

# Install rust-analyzer (Rust language server)
echo "Installing rust-analyzer..."
if command -v rustup &> /dev/null; then
  rustup component add rust-analyzer
elif command -v cargo &> /dev/null; then
  cargo install rust-analyzer
elif command -v brew &> /dev/null; then
  brew install rust-analyzer
else
  echo "Warning: rustup/cargo/brew not found. Install rust-analyzer manually via: rustup component add rust-analyzer"
fi

# Install npm packages
echo "Installing npm packages..."
npm install -g --force \
  @antfu/ni \
  basedpyright \
  @fsouza/prettierd \
  @mermaid-js/mermaid-cli \
  @tailwindcss/language-server \
  @vtsls/language-server \
  cspell \
  npm-check-updates \
  oxlint \
  pnpm \
  prettier \
  rustywind \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted

# Install Python tools with uv (note: pyright is already handled by npm)
echo "Installing tools with uv..."
uv tool install codespell
uv tool install isort
uv tool install ruff

echo "All tools have been installed successfully!"
