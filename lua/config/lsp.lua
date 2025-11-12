-- utils.lua must have a function utils.executable(cmd) returning true if cmd exists
local utils = require("utils")

-- Default LSP capabilities
local capabilities = require("lsp_utils").get_default_capabilities()

-- Function to attach keymaps and features per LSP
local on_attach = function(client, bufnr)
  if not client then return end

  local map = function(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.silent = true
    opts.buffer = bufnr
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  -- Go to Definition with duplicate filtering
  map("n", "gd", function()
    vim.lsp.buf.definition({
      on_list = function(options)
        local unique_defs = {}
        local seen = {}
        for _, loc in pairs(options.items) do
          local key = loc.filename .. loc.lnum
          if not seen[key] then
            seen[key] = true
            table.insert(unique_defs, loc)
          end
        end
        options.items = unique_defs

        vim.fn.setloclist(0, {}, " ", options)

        if #options.items > 1 then
          vim.cmd.lopen()
        elseif #options.items == 1 then
          vim.cmd([[silent! lfirst]])
        end
      end,
    })
  end, { desc = "Go to Definition" })

  map("n", "<C-]>", vim.lsp.buf.definition, { desc = "Go to Definition (direct)" })
  map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
  map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
  map("n", "gr", vim.lsp.buf.references, { desc = "References" })
  map("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
  map("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
  map("n", "<space>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
  map("n", "<space>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
  map("n", "<space>wa", vim.lsp.buf.add_workspace_folder, { desc = "Add Workspace Folder" })
  map("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove Workspace Folder" })
  map("n", "<space>wl", function() vim.print(vim.lsp.buf.list_workspace_folders()) end, { desc = "List Workspace Folders" })

  -- Disable Ruff hover (let Pyright handle Python navigation)
  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
    client.server_capabilities.definitionProvider = false
  end

  -- Highlight references
  if client.server_capabilities.documentHighlightProvider then
    local gid = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = gid,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = gid,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

-- List of LSP servers with executables
local enabled_lsp_servers = {
  pyright = "pyright-langserver",
  pylsp = "pylsp",
  ruff = "ruff",
  lua_ls = "lua-language-server",
  clangd = "clangd",
  vimls = "vim-language-server",
  bashls = "bash-language-server",
  yamlls = "yaml-language-server",
}

for server_name, executable in pairs(enabled_lsp_servers) do
  if utils.executable(executable) then
    local ok, server_config = pcall(require, "lsp." .. server_name)
    local config = ok and type(server_config) == "table" and vim.deepcopy(server_config) or {}
    config.capabilities = config.capabilities or capabilities
    config.on_attach = config.on_attach or on_attach
    config.flags = config.flags or { debounce_text_changes = 500 }

    require("lspconfig")[server_name].setup(config)
  else
    vim.notify(
      string.format("Executable '%s' for server '%s' not found! Server will not be enabled", executable, server_name),
      vim.log.levels.WARN,
      { title = "Nvim-config" }
    )
  end
end
