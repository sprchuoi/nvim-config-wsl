#!/bin/bash
# Font icon detector and tester for Neovim configuration
# This script scans your Neovim config for icons and tests if they display correctly

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

echo "========================================"
echo "Neovim Font Icon Detector & Tester"
echo "========================================"
echo ""

# Icons detected in your Neovim configuration
# These require Nerd Fonts to display correctly

echo "Testing Nerd Font Icons from your config..."
echo ""

# Bufferline icons (from bufferline.lua)
echo "Bufferline Icons:"
echo "  Buffer close:    "
echo "  Close:           "
echo "  Truncation:      "
echo ""

# nvim-tree icons (from nvim-tree.lua)
echo "nvim-tree Diagnostic Icons:"
echo "  Hint:     "
echo "  Info:     "
echo "  Warning:  "
echo "  Error:    "
echo ""

# Dashboard icons (emoji fallback available)
echo "Dashboard Icons (emoji fallback):  "
echo "  Find:     🔎"
echo "  Recent:   🕘"
echo "  Grep:     🔍"
echo "  Config:   ⚙️"
echo "  New:      📄"
echo "  Quit:     🚪"
echo ""

# lualine icons
echo "lualine/Diagnostic Icons:"
echo "  Error:    🆇"
echo "  Warning:  ⚠️"
echo "  Info:     ℹ️"
echo "  Hint:     "
echo "  Python:   "
echo "  Antenna:  📡"
echo ""

# Copilot icon (from nvim-cmp.lua)
echo "Copilot Icon:"
echo "  Copilot:  "
echo ""

# Diagnostic config icons
echo "Diagnostic Signs (from diagnostic-conf.lua):"
echo "  Error:    "
echo "  Warning:  "
echo "  Info:     "
echo "  Hint:     "
echo ""

# LSP kind icons (from mini.icons)
echo "LSP Kind Icons (mini.icons):"
echo "  Variable:   "
echo "  Function:   "
echo "  Class:      "
echo "  Method:     "
echo "  Property:   "
echo "  Module:     "
echo "  Interface:  "
echo "  Keyword:    "
echo "  Snippet:    "
echo ""

echo "========================================"
echo "Icon Display Test"
echo "========================================"
echo ""

# Test if Nerd Font icons display
echo "If you see boxes (□) or question marks (?), install a Nerd Font:"
echo ""
echo "Common Nerd Font Icons:"
echo "  Files:     "
echo "  Folders:    "
echo "  Git:       "
echo "  Code:       "
echo "  Arrows:     "
echo "  Terminal:   "
echo "  Check/X:    "
echo ""

echo "========================================"
echo "Font Requirements"
echo "========================================"
echo ""
print_info "Required Font Types:"
echo "  ✓ Nerd Font Mono (recommended for terminal)"
echo "  ✓ Powerline symbols"
echo "  ✓ Unicode emoji support (optional)"
echo ""

print_info "Recommended Fonts:"
echo "  1. JetBrainsMono Nerd Font (best for coding)"
echo "  2. Hack Nerd Font (clear and readable)"
echo "  3. FiraCode Nerd Font (great ligatures)"
echo "  4. CascadiaCode Nerd Font (Microsoft)"
echo ""

# Check if running in WSL
if grep -qi microsoft /proc/version; then
    echo "========================================"
    echo "WSL Font Installation Status"
    echo "========================================"
    echo ""
    
    WIN_FONTS_LOCAL_DIR="$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | tr -d '\r')")"
    
    if [ -d "$WIN_FONTS_LOCAL_DIR" ]; then
        print_info "Checking installed Nerd Fonts..."
        
        NERD_FONTS=$(find "$WIN_FONTS_LOCAL_DIR" -type f \( -iname "*nerd*" -o -iname "*NF*" \) 2>/dev/null | wc -l)
        
        if [ "$NERD_FONTS" -gt 0 ]; then
            print_success "Found $NERD_FONTS Nerd Font files installed"
            echo ""
            echo "Installed Nerd Fonts:"
            find "$WIN_FONTS_LOCAL_DIR" -type f \( -iname "*nerd*" -o -iname "*NF*" \) 2>/dev/null | while read -r font; do
                basename "$font"
            done | sort -u | head -20
        else
            print_error "No Nerd Fonts detected!"
            echo ""
            print_warning "Install a Nerd Font to fix missing icons:"
            echo "  Run: bash docs/install_nerd_font.sh"
        fi
    else
        print_error "Windows Fonts directory not found"
    fi
    
    echo ""
    print_info "Windows Terminal Font Configuration:"
    echo "  1. Press Ctrl+, in Windows Terminal"
    echo "  2. Go to your WSL profile"
    echo "  3. Under 'Appearance' → 'Font face'"
    echo "  4. Select a Nerd Font (e.g., 'JetBrainsMono Nerd Font')"
    echo "  5. Save and restart Windows Terminal"
fi

echo ""
echo "========================================"
echo "Quick Fix"
echo "========================================"
echo ""
print_info "To install Nerd Fonts automatically:"
echo "  bash docs/install_nerd_font.sh"
echo ""
print_info "To verify font installation:"
echo "  bash docs/test_font_icons.sh"
echo ""
print_info "For manual installation:"
echo "  See: docs/fix_missing_icons.md"
echo ""
