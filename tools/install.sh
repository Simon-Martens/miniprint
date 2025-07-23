#!/bin/bash

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/.local/share/omarchy/bin"

# Use provided path or default
INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up one level to get the project root
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Installing scripts from $PROJECT_ROOT to $INSTALL_DIR"

# Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Find all .sh files in the project root (not subdirectories)
for script in "$PROJECT_ROOT"/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script" .sh)  # Strip .sh extension
        dest_file="$INSTALL_DIR/$script_name"
        
        echo "Installing $script_name..."
        
        # Remove existing file if it exists
        if [ -f "$dest_file" ]; then
            rm "$dest_file"
            echo "  Removed existing $script_name"
        fi
        
        # Make the script executable
        chmod +x "$script"
        
        # Copy to installation directory without .sh extension
        cp "$script" "$dest_file"
        
        # Make the copied script executable too
        chmod +x "$dest_file"
        
        echo "  ✓ $script_name installed to $INSTALL_DIR"
    fi
done

echo ""
echo "Installation complete!"
echo "Scripts installed in: $INSTALL_DIR"
echo ""
echo "To use the scripts from anywhere, add this directory to your PATH:"
echo "export PATH=\"$INSTALL_DIR:\$PATH\""
echo ""
echo "Add the above line to your ~/.bashrc or ~/.zshrc to make it permanent."