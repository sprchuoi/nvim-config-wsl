return {
  filetypes = { "c", "cpp", "cc", "h", "hpp" },

  -- Clangd-specific settings for workspace scanning
  cmd = {
    "clangd",
    "--background-index",              -- Build index in the background for workspace
    "--clang-tidy",                    -- Enable clang-tidy diagnostics
    "--completion-style=detailed",     -- Detailed completion
    "--header-insertion=iwyu",         -- Include what you use for headers
    "--pch-storage=memory",            -- Store precompiled headers in memory
    "--cross-file-rename",             -- Enable cross-file rename
    "--suggest-missing-includes",      -- Suggest missing includes
    "--all-scopes-completion",         -- Completion from all scopes
    "--log=verbose",                   -- Enable verbose logging for debugging
  },

  init_options = {
    clangdFileStatus = true,           -- Enable file status in LSP
    usePlaceholders = true,            -- Use placeholders in completions
    completeUnimported = true,         -- Complete unimported symbols
    semanticHighlighting = true,       -- Enable semantic highlighting
  },

  root_dir = function(fname)
    -- Detect project root similar to VS Code behavior
    local util = require("lspconfig.util")

    -- These are typical C/C++ project markers in order of preference
    local primary_markers = {
      "compile_commands.json",  -- CMake compilation database (highest priority)
      "compile_flags.txt",      -- Compilation flags file
      ".clangd",                -- Clangd config file
    }

    local project_markers = {
      "CMakeLists.txt",         -- CMake project
      "Makefile",               -- Make project
      "makefile",               -- Make project (lowercase)
      "configure.ac",           -- Autotools
      "configure.in",           -- Autotools
      "meson.build",            -- Meson build
      "build.ninja",            -- Ninja build
      "Cargo.toml",             -- Rust (sometimes mixed projects)
      "pyproject.toml",         -- Python (sometimes mixed projects)
    }

    local vcs_markers = {
      ".git",                   -- Git repository
      ".hg",                    -- Mercurial
      ".svn",                   -- SVN
    }

    -- Try primary markers first (compilation database, etc.)
    local root = util.root_pattern(unpack(primary_markers))(fname)
    if root then return root end

    -- Try project-specific markers
    root = util.root_pattern(unpack(project_markers))(fname)
    if root then return root end

    -- Try VCS markers
    root = util.root_pattern(unpack(vcs_markers))(fname)
    if root then return root end

    -- Last resort: look for any C/C++ files in parent directories
    local function find_cpp_files(dir)
      local handle = vim.loop.fs_scandir(dir)
      if handle then
        local name, type = vim.loop.fs_scandir_next(handle)
        while name do
          if type == "file" and name:match("%.c$") or name:match("%.cpp$") or name:match("%.cc$") or name:match("%.h$") or name:match("%.hpp$") then
            return true
          end
          name, type = vim.loop.fs_scandir_next(handle)
        end
      end
      return false
    end

    -- Walk up directories looking for C/C++ files
    local current_dir = vim.fn.fnamemodify(fname, ":p:h")
    while current_dir ~= "/" do
      if find_cpp_files(current_dir) then
        return current_dir
      end
      current_dir = vim.fn.fnamemodify(current_dir, ":h")
    end

    -- Final fallback to current working directory
    return vim.loop.cwd()
  end,

  -- Custom settings to improve workspace detection
  settings = {
    clangd = {
      -- Enable all diagnostics
      ["diagnostics"] = {
        ["clang-tidy"] = true,
        ["clang-diagnostic-*"] = true,
      },
      -- Fallback flags when no compile_commands.json exists
      fallbackFlags = {
        "-std=c++17",
        "-Wall",
        "-Wextra",
        "-I/usr/include",
        "-I/usr/local/include",
      },
    },
  },
}
