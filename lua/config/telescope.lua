local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Telescope not found. Install 'nvim-telescope/telescope.nvim' to enable fuzzy finding.", vim.log.levels.WARN)
  return
end

local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

telescope.setup {
  defaults = {
    mappings = {
      i = { ["<esc>"] = actions.close },
    },
  },
}

-- Keymaps for Telescope (replaces previous mappings)
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Fuzzy grep files" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Fuzzy grep tags in help files" })
vim.keymap.set("n", "<leader>ft", "<cmd>Telescope current_buffer_tags<cr>", { desc = "Fuzzy search buffer tags" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Fuzzy search opened buffers" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy search opened files history" })

return telescope
