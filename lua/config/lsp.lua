local utils = require("utils")
local capabilities = require("lsp_utils").get_default_capabilities()

local on_attach = function(client, bufnr)
  if not client then return end

  local map = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = true
    opts.buffer = bufnr
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  -- Go to Definition
  map("n", "gd", function()
    vim.lsp.buf.definition({
      on_list = function(options)
        local seen, unique = {}, {}
        for _, loc in ipairs(options.items or {}) do
          local key = loc.filename .. loc.lnum
          if not seen[key] then
            seen[key] = true
            table.insert(unique, loc)
          end
        end
        options.items = unique
        vim.fn.setloclist(0, {}, " ", options)
        if #unique > 1 then
          vim.cmd.lopen()
        elseif #unique == 1 then
          vim.cmd([[silent! lfirst]])
        end
      end,
    })
  end, { desc = "Go to Definition" })

  map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
  map("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
  map("n", "gr", vim.lsp.buf.references, { desc = "References" })
  map("n", "<space>rn", vim.lsp.buf.rename, { desc = "Rename" })

  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
    client.server_capabilities.definitionProvider = false
  end
end

-- List of LSP servers
local servers = {
  pyright = "pyright-langserver",
  pylsp = "pylsp",
  ruff = "ruff",
  lua_ls = "lua-language-server",
  clangd = "clangd",
  vimls = "vim-language-server",
  bashls = "bash-language-server",
  yamlls = "yaml-language-server",
}

for name, exe in pairs(servers) do
  if utils.executable(exe) then
    local ok, user_conf = pcall(require, "lsp." .. name)
    local config = ok and user_conf or {}

    config.name = name
    config.cmd = config.cmd or { exe }
    config.capabilities = config.capabilities or capabilities
    config.on_attach = config.on_attach or on_attach
    config.flags = config.flags or { debounce_text_changes = 500 }

    -- Register it with Neovim's new LSP config API (for :LspStart etc.)
    vim.lsp.configs = vim.lsp.configs or {}
    vim.lsp.configs[name] = config

    -- Start it if the buffer matches (for startup use cases)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "python", "lua", "c", "cpp", "bash", "yaml", "vim" },
      callback = function()
        if vim.bo.filetype == "python" and (name == "pyright" or name == "ruff" or name == "pylsp") then
          vim.lsp.start(config)
        elseif vim.bo.filetype == "lua" and name == "lua_ls" then
          vim.lsp.start(config)
        elseif vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
          if name == "clangd" then vim.lsp.start(config) end
        elseif vim.bo.filetype == "bash" and name == "bashls" then
          vim.lsp.start(config)
        elseif vim.bo.filetype == "yaml" and name == "yamlls" then
          vim.lsp.start(config)
        elseif vim.bo.filetype == "vim" and name == "vimls" then
          vim.lsp.start(config)
        end
      end,
    })
  else
    vim.notify(
      string.format("Skipping %s — executable '%s' not found", name, exe),
      vim.log.levels.WARN,
      { title = "LSP Setup" }
    )
  end
end
