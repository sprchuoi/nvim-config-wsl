#!/bin/bash

# Clangd Workspace Debugging Script
# Run this in your C/C++ project directory to diagnose workspace detection issues

set -e

PROJECT_DIR="${1:-$(pwd)}"
cd "$PROJECT_DIR"

echo "🔍 Clangd Workspace Detection Debugging"
echo "========================================"
echo "Project Directory: $PROJECT_DIR"
echo ""

# Check for clangd installation
echo "📋 Clangd Installation Check:"
if command -v clangd >/dev/null 2>&1; then
    CLANGD_VERSION=$(clangd --version | head -n1)
    echo "✅ clangd found: $CLANGD_VERSION"
else
    echo "❌ clangd not found in PATH"
    exit 1
fi
echo ""

# Check for project markers
echo "📁 Project Structure Analysis:"
echo ""

echo "Primary markers (highest priority):"
for marker in "compile_commands.json" "compile_flags.txt" ".clangd"; do
    if [ -f "$marker" ]; then
        echo "✅ $marker - FOUND"
        if [ "$marker" = "compile_commands.json" ]; then
            ENTRIES=$(jq '. | length' "$marker" 2>/dev/null || echo "Invalid JSON")
            echo "   └─ Entries: $ENTRIES"
        fi
    else
        echo "❌ $marker - missing"
    fi
done
echo ""

echo "Build system markers:"
for marker in "CMakeLists.txt" "Makefile" "makefile" "meson.build" "xmake.lua" "BUILD"; do
    if [ -f "$marker" ]; then
        echo "✅ $marker - FOUND"
    else
        echo "❌ $marker - missing"
    fi
done
echo ""

echo "Version control markers:"
for marker in ".git" ".hg" ".svn"; do
    if [ -d "$marker" ]; then
        echo "✅ $marker/ - FOUND"
    else
        echo "❌ $marker/ - missing"
    fi
done
echo ""

# Count C/C++ files
echo "📊 C/C++ Files Analysis:"
C_FILES=$(find . -name "*.c" -type f | wc -l)
CPP_FILES=$(find . -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -type f | wc -l)
H_FILES=$(find . -name "*.h" -type f | wc -l)
HPP_FILES=$(find . -name "*.hpp" -o -name "*.hxx" -type f | wc -l)

echo "C files: $C_FILES"
echo "C++ files: $CPP_FILES"
echo "C headers: $H_FILES"
echo "C++ headers: $HPP_FILES"
echo "Total: $((C_FILES + CPP_FILES + H_FILES + HPP_FILES))"
echo ""

if [ $((C_FILES + CPP_FILES + H_FILES + HPP_FILES)) -eq 0 ]; then
    echo "⚠️  No C/C++ files found in current directory!"
    echo "   Try running this script from your project root."
    echo ""
fi

# Show directory structure
echo "📂 Directory Structure (top 3 levels):"
tree -d -L 3 2>/dev/null || find . -type d -name ".*" -prune -o -type d -print | head -20
echo ""

# Check include paths
echo "🔗 Common Include Directories:"
for include_dir in "include" "inc" "src" "lib" "../include" "../inc"; do
    if [ -d "$include_dir" ]; then
        FILES_COUNT=$(find "$include_dir" -name "*.h" -o -name "*.hpp" | wc -l)
        echo "✅ $include_dir/ ($FILES_COUNT headers)"
    else
        echo "❌ $include_dir/ - missing"
    fi
done
echo ""

# Test clangd root detection
echo "🎯 Clangd Root Detection Test:"
if [ -f "test_file.cpp" ]; then
    echo "⚠️  test_file.cpp already exists, skipping test"
else
    # Create a temporary test file
    echo '#include <iostream>' > test_file.cpp
    echo 'int main() { return 0; }' >> test_file.cpp
    
    # Test clangd on the file (this will show what root it detects)
    echo "Testing clangd root detection..."
    timeout 10s clangd --log=verbose < test_file.cpp > clangd_test.log 2>&1 || true
    
    if [ -f "clangd_test.log" ]; then
        if grep -q "root" clangd_test.log; then
            echo "Root detection info found in log:"
            grep -i "root\|workspace" clangd_test.log | head -5
        else
            echo "No root detection info found in clangd log"
        fi
        rm -f clangd_test.log
    fi
    
    rm -f test_file.cpp
fi
echo ""

# Recommendations
echo "💡 Recommendations:"
echo ""

if [ ! -f "compile_commands.json" ] && [ ! -f ".clangd" ]; then
    echo "🔧 Create compilation database:"
    echo "   - For CMake: cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    echo "   - For Make: bear -- make"
    echo "   - For simple projects: use generate_compile_commands.sh"
    echo ""
fi

if [ ! -f ".clangd" ]; then
    echo "📝 Create .clangd config file:"
    echo "   cp path/to/nvim-config/docs/example-.clangd .clangd"
    echo ""
fi

if [ $((C_FILES + CPP_FILES + H_FILES + HPP_FILES)) -eq 0 ]; then
    echo "📁 Make sure you're in the correct project directory"
    echo ""
fi

echo "🚀 After making changes:"
echo "   1. Restart your editor"
echo "   2. Open a C/C++ file"
echo "   3. Run :LspInfo to verify clangd is attached"
echo "   4. Run :ClangdWorkspaceInfo to see workspace root"
echo ""

echo "🐛 Enable debug mode by setting CLANGD_DEBUG=1 in your environment"