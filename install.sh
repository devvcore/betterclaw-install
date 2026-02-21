#!/bin/bash
# BetterClaw — one-click installer
# curl -sL https://raw.githubusercontent.com/devvcore/betterclaw-install/main/install.sh | bash

set -e

INSTALL_DIR="$HOME/.betterclaw/app"
BIN_LINK="/usr/local/bin/claw"

echo ""
echo "  ╔══════════════════════════════╗"
echo "  ║     BetterClaw Installer     ║"
echo "  ╚══════════════════════════════╝"
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "❌ Node.js is required but not installed."
  echo ""
  if command -v brew &>/dev/null; then
    echo "   Run: brew install node"
  else
    echo "   Install from: https://nodejs.org"
  fi
  exit 1
fi

NODE_MAJOR=$(node -e "process.stdout.write(String(process.versions.node.split('.')[0]))")
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "❌ Node.js 20+ required (you have $(node -v))"
  exit 1
fi

echo "✓ Node.js $(node -v)"

# Download
echo "⬇ Downloading BetterClaw..."
TMP=$(mktemp -d)
curl -sL "https://raw.githubusercontent.com/devvcore/betterclaw-install/main/betterclaw.tgz" -o "$TMP/bc.tgz"
tar xzf "$TMP/bc.tgz" -C "$TMP"
SRC_DIR="$TMP/betterclaw"

if [ ! -f "$SRC_DIR/bin/claw" ]; then
  echo "❌ Download failed — could not find BetterClaw files."
  echo "   Make sure you have access to the repository."
  rm -rf "$TMP"
  exit 1
fi

# Install
echo "📦 Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -R "$SRC_DIR"/* "$INSTALL_DIR"/
chmod +x "$INSTALL_DIR/bin/claw"
rm -rf "$TMP"

# Remove quarantine (macOS)
if command -v xattr &>/dev/null; then
  xattr -dr com.apple.quarantine "$INSTALL_DIR" 2>/dev/null || true
fi

# Add to PATH via shell profile instead of symlink (no sudo needed)
echo "🔗 Setting up claw command..."

SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then
  SHELL_RC="$HOME/.bash_profile"
else
  SHELL_RC="$HOME/.profile"
fi

PATH_LINE='export PATH="$HOME/.betterclaw/app/bin:$PATH"'

if ! grep -q '.betterclaw/app/bin' "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# BetterClaw" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
fi

export PATH="$HOME/.betterclaw/app/bin:$PATH"

echo ""
echo "✅ BetterClaw installed!"
echo ""
echo "   Run:  source $SHELL_RC && claw init"
echo ""
