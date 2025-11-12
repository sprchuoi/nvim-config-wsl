#!/bin/bash

# Script to generate compile_commands.json for C/C++ projects
# This helps clangd properly index your workspace

set -e

PROJECT_ROOT="${1:-$(pwd)}"
cd "$PROJECT_ROOT"

echo "Generating compile_commands.json for project at: $PROJECT_ROOT"

# Function to generate basic compile_commands.json
generate_basic_compile_commands() {
    local files=()
    
    # Find all C/C++ source files
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find . -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -print0)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No C/C++ source files found in $PROJECT_ROOT"
        return 1
    fi
    
    echo "Found ${#files[@]} C/C++ source files"
    
    # Determine compiler and flags
    local compiler=""
    local std_flag=""
    
    # Check if this is primarily C or C++
    local cpp_count=$(find . -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" | wc -l)
    local c_count=$(find . -name "*.c" | wc -l)
    
    if [ "$cpp_count" -gt 0 ]; then
        if command -v clang++ >/dev/null 2>&1; then
            compiler="clang++"
        elif command -v g++ >/dev/null 2>&1; then
            compiler="g++"
        else
            echo "No C++ compiler found!"
            return 1
        fi
        std_flag="-std=c++17"
    else
        if command -v clang >/dev/null 2>&1; then
            compiler="clang"
        elif command -v gcc >/dev/null 2>&1; then
            compiler="gcc"
        else
            echo "No C compiler found!"
            return 1
        fi
        std_flag="-std=c11"
    fi
    
    # Generate compile_commands.json
    cat > compile_commands.json << EOF
[
EOF
    
    local first=true
    for file in "${files[@]}"; do
        local absolute_path="$(realpath "$file")"
        local directory="$(dirname "$absolute_path")"
        
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> compile_commands.json
        fi
        
        cat >> compile_commands.json << EOF
  {
    "directory": "$directory",
    "command": "$compiler $std_flag -Wall -Wextra -I. -I.. -I/usr/include -I/usr/local/include -c $absolute_path",
    "file": "$absolute_path"
  }
EOF
    done
    
    echo "" >> compile_commands.json
    echo "]" >> compile_commands.json
    
    echo "Generated compile_commands.json with ${#files[@]} entries"
}

# Check if CMake project
if [ -f "CMakeLists.txt" ]; then
    echo "CMake project detected"
    
    # Create build directory if it doesn't exist
    mkdir -p build
    
    # Generate compile_commands.json using CMake
    cd build
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
    
    if [ -f "compile_commands.json" ]; then
        # Copy to project root
        cp compile_commands.json ../
        echo "Generated compile_commands.json using CMake"
    else
        echo "CMake failed to generate compile_commands.json, falling back to basic generation"
        cd ..
        generate_basic_compile_commands
    fi
    
elif [ -f "Makefile" ] || [ -f "makefile" ]; then
    echo "Make project detected"
    
    # Try to generate using bear if available
    if command -v bear >/dev/null 2>&1; then
        echo "Using bear to generate compile_commands.json"
        bear -- make clean
        bear -- make
    else
        echo "bear not found, falling back to basic generation"
        generate_basic_compile_commands
    fi
    
else
    echo "No build system detected, generating basic compile_commands.json"
    generate_basic_compile_commands
fi

# Verify the file was created
if [ -f "compile_commands.json" ]; then
    echo "✅ compile_commands.json created successfully"
    echo "📊 Entries: $(jq '. | length' compile_commands.json 2>/dev/null || echo "N/A (jq not installed)")"
    echo ""
    echo "💡 Tips:"
    echo "   - Restart your editor to pick up the new compile_commands.json"
    echo "   - clangd should now properly index your workspace"
    echo "   - You can customize compilation flags in compile_commands.json if needed"
else
    echo "❌ Failed to generate compile_commands.json"
    exit 1
fi