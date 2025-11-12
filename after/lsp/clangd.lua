return {
  filetypes = { "c", "cpp", "cc" },

  -- Clangd-specific settings for workspace scanning
  cmd = {
    "clangd",
    "--background-index",           -- Build index in the background for workspace
    "--clang-tidy",                 -- Enable clang-tidy diagnostics
    "--completion-style=detailed",  -- Detailed completion
    "--header-insertion=iwyu",      -- Include what you use for headers
    "--pch-storage=memory",         -- Store precompiled headers in memory
  },

  root_dir = function(fname)
    -- Detect project root similar to VS Code behavior
    local util = require("lspconfig.util")

    -- These are typical C/C++ project markers
    local markers = {
      "compile_commands.json",  -- CMake compilation database
      "compile_flags.txt",      -- Compilation flags file
      ".clangd",                -- Clangd config file
      "CMakeLists.txt",         -- CMake project
      "Makefile",               -- Make project
      ".git",                   -- Git repository
    }

    -- Try to detect root by markers
    local root = util.root_pattern(unpack(markers))(fname)

    -- If no marker is found, fall back to current working directory
    return root or vim.loop.cwd()
  end,
}
