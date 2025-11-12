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
    "--enable-config",                 -- Enable .clangd config files
    "--compile-commands-dir=.",        -- Look for compile_commands.json in project root
    "--query-driver=/usr/bin/clang*,/usr/bin/gcc*,/usr/bin/g++*", -- Query system compilers
    "--fallback-style=file",           -- Use .clang-format if available
    "--function-arg-placeholders",     -- Show argument placeholders
    "--header-insertion-decorators",   -- Decorators for header insertions
    "--ranking-model=decision_forest", -- Better ranking for completions
    "--malloc-trim",                   -- Reduce memory usage
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
    
    -- Debug function to log root detection
    local function debug_log(msg)
      if vim.env.CLANGD_DEBUG then
        vim.notify("[clangd] " .. msg, vim.log.levels.DEBUG)
      end
    end

    debug_log("Detecting root for: " .. fname)

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
      "xmake.lua",              -- XMake build
      "BUILD",                  -- Bazel build
      "WORKSPACE",              -- Bazel workspace
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
    if root then 
      debug_log("Found root via primary markers: " .. root)
      return root 
    end

    -- Try project-specific markers
    root = util.root_pattern(unpack(project_markers))(fname)
    if root then 
      debug_log("Found root via project markers: " .. root)
      return root 
    end

    -- Try VCS markers
    root = util.root_pattern(unpack(vcs_markers))(fname)
    if root then 
      debug_log("Found root via VCS markers: " .. root)
      return root 
    end

    -- Advanced detection: look for directories with multiple C/C++ files
    local function count_cpp_files(dir)
      local count = 0
      local handle = vim.loop.fs_scandir(dir)
      if handle then
        local name, type = vim.loop.fs_scandir_next(handle)
        while name do
          if type == "file" and (
            name:match("%.c$") or name:match("%.cpp$") or name:match("%.cc$") or 
            name:match("%.cxx$") or name:match("%.h$") or name:match("%.hpp$") or
            name:match("%.hxx$")
          ) then
            count = count + 1
          end
          name, type = vim.loop.fs_scandir_next(handle)
        end
      end
      return count
    end

    -- Look for the directory with the most C/C++ files (likely the project root)
    local current_dir = vim.fn.fnamemodify(fname, ":p:h")
    local best_root = current_dir
    local best_count = count_cpp_files(current_dir)
    
    debug_log("Scanning for C/C++ files, current dir has: " .. best_count)

    -- Walk up directories looking for directories with more C/C++ files
    while current_dir ~= "/" do
      local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
      if parent_dir == current_dir then break end -- Reached root
      
      local file_count = count_cpp_files(parent_dir)
      debug_log("Directory " .. parent_dir .. " has " .. file_count .. " C/C++ files")
      
      -- If parent has significantly more files, it's likely the project root
      if file_count > best_count then
        best_root = parent_dir
        best_count = file_count
      elseif file_count > 0 and file_count >= best_count then
        -- Even if same count, prefer higher directory (more likely to be root)
        best_root = parent_dir
      end
      
      current_dir = parent_dir
    end

    -- Check if Neovim's current working directory is a better choice
    local cwd = vim.loop.cwd()
    if cwd and cwd ~= best_root then
      local cwd_count = count_cpp_files(cwd)
      debug_log("CWD " .. cwd .. " has " .. cwd_count .. " C/C++ files")
      
      -- If CWD has C/C++ files and is a parent of our current best, use it
      if cwd_count > 0 and best_root:find(cwd, 1, true) == 1 then
        best_root = cwd
      end
    end

    debug_log("Selected root: " .. best_root)
    return best_root
  end,

  -- Custom settings to improve workspace detection and scanning
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
        "-I.",
        "-I..",
        "-I./include",
        "-I../include",
        "-I./src",
        "-I../src",
        "-I/usr/include",
        "-I/usr/local/include",
      },
      -- Index configuration for better workspace scanning
      index = {
        background = "Build",
        onChange = true,
        threads = 0, -- Use all available cores
      },
      -- Semantic highlighting
      semanticHighlighting = true,
      -- Cross references
      xrefs = {
        container = true,
        maxNum = 1000,
      },
    },
  },

  -- Custom on_attach to force workspace refresh and provide debugging
  on_attach = function(client, bufnr)
    -- Call the default on_attach from lsp.lua
    local lsp_config = require("config.lsp")
    if lsp_config and lsp_config.on_attach then
      lsp_config.on_attach(client, bufnr)
    end

    -- Force workspace refresh after attachment
    vim.defer_fn(function()
      if client and client.server_capabilities then
        -- Request workspace symbols to trigger indexing
        vim.lsp.buf.workspace_symbol("")
        
        -- Notify user about workspace root
        local root = client.config.root_dir
        vim.notify(
          string.format("clangd attached to buffer %d, workspace root: %s", bufnr, root or "unknown"),
          vim.log.levels.INFO,
          { title = "clangd LSP" }
        )
        
        -- Debug: Show indexing status
        if vim.env.CLANGD_DEBUG then
          vim.notify("clangd indexing status: " .. (client.server_capabilities.workspaceSymbolProvider and "enabled" or "disabled"))
        end
      end
    end, 1000)

    -- Add command to manually refresh workspace
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdRefreshWorkspace", function()
      if client then
        vim.lsp.buf.workspace_symbol("")
        vim.notify("Refreshing clangd workspace index...", vim.log.levels.INFO)
      end
    end, { desc = "Refresh clangd workspace index" })

    -- Add command to show workspace info
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdWorkspaceInfo", function()
      if client then
        local root = client.config.root_dir
        local cmd = table.concat(client.config.cmd, " ")
        vim.notify(
          string.format("clangd workspace info:\nRoot: %s\nCommand: %s", root, cmd),
          vim.log.levels.INFO,
          { title = "clangd Info" }
        )
      end
    end, { desc = "Show clangd workspace information" })
  end,
}
