# C/C++ Language Server (clangd) Workspace Detection Fix

## Problem: clangd detects files in same folder but not entire workspace

This is a common issue where clangd can detect files in the current directory and system libraries, but fails to properly index and scan the entire workspace/project. The problem usually manifests as:

- ✅ System headers work (like `#include <iostream>`)
- ✅ Files in the same directory are detected
- ❌ Files in subdirectories are not found
- ❌ Project-wide symbol search doesn't work
- ❌ Cross-file references are incomplete

Here's how to fix it:

## Root Causes

1. **Missing compilation database** (`compile_commands.json`)
2. **Incorrect workspace root detection**
3. **No project configuration** (`.clangd` file)
4. **clangd not indexing the full workspace tree**
5. **Missing build system files that help identify project structure**

## Solutions

### 1. Generate compile_commands.json (MOST IMPORTANT)

The compilation database tells clangd about all files in your project and how to compile them:

#### For CMake projects:
```bash
mkdir build && cd build
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
cp compile_commands.json ../
```

#### For Make projects:
```bash
# Install bear first: sudo apt install bear (Ubuntu) or brew install bear (macOS)
bear -- make clean
bear -- make
```

#### For simple projects (no build system):
```bash
# Use our helper script
./docs/generate_compile_commands.sh
```

### 2. Create .clangd configuration file

Copy the example configuration to your project root:
```bash
cp docs/example-.clangd .clangd
```

This provides fallback compilation flags and workspace indexing settings.

### 3. Debug workspace detection

Use our debugging script to diagnose issues:
```bash
./docs/debug_clangd_workspace.sh
```

This will show you:
- Which project markers clangd can find
- How many C/C++ files are in your project
- What workspace root clangd would detect
- Specific recommendations for your project

### 4. Force workspace refresh

After making changes, you can force clangd to refresh:

In Neovim:
```vim
:ClangdRefreshWorkspace     " Force refresh workspace index
:ClangdWorkspaceInfo        " Show current workspace info
```

Or enable debug mode:
```bash
export CLANGD_DEBUG=1       # Enable debug logging
nvim                        # Restart editor
```

## Enhanced clangd.lua Features

The updated configuration includes:

### Better Command Line Options:
- `--compile-commands-dir=.` - Look for compile_commands.json in project root
- `--query-driver=...` - Query system compilers for include paths
- `--enable-config` - Enable .clangd config files
- `--all-scopes-completion` - Complete symbols from entire workspace

### Smarter Root Detection:
- Searches for multiple project markers
- Counts C/C++ files in directories to find project root
- Prefers directories with compilation databases
- Falls back intelligently to workspace with most source files

### Workspace Indexing:
- Forces background indexing of entire workspace
- Automatically refreshes workspace symbols
- Provides debugging commands
- Shows workspace root in notifications

### Better Include Paths:
- Automatically adds common include directories
- Queries system compilers for standard paths
- Supports relative include paths (., .., ./include, etc.)

## Troubleshooting

### Issue: "Files in subdirectories not found"

**Root Cause:** clangd doesn't know about your project structure.

**Solution:** 
1. Create `compile_commands.json` in your project root
2. Ensure it includes entries for files in all subdirectories
3. Use the generate script: `./docs/generate_compile_commands.sh`

### Issue: "Same folder works, but workspace doesn't"

**Root Cause:** clangd is detecting the wrong workspace root.

**Solution:**
1. Run `./docs/debug_clangd_workspace.sh` to see detected root
2. Add a `.clangd` file to your actual project root
3. Or create `compile_commands.json` in the project root
4. Check with `:ClangdWorkspaceInfo` in Neovim

### Issue: "Project-wide symbol search doesn't work"

**Root Cause:** clangd isn't indexing the full workspace.

**Solution:**
1. Ensure `compile_commands.json` exists and has entries for all source files
2. Verify workspace root with `:ClangdWorkspaceInfo`
3. Use `:ClangdRefreshWorkspace` to force re-indexing
4. Check `.clangd` file has `Index: Background: Build`

### Issue: "Cross-file references incomplete"

**Root Cause:** Missing compilation database or wrong include paths.

**Solution:**
1. Generate proper `compile_commands.json`
2. Add include paths to `.clangd` file:
   ```yaml
   CompileFlags:
     Add:
       - -I./src
       - -I./include
       - -I../external
   ```

## Verification Steps

1. **Check clangd attachment:**
   ```vim
   :LspInfo
   ```

2. **Verify workspace root:**
   ```vim
   :ClangdWorkspaceInfo
   ```

3. **Test workspace symbol search:**
   ```vim
   :lua vim.lsp.buf.workspace_symbol("your_function_name")
   ```

4. **Test cross-file navigation:**
   - Go to definition should work across files
   - Find references should show all usages in workspace

## Quick Setup for New Projects

1. Navigate to your C/C++ project root
2. Run: `./docs/debug_clangd_workspace.sh` (see what's missing)
3. Run: `./docs/generate_compile_commands.sh` (create compilation database)
4. Copy: `cp ./docs/example-.clangd .clangd` (add config)
5. Restart Neovim
6. Open a C/C++ file and run `:ClangdWorkspaceInfo`
7. Test with `:lua vim.lsp.buf.workspace_symbol("")`

## Performance Tips

- **Large projects:** Add exclusions to `.clangd`:
  ```yaml
  Index:
    Exclude:
      - build/
      - .git/
      - external/
      - third_party/
  ```

- **Faster indexing:** Disable system library indexing:
  ```yaml
  Index:
    StandardLibrary: false
  ```

## Debug Commands (available in C/C++ buffers)

- `:ClangdRefreshWorkspace` - Force workspace re-indexing
- `:ClangdWorkspaceInfo` - Show workspace root and configuration
- `export CLANGD_DEBUG=1` - Enable verbose logging

## References

- [clangd configuration reference](https://clangd.llvm.org/config)
- [CMake compile_commands.json](https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html)
- [bear (Build EAR)](https://github.com/rizsotto/Bear)