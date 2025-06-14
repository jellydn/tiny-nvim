#!/bin/bash

# Check if mise is installed, if not install it
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    curl https://mise.run | sh
    # Add mise to shell
    echo 'eval "$(mise activate)"' >> ~/.bashrc
    echo 'eval "$(mise activate)"' >> ~/.zshrc
    echo 'eval "$(mise activate)"' >> ~/.config/fish/config.fish
fi

# Install tools with mise first
echo "Installing tools with mise..."
mise install \
  bat@latest \
  black@latest \
  bun@latest \
  delta@latest \
  deno@latest \
  fzf@latest \
  go@latest \
  lazygit@latest \
  lua-language-server@latest \
  neovim@nightly \
  node@lts \
  rg@latest \
  ruby@latest \
  ruff@latest \
  rye@latest \
  stylua@latest \
  ffmpeg@latest \
  usage@latest \
  uv@latest \
  yarn@1.22.22

# Install Go tools
echo "Installing Go tools..."
go install golang.org/x/tools/gopls@latest
go install github.com/mgechev/revive@latest
go install mvdan.cc/sh/v3/cmd/shfmt@latest

# Install npm packages
echo "Installing npm packages..."
npm install -g \
  @antfu/ni \
  @fsouza/prettierd \
  @mermaid-js/mermaid-cli \
  @tailwindcss/language-server \
  @vtsls/language-server \
  cspell \
  oxlint \
  pnpm \
  prettier \
  rustywind \
  typescript-language-server \
  typescript \
  vscode-langservers-extracted

# Install tools with uv
echo "Installing tools with uv..."
uv tool install codespell
uv tool install isort
uv tool install pyright
uv tool install ruff

echo "All tools have been installed successfully!"
