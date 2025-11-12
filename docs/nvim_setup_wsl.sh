#!/bin/bash
# Neovim setup script optimized for WSL (Windows Subsystem for Linux)
# This script installs only the language servers and necessary tools

set -e  # Exit on error, but don't use -x for cleaner output

echo "====================================="
echo "Neovim LSP Setup for WSL"
echo "====================================="

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "${NC}→ $1${NC}"
}

#######################################################################
#                    Check and Install Node.js/npm                    #
#######################################################################
echo ""
print_info "Checking Node.js and npm..."

if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    print_success "Node.js $NODE_VERSION and npm $NPM_VERSION are already installed"
    NPM_CMD="npm"
else
    print_warning "Node.js/npm not found. Installing via apt..."
    sudo apt update
    sudo apt install -y nodejs npm
    NPM_CMD="npm"
fi

#######################################################################
#                    Install Node-based Language Servers              #
#######################################################################
echo ""
print_info "Installing Node.js-based language servers..."

# Check if we need sudo for global npm installs
NPM_PREFIX=$(npm config get prefix)
if [[ "$NPM_PREFIX" == "/usr" || "$NPM_PREFIX" == "/usr/local" ]]; then
    print_warning "Global npm prefix requires sudo. Installing with sudo..."
    SUDO_NPM="sudo"
else
    SUDO_NPM=""
fi

# Install yaml-language-server
if command -v yaml-language-server &> /dev/null; then
    print_success "yaml-language-server is already installed"
else
    print_info "Installing yaml-language-server..."
    $SUDO_NPM npm install -g yaml-language-server
    print_success "yaml-language-server installed"
fi

# Install pyright
if command -v pyright-langserver &> /dev/null || command -v pyright &> /dev/null; then
    print_success "pyright is already installed"
else
    print_info "Installing pyright..."
    $SUDO_NPM npm install -g pyright
    print_success "pyright installed"
fi

# Install vim-language-server
if command -v vim-language-server &> /dev/null; then
    print_success "vim-language-server is already installed"
else
    print_info "Installing vim-language-server..."
    $SUDO_NPM npm install -g vim-language-server
    print_success "vim-language-server installed"
fi

# Install bash-language-server
if command -v bash-language-server &> /dev/null; then
    print_success "bash-language-server is already installed"
else
    print_info "Installing bash-language-server..."
    $SUDO_NPM npm install -g bash-language-server
    print_success "bash-language-server installed"
fi

#######################################################################
#                    Install Python and Python-based tools            #
#######################################################################
echo ""
print_info "Checking Python installation..."

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python is installed: $PYTHON_VERSION"
else
    print_warning "Python3 not found. Installing via apt..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

# Check for pip and pipx
if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
    print_success "pip is available"
    PIP_CMD=$(command -v pip3 || command -v pip)
else
    print_warning "pip not found. Installing..."
    sudo apt install -y python3-pip
    PIP_CMD="pip3"
fi

# Check for pipx (better for installing Python CLI tools)
if ! command -v pipx &> /dev/null; then
    print_warning "pipx not found. Installing..."
    sudo apt install -y pipx
    pipx ensurepath
fi

echo ""
print_info "Installing Python-based tools..."

# Install ruff using pipx (handles externally-managed-environment)
if command -v ruff &> /dev/null; then
    print_success "ruff is already installed"
else
    print_info "Installing ruff..."
    pipx install ruff
    print_success "ruff installed"
fi

# Install pynvim (required for Neovim Python support)
print_info "Installing/updating pynvim..."
# Use --break-system-packages flag for system Python in WSL, or try with --user flag
if $PIP_CMD install --user --upgrade pynvim 2>/dev/null; then
    print_success "pynvim installed/updated"
else
    print_warning "Installing pynvim with --break-system-packages flag..."
    $PIP_CMD install --break-system-packages --upgrade pynvim
    print_success "pynvim installed/updated"
fi

#######################################################################
#                    Install lua-language-server                      #
#######################################################################
echo ""
print_info "Checking lua-language-server..."

if command -v lua-language-server &> /dev/null; then
    print_success "lua-language-server is already installed"
else
    print_info "Installing lua-language-server..."
    
    LUA_LS_INSTALL_DIR="$HOME/.local/share/lua-language-server"
    LUA_LS_VERSION="3.7.4"
    LUA_LS_TARBALL="/tmp/lua-language-server.tar.gz"
    
    # Download lua-language-server
    wget -q --show-progress \
        "https://github.com/LuaLS/lua-language-server/releases/download/$LUA_LS_VERSION/lua-language-server-$LUA_LS_VERSION-linux-x64.tar.gz" \
        -O "$LUA_LS_TARBALL"
    
    # Create directory and extract
    mkdir -p "$LUA_LS_INSTALL_DIR"
    tar -xzf "$LUA_LS_TARBALL" -C "$LUA_LS_INSTALL_DIR"
    
    # Create symlink in ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    ln -sf "$LUA_LS_INSTALL_DIR/bin/lua-language-server" "$HOME/.local/bin/lua-language-server"
    
    # Cleanup
    rm "$LUA_LS_TARBALL"
    
    print_success "lua-language-server installed to $LUA_LS_INSTALL_DIR"
fi

#######################################################################
#                    Install clangd (C/C++ Language Server)           #
#######################################################################
echo ""
print_info "Checking clangd..."

if command -v clangd &> /dev/null; then
    CLANGD_VERSION=$(clangd --version | head -n1)
    print_success "clangd is already installed: $CLANGD_VERSION"
else
    print_info "Installing clangd..."
    sudo apt update
    sudo apt install -y clangd
    print_success "clangd installed"
fi

# Optional: Install build-essential for C/C++ compilation
if command -v gcc &> /dev/null && command -v g++ &> /dev/null; then
    print_success "gcc/g++ compilers are already installed"
else
    print_warning "gcc/g++ not found. Installing build-essential..."
    sudo apt update
    sudo apt install -y build-essential
    print_success "build-essential (gcc, g++, make, etc.) installed"
fi

#######################################################################
#                    Install Nerd Font for Icons                      #
#######################################################################
echo ""
print_info "Checking Nerd Font installation..."

# Check if running in WSL
if grep -qi microsoft /proc/version; then
    WIN_FONTS_LOCAL_DIR="$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | tr -d '\r')")"
    
    # Check if any Nerd Font is installed
    NERD_FONT_INSTALLED=false
    if [ -d "$WIN_FONTS_LOCAL_DIR" ]; then
        if find "$WIN_FONTS_LOCAL_DIR" -iname "*nerd*" -o -iname "*NF*" | grep -q .; then
            NERD_FONT_INSTALLED=true
        fi
    fi
    
    if [ "$NERD_FONT_INSTALLED" = true ]; then
        print_success "Nerd Font appears to be installed"
    else
        print_warning "No Nerd Font detected. Nvim icons may not display correctly."
        echo ""
        read -p "Would you like to install JetBrainsMono Nerd Font now? (y/n) [y]: " install_font
        install_font=${install_font:-y}
        
        if [[ "$install_font" =~ ^[Yy]$ ]]; then
            # Check for unzip
            if ! command -v unzip &> /dev/null; then
                print_info "Installing unzip..."
                sudo apt update && sudo apt install -y unzip
            fi
            
            FONT_NAME="JetBrainsMono"
            FONT_VERSION="v3.1.1"
            DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_VERSION}/${FONT_NAME}.zip"
            TEMP_DIR="/tmp/nerdfonts-install"
            FONT_FILE="${TEMP_DIR}/${FONT_NAME}.zip"
            EXTRACT_DIR="${TEMP_DIR}/${FONT_NAME}"
            
            mkdir -p "$TEMP_DIR" "$EXTRACT_DIR"
            
            print_info "Downloading ${FONT_NAME} Nerd Font..."
            if command -v wget &> /dev/null; then
                wget -q --show-progress -O "$FONT_FILE" "$DOWNLOAD_URL" 2>&1 || print_error "Download failed"
            elif command -v curl &> /dev/null; then
                curl -L --progress-bar -o "$FONT_FILE" "$DOWNLOAD_URL" || print_error "Download failed"
            fi
            
            if [ -f "$FONT_FILE" ]; then
                print_info "Extracting fonts..."
                unzip -q -o "$FONT_FILE" -d "$EXTRACT_DIR"
                
                print_info "Installing fonts to Windows..."
                INSTALLED=0
                while IFS= read -r font_file; do
                    font_basename=$(basename "$font_file")
                    cp "$font_file" "$WIN_FONTS_LOCAL_DIR/" 2>/dev/null && ((INSTALLED++))
                done < <(find "$EXTRACT_DIR" -type f \( -iname "*.ttf" -o -iname "*.otf" \) ! -iname "*Windows Compatible*")
                
                rm -rf "$TEMP_DIR"
                
                if [ $INSTALLED -gt 0 ]; then
                    print_success "${FONT_NAME} Nerd Font installed ($INSTALLED files)"
                    print_warning "Remember to configure Windows Terminal to use '${FONT_NAME} Nerd Font'"
                else
                    print_error "Font installation failed"
                fi
            fi
        else
            print_info "Skipping font installation. Run 'bash docs/install_nerd_font.sh' later to install."
        fi
    fi
else
    print_warning "Not running in WSL, skipping font installation"
fi

#######################################################################
#                    Update PATH if needed                             #
#######################################################################
echo ""
print_info "Checking PATH configuration..."

# Add ~/.local/bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warning "~/.local/bin is not in PATH. Adding to ~/.bashrc"
    echo '' >> "$HOME/.bashrc"
    echo '# Add local bin to PATH for language servers' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    print_success "Added ~/.local/bin to PATH (restart shell or run: source ~/.bashrc)"
else
    print_success "~/.local/bin is already in PATH"
fi

# Add ~/.npm-global/bin to PATH if not already there (for npm global packages)
if [[ ":$PATH:" != *":$HOME/.npm-global/bin:"* ]]; then
    if [[ -d "$HOME/.npm-global/bin" ]]; then
        print_warning "~/.npm-global/bin is not in PATH. Adding to ~/.bashrc"
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.npm-global/bin:$PATH"
        print_success "Added ~/.npm-global/bin to PATH"
    fi
else
    print_success "~/.npm-global/bin is already in PATH"
fi

# Ensure pipx path is in PATH
if command -v pipx &> /dev/null; then
    pipx ensurepath --force 2>/dev/null || true
fi

#######################################################################
#                    Verify installations                              #
#######################################################################
echo ""
echo "====================================="
print_info "Verifying installations..."
echo "====================================="

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 ✓"
        return 0
    else
        print_error "$1 ✗ (not found)"
        return 1
    fi
}

# Check all language servers
check_command "lua-language-server"
check_command "yaml-language-server"
check_command "pyright-langserver" || check_command "pyright"
check_command "ruff"
check_command "vim-language-server"
check_command "bash-language-server"
check_command "clangd"

#######################################################################
#                    Install/Update Neovim Plugins                     #
#######################################################################
echo ""
print_info "Installing nvim plugins, please wait..."

if command -v nvim &> /dev/null; then
    # Update the config if it's not the git repo
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    
    if [[ -d "$NVIM_CONFIG_DIR/.git" ]]; then
        print_info "Updating Neovim config from git..."
        (cd "$NVIM_CONFIG_DIR" && git pull)
    fi
    
    # Install/update plugins using Lazy.nvim
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    print_success "Neovim plugins installed/updated"
else
    print_warning "Neovim not found. Skipping plugin installation."
    print_info "Install Neovim first, then run: nvim --headless '+Lazy! sync' +qa"
fi

echo ""
echo "====================================="
print_success "Setup complete!"
echo "====================================="
echo ""
print_info "Next steps:"
echo "  1. If PATH was updated, run: source ~/.bashrc"
echo "  2. Restart Neovim"
echo "  3. Language servers should now be available"
echo ""
print_info "To verify in Neovim, run: :checkhealth lsp"
echo ""
