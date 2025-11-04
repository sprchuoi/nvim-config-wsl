return {
  filetypes = { "c", "cpp", "cc" },
  -- Clangd-specific settings for workspace scanning
  cmd = {
    "clangd",
    "--background-index",           -- Build index in the background for workspace
    "--clang-tidy",                  -- Enable clang-tidy diagnostics
    "--completion-style=detailed",   -- Detailed completion
    "--header-insertion=iwyu",       -- Include what you use for headers
    "--pch-storage=memory",          -- Store precompiled headers in memory
  },
  root_dir = function(fname)
    -- Find workspace root by looking for these markers
    local markers = {
      "compile_commands.json",       -- CMake compilation database
      "compile_flags.txt",           -- Compilation flags file
      ".clangd",                     -- Clangd config file
      ".git",                        -- Git repository
      "Makefile",                    -- Make project
      "CMakeLists.txt",             -- CMake project
    }
    return vim.fs.root(fname, markers)
  end,
}
