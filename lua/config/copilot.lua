require("copilot").setup({
  panel = {
    enabled = true,         -- Keep the Copilot panel
    auto_refresh = false,   -- Only refresh when requested
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>",
    },
    layout = {
      position = "bottom",  -- Panel at bottom
      ratio = 0.4,
    },
  },
  suggestion = {
    enabled = false,       -- Disabled, use copilot-cmp instead
    auto_trigger = false,
  },
  filetypes = {
    yaml = false,
    markdown = false,
    help = false,
    gitcommit = false,
    gitrebase = false,
    hgcommit = false,
    svn = false,
    cvs = false,
    ["."] = false,
  },
  copilot_node_command = "node", -- Node.js >= 18 required
  server_opts_overrides = {},
})
