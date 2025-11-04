#!/bin/bash
# Automatic Nerd Font installer for WSL
# This downloads and installs fonts directly to Windows from WSL

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

echo -e "${BLUE}====================================="
echo "Nerd Font Auto-Installer for WSL"
echo -e "=====================================${NC}"
echo ""

# Check if running in WSL
if ! grep -qi microsoft /proc/version; then
    print_error "This script is designed for WSL (Windows Subsystem for Linux)"
    exit 1
fi

# Check for required tools
if ! command -v unzip &> /dev/null; then
    print_warning "unzip not found. Installing..."
    sudo apt update && sudo apt install -y unzip
fi

if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    print_warning "wget/curl not found. Installing wget..."
    sudo apt update && sudo apt install -y wget
fi

# Available fonts
echo "Available Nerd Fonts:"
echo "  1) JetBrainsMono (recommended - clean, modern)"
echo "  2) Hack (clear, readable)"
echo "  3) FiraCode (great ligatures)"
echo "  4) CascadiaCode (Microsoft's font)"
echo "  5) Meslo (popular)"
echo ""

read -p "Choose a font (1-5) [1]: " choice
choice=${choice:-1}

# Set font based on choice
case $choice in
    1) FONT_NAME="JetBrainsMono" ;;
    2) FONT_NAME="Hack" ;;
    3) FONT_NAME="FiraCode" ;;
    4) FONT_NAME="CascadiaCode" ;;
    5) FONT_NAME="Meslo" ;;
    *) echo "Invalid choice, using JetBrainsMono"; FONT_NAME="JetBrainsMono" ;;
esac

FONT_VERSION="v3.1.1"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_NAME}.zip"
TEMP_DIR="/tmp/nerdfonts-install"
FONT_FILE="${TEMP_DIR}/${FONT_NAME}.zip"
EXTRACT_DIR="${TEMP_DIR}/${FONT_NAME}"

# Get Windows Fonts directory path
WIN_FONTS_DIR="/mnt/c/Windows/Fonts"
WIN_FONTS_LOCAL_DIR="$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | tr -d '\r')")"

# Create temp directory
mkdir -p "$TEMP_DIR"
mkdir -p "$EXTRACT_DIR"

echo ""
print_info "Downloading ${FONT_NAME} Nerd Font..."
echo "URL: $DOWNLOAD_URL"
echo ""

# Download the font
if command -v wget &> /dev/null; then
    wget -q --show-progress -O "$FONT_FILE" "$DOWNLOAD_URL" || {
        print_error "Download failed!"
        exit 1
    }
elif command -v curl &> /dev/null; then
    curl -L --progress-bar -o "$FONT_FILE" "$DOWNLOAD_URL" || {
        print_error "Download failed!"
        exit 1
    }
fi

print_success "Download complete!"

# Extract the font
print_info "Extracting fonts..."
unzip -q -o "$FONT_FILE" -d "$EXTRACT_DIR"

# Count font files
FONT_FILES=$(find "$EXTRACT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) ! -iname "*Windows Compatible*" | wc -l)
print_success "Found $FONT_FILES font files"

# Install fonts
echo ""
print_info "Installing fonts to Windows..."

# Try to install to user fonts directory (no admin required)
if [ -d "$WIN_FONTS_LOCAL_DIR" ]; then
    print_info "Installing to user fonts directory..."
    
    # Copy TTF and OTF files, excluding "Windows Compatible" versions
    INSTALLED=0
    FAILED=0
    while IFS= read -r font_file; do
        font_basename=$(basename "$font_file")
        if cp "$font_file" "$WIN_FONTS_LOCAL_DIR/" 2>/dev/null; then
            ((INSTALLED++))
            echo -n "."
        else
            ((FAILED++))
        fi
    done < <(find "$EXTRACT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) ! -iname "*Windows Compatible*")
    
    echo ""
    
    if [ $INSTALLED -gt 0 ]; then
        print_success "Installed $INSTALLED font files to user fonts directory"
        
        # Note: Registry registration is optional and may fail silently
        # Windows will still recognize fonts in the Fonts directory
        print_info "Fonts installed successfully!"
    else
        print_error "Failed to install fonts ($FAILED files failed)"
        print_info "Fonts downloaded to: $EXTRACT_DIR"
        print_info "Please install manually from Windows Explorer"
        exit 1
    fi
    
else
    print_error "Windows fonts directory not found"
    print_info "Fonts downloaded to: $EXTRACT_DIR"
    print_info "Please install manually from Windows Explorer"
    exit 1
fi

# Cleanup
print_info "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
print_success "Cleanup complete!"

echo ""
echo -e "${GREEN}====================================="
echo "Installation Complete!"
echo -e "=====================================${NC}"
echo ""
print_success "${FONT_NAME} Nerd Font has been installed!"
echo ""
print_info "Next Steps:"
echo "  1. Close and reopen Windows Terminal"
echo "  2. Open Windows Terminal settings (Ctrl+,)"
echo "  3. Go to your WSL profile (e.g., Ubuntu)"
echo "  4. Under 'Appearance' → 'Font face'"
echo "  5. Select '${FONT_NAME} Nerd Font' or '${FONT_NAME}NF'"
echo "  6. Save and restart Windows Terminal"
echo "  7. Open Neovim - icons should now display correctly!"
echo ""
print_warning "Note: You may need to restart Windows Terminal for fonts to appear in the list"
echo ""
print_info "To verify icons in terminal, run:"
echo "  echo -e \"\\ue0b0 \\ue0b2 \\uf015 \\uf013 \\uf07b \\uf121 \\uf120\""
echo ""
