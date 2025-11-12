# This script is used to update Nvim on macOS
#!/bin/bash
set -eux

wget https://github.com/neovim/neovim/releases/download/stable/nvim-macos.tar.gz

if [[ ! -d "$HOME/tools/"  ]]; then
    mkdir -p "$HOME/tools"
fi

# Delete existing nvim installation.
# For newer release, the directory name is nvim-macos
if [[ -d "$HOME/tools/nvim-macos" ]]; then
    rm -rf "$HOME/tools/nvim-macos"
fi

# Extract the tar ball
tar zxvf nvim-macos.tar.gz -C "$HOME/tools"

rm nvim-macos.tar.gz

#######################################################################
#                    Install Nerd Font for Icons                      #
#######################################################################
echo "Installing Nerd Font for proper icon display..."

FONT_NAME="JetBrainsMono"
FONT_VERSION="v3.1.1"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_NAME}.zip"
FONTS_DIR="$HOME/Library/Fonts"
TEMP_DIR="/tmp/nerdfonts-install"
FONT_FILE="${TEMP_DIR}/${FONT_NAME}.zip"
EXTRACT_DIR="${TEMP_DIR}/${FONT_NAME}"

mkdir -p "$TEMP_DIR" "$EXTRACT_DIR"

echo "Downloading ${FONT_NAME} Nerd Font..."
if command -v curl &> /dev/null; then
    curl -L --progress-bar -o "$FONT_FILE" "$DOWNLOAD_URL" || echo "Download failed"
elif command -v wget &> /dev/null; then
    wget -q --show-progress -O "$FONT_FILE" "$DOWNLOAD_URL" || echo "Download failed"
fi

if [[ -f "$FONT_FILE" ]]; then
    echo "Extracting and installing fonts..."
    unzip -q -o "$FONT_FILE" -d "$EXTRACT_DIR"
    
    # Copy only TTF and OTF files to user Fonts directory
    find "$EXTRACT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) ! -iname "*Windows Compatible*" -exec cp {} "$FONTS_DIR/" \;
    
    rm -rf "$TEMP_DIR"
    echo "${FONT_NAME} Nerd Font installed successfully!"
    echo "Configure your terminal to use '${FONT_NAME} Nerd Font' for proper icons"
    echo "For iTerm2: Preferences → Profiles → Text → Font"
    echo "For Terminal.app: Preferences → Profiles → Font"
else
    echo "Font download failed. You can install it manually from https://www.nerdfonts.com"
fi

echo "Nvim installation complete!"
