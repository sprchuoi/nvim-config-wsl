-- settings for lua-language-server can be found on https://lulas.github.io/wiki/settings/
return {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      hint = {
        enable = true,
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
        },
        -- Enable workspace diagnostics
        maxPreload = 10000,
        preloadFileSize = 10000,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
        -- Enable workspace diagnostics (scan all files)
        workspaceDelay = 500,
      },
    },
  },
  root_dir = function(fname)
    -- Find workspace root
    local markers = { ".git", ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml" }
    return vim.fs.root(fname, markers)
  end,
}
