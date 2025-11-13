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
    "--compile-commands-dir=./build",  -- Also look in build directory
    "--compile-commands-dir=./Build",  -- Also look in Build directory (Windows style)
    "--compile-commands-dir=./_build", -- Also look in _build directory
    "--compile-commands-dir=./cmake-build-debug",   -- CLion default debug build
    "--compile-commands-dir=./cmake-build-release", -- CLion default release build
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

    local cmake_markers = {
      "CMakeLists.txt",         -- CMake project root
      "CMakeCache.txt",         -- CMake build directory (look for parent with CMakeLists.txt)
      "cmake_install.cmake",    -- CMake install script
      "CMakeFiles/",            -- CMake build files directory
    }

    local project_markers = {
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

    -- Special handling for CMake projects and build directories
    local function find_cmake_root(starting_dir)
      local current = starting_dir
      while current ~= "/" do
        -- Check if current directory has CMakeLists.txt (project root)
        if vim.fn.filereadable(current .. "/CMakeLists.txt") == 1 then
          debug_log("Found CMakeLists.txt in: " .. current)
          return current
        end
        
        -- Check if current directory is a CMake build directory
        if vim.fn.filereadable(current .. "/CMakeCache.txt") == 1 then
          debug_log("Found CMakeCache.txt in: " .. current .. ", looking for source directory")
          
          -- Try to find source directory from CMakeCache.txt
          local cache_file = io.open(current .. "/CMakeCache.txt", "r")
          if cache_file then
            for line in cache_file:lines() do
              -- Look for CMAKE_HOME_DIRECTORY or CMAKE_SOURCE_DIR
              local source_dir = line:match("CMAKE_HOME_DIRECTORY:INTERNAL=(.+)")
              if not source_dir then
                source_dir = line:match("CMAKE_SOURCE_DIR:INTERNAL=(.+)")
              end
              if source_dir and vim.fn.isdirectory(source_dir) == 1 then
                debug_log("Found source directory from CMakeCache.txt: " .. source_dir)
                cache_file:close()
                return source_dir
              end
            end
            cache_file:close()
          end
          
          -- Fallback: look for CMakeLists.txt in parent directories
          local parent = vim.fn.fnamemodify(current, ":h")
          while parent ~= "/" and parent ~= current do
            if vim.fn.filereadable(parent .. "/CMakeLists.txt") == 1 then
              debug_log("Found CMakeLists.txt in parent: " .. parent)
              return parent
            end
            parent = vim.fn.fnamemodify(parent, ":h")
          end
        end
        
        current = vim.fn.fnamemodify(current, ":h")
      end
      return nil
    end

    -- Try CMake-aware detection
    local cmake_root = find_cmake_root(vim.fn.fnamemodify(fname, ":p:h"))
    if cmake_root then
      debug_log("Found CMake root: " .. cmake_root)
      
      -- Look for compile_commands.json in build directories
      local build_dirs = {"build", "Build", "_build", "cmake-build-debug", "cmake-build-release"}
      for _, build_dir in ipairs(build_dirs) do
        local build_path = cmake_root .. "/" .. build_dir
        local compile_commands = build_path .. "/compile_commands.json"
        if vim.fn.filereadable(compile_commands) == 1 then
          debug_log("Found compile_commands.json in build directory: " .. compile_commands)
          -- Copy to project root if it doesn't exist there
          local root_compile_commands = cmake_root .. "/compile_commands.json"
          if vim.fn.filereadable(root_compile_commands) == 0 then
            debug_log("Copying compile_commands.json to project root")
            vim.fn.system(string.format("cp '%s' '%s'", compile_commands, root_compile_commands))
          end
        end
      end
      
      return cmake_root
    end

    -- Try regular CMake markers
    root = util.root_pattern(unpack(cmake_markers))(fname)
    if root then 
      debug_log("Found root via CMake markers: " .. root)
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
        "-I./lib",
        "-I../lib",
        "-I./external",
        "-I../external",
        "-I./third_party",
        "-I../third_party",
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

  -- Internal function to auto-generate compile_commands.json
  setup_project = function(root_dir)
    if not root_dir then return end
    
    local compile_commands = root_dir .. "/compile_commands.json"
    
    -- If compile_commands.json already exists, we're good
    if vim.fn.filereadable(compile_commands) == 1 then
      return
    end
    
    -- Check if this is a CMake project
    local cmake_file = root_dir .. "/CMakeLists.txt"
    if vim.fn.filereadable(cmake_file) == 1 then
      -- Try to find existing build directory with compile_commands.json
      local build_dirs = {"build", "Build", "_build", "cmake-build-debug", "cmake-build-release"}
      for _, build_dir in ipairs(build_dirs) do
        local build_path = root_dir .. "/" .. build_dir
        local build_compile_commands = build_path .. "/compile_commands.json"
        if vim.fn.filereadable(build_compile_commands) == 1 then
          -- Copy existing compile_commands.json to root
          vim.fn.system(string.format("cp '%s' '%s'", build_compile_commands, compile_commands))
          return
        end
      end
      
      -- If no existing compile_commands.json found, generate one silently
      local build_dir = root_dir .. "/build"
      vim.fn.system(string.format("mkdir -p '%s'", build_dir))
      vim.fn.system(string.format("cd '%s' && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON '%s' >/dev/null 2>&1", build_dir, root_dir))
      
      local build_compile_commands = build_dir .. "/compile_commands.json"
      if vim.fn.filereadable(build_compile_commands) == 1 then
        vim.fn.system(string.format("cp '%s' '%s'", build_compile_commands, compile_commands))
      end
      return
    end
    
    -- For non-CMake projects, create a basic compile_commands.json
    local function create_basic_compile_commands()
      local files = {}
      local extensions = {"*.c", "*.cpp", "*.cc", "*.cxx"}
      
      for _, ext in ipairs(extensions) do
        local cmd = string.format("find '%s' -name '%s' -type f", root_dir, ext)
        local handle = io.popen(cmd)
        if handle then
          for file in handle:lines() do
            table.insert(files, file)
          end
          handle:close()
        end
      end
      
      if #files == 0 then return end
      
      -- Determine compiler and standard
      local compiler = "clang++"
      local std = "-std=c++17"
      
      -- Check if this is primarily a C project
      local c_files = 0
      local cpp_files = 0
      for _, file in ipairs(files) do
        if file:match("%.c$") then
          c_files = c_files + 1
        else
          cpp_files = cpp_files + 1
        end
      end
      
      if c_files > cpp_files then
        compiler = "clang"
        std = "-std=c11"
      end
      
      -- Create compile_commands.json
      local compile_db = {}
      for _, file in ipairs(files) do
        local dir = vim.fn.fnamemodify(file, ":h")
        local command = string.format("%s %s -Wall -Wextra -I. -I.. -I./include -I../include -I./src -I../src -c %s", 
                                     compiler, std, file)
        table.insert(compile_db, {
          directory = dir,
          command = command,
          file = file
        })
      end
      
      if #compile_db > 0 then
        local json_content = vim.fn.json_encode(compile_db)
        local file_handle = io.open(compile_commands, "w")
        if file_handle then
          file_handle:write(json_content)
          file_handle:close()
        end
      end
    end
    
    create_basic_compile_commands()
    
    -- Also create a basic .clangd config if it doesn't exist
    local clangd_config = root_dir .. "/.clangd"
    if vim.fn.filereadable(clangd_config) == 0 then
      local config_content = [[
CompileFlags:
  Add:
    - -std=c++17
    - -Wall
    - -Wextra
    - -I.
    - -I..
    - -I./include
    - -I../include
    - -I./src
    - -I../src
    - -I./lib
    - -I../lib
  Remove:
    - -W*

Index:
  Background: Build
  StandardLibrary: false

Diagnostics:
  ClangTidy:
    Add:
      - bugprone-*
      - performance-*
      - readability-*
    Remove:
      - readability-magic-numbers
  Suppress:
    - pp_file_not_found

Completion:
  AllScopes: true
]]
      local config_file = io.open(clangd_config, "w")
      if config_file then
        config_file:write(config_content)
        config_file:close()
      end
    end
  end,

  -- Custom on_attach to force workspace refresh and provide debugging
  on_attach = function(client, bufnr)
    -- Call the default on_attach from lsp.lua
    local lsp_config = require("config.lsp")
    if lsp_config and lsp_config.on_attach then
      lsp_config.on_attach(client, bufnr)
    end
    
    -- Auto-setup project compilation database (can be disabled)
    if vim.g.clangd_auto_setup ~= false and client and client.config.root_dir then
      vim.defer_fn(function()
        client.config.setup_project(client.config.root_dir)
      end, 500)
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
        
        -- Check for CMake info
        local cmake_info = ""
        if root then
          local cmake_lists = root .. "/CMakeLists.txt"
          local cmake_cache = root .. "/CMakeCache.txt"
          local build_compile_commands = root .. "/build/compile_commands.json"
          local root_compile_commands = root .. "/compile_commands.json"
          
          if vim.fn.filereadable(cmake_lists) == 1 then
            cmake_info = cmake_info .. "\n✅ CMakeLists.txt found"
          end
          if vim.fn.filereadable(cmake_cache) == 1 then
            cmake_info = cmake_info .. "\n✅ CMakeCache.txt found"
          end
          if vim.fn.filereadable(build_compile_commands) == 1 then
            cmake_info = cmake_info .. "\n✅ build/compile_commands.json found"
          end
          if vim.fn.filereadable(root_compile_commands) == 1 then
            cmake_info = cmake_info .. "\n✅ compile_commands.json found in root"
          end
        end
        
        vim.notify(
          string.format("clangd workspace info:\nRoot: %s\nCommand: %s%s", root, cmd, cmake_info),
          vim.log.levels.INFO,
          { title = "clangd Info" }
        )
      end
    end, { desc = "Show clangd workspace information" })

    -- Add CMake-specific commands
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdGenerateCMakeCompileCommands", function()
      if client and client.config.root_dir then
        local root = client.config.root_dir
        if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
          local build_dir = root .. "/build"
          vim.fn.system(string.format("mkdir -p '%s'", build_dir))
          
          local cmd = string.format("cd '%s' && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON '%s'", build_dir, root)
          vim.notify("Generating CMake compile commands...", vim.log.levels.INFO)
          
          vim.fn.jobstart(cmd, {
            on_exit = function(_, exit_code)
              if exit_code == 0 then
                local build_compile_commands = build_dir .. "/compile_commands.json"
                local root_compile_commands = root .. "/compile_commands.json"
                
                if vim.fn.filereadable(build_compile_commands) == 1 then
                  vim.fn.system(string.format("cp '%s' '%s'", build_compile_commands, root_compile_commands))
                  vim.notify("✅ compile_commands.json generated and copied to project root", vim.log.levels.INFO)
                  
                  -- Refresh clangd
                  vim.lsp.buf.workspace_symbol("")
                else
                  vim.notify("❌ Failed to generate compile_commands.json", vim.log.levels.ERROR)
                end
              else
                vim.notify("❌ CMake configuration failed", vim.log.levels.ERROR)
              end
            end
          })
        else
          vim.notify("❌ No CMakeLists.txt found in workspace root", vim.log.levels.ERROR)
        end
      end
    end, { desc = "Generate CMake compile_commands.json" })

    -- Add command to clean auto-generated files
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdCleanAutoGenerated", function()
      if client and client.config.root_dir then
        local root = client.config.root_dir
        local files_to_remove = {
          root .. "/compile_commands.json",
          root .. "/.clangd"
        }
        
        for _, file in ipairs(files_to_remove) do
          if vim.fn.filereadable(file) == 1 then
            vim.fn.delete(file)
            vim.notify("Removed: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
          end
        end
        
        vim.notify("Cleaned auto-generated clangd files", vim.log.levels.INFO)
      end
    end, { desc = "Clean auto-generated clangd files" })

    -- Add command to toggle auto-generation
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdToggleAutoSetup", function()
      vim.g.clangd_auto_setup = not vim.g.clangd_auto_setup
      local status = vim.g.clangd_auto_setup and "enabled" or "disabled"
      vim.notify("clangd auto-setup " .. status, vim.log.levels.INFO)
    end, { desc = "Toggle clangd auto-setup" })
  end,
}
