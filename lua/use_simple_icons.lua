-- Alternative configuration for systems without Nerd Fonts
-- This uses simple ASCII characters instead of fancy icons
-- 
-- To enable this, add to your init.lua:
--   require("use_simple_icons")
--
-- Or comment it out if you have Nerd Fonts installed

-- Set flag to indicate no Nerd Font available
vim.g.have_nerd_font = false

-- Override diagnostic signs with simple ASCII characters
vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
}

-- Note: Some plugins may still use icons. You may need to configure them individually:
-- 
-- For nvim-tree.lua:
--   renderer = {
--     icons = {
--       show = {
--         file = false,
--         folder = false,
--         folder_arrow = false,
--         git = false,
--       },
--     },
--   },
--
-- For lualine.lua:
--   options = {
--     icons_enabled = false,
--   },
