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
mise use -g ruff@latest
mise use -g rye@latest
mise use -g stylua@latest
mise use -g tree-sitter@latest
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
        ghostscript
fi

# Ensure tree-sitter CLI is on PATH (required for nvim-treesitter compile on Neovim 0.11+)
echo "Ensuring tree-sitter CLI..."
if ! command -v tree-sitter &> /dev/null; then
  if command -v mise &> /dev/null; then
    mise use -g tree-sitter@latest || true
  fi
  if ! command -v tree-sitter &> /dev/null && command -v cargo &> /dev/null; then
    cargo install tree-sitter-cli
  fi
  if ! command -v tree-sitter &> /dev/null && command -v npm &> /dev/null; then
    npm install -g tree-sitter-cli
  fi
  if ! command -v tree-sitter &> /dev/null; then
    echo "Warning: tree-sitter CLI not found. Install via mise/cargo/npm."
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
# Pin typescript@5 — TS 7+ drops classic lib/tsserver.js required by typescript-language-server.
# Default TS LSP is vtsls; ts_ls remains available via vim.g.lsp_typescript_server = "ts_ls".
echo "Installing npm packages..."
npm install -g --force \
  @antfu/ni \
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
  typescript@5 \
  typescript-language-server \
  vscode-langservers-extracted

# Astral Python stack: uv (env) + ruff (lint/format LSP) + ty (type checker LSP)
echo "Installing Astral Python tools with uv..."
uv tool install codespell
uv tool install isort
uv tool install --force ruff@latest
uv tool install --force ty@latest

# Old Homebrew ruff (0.1.x) lacks `ruff server` and often shadows mise/uv on PATH.
if command -v ruff &> /dev/null; then
  if ! ruff server --help 2>&1 | grep -qi "language server"; then
    echo "Warning: $(command -v ruff) does not support 'ruff server'."
    echo "  Prefer mise/uv ruff (lsp/ruff.lua will try mise which ruff)."
    echo "  Or: brew uninstall ruff && uv tool install ruff"
  fi
fi
if ! command -v ty &> /dev/null; then
  echo "Warning: ty not on PATH. Ensure ~/.local/bin is in PATH (uv tool install ty)."
fi

echo "All tools have been installed successfully!"
