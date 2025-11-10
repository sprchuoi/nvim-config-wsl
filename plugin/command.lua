-- Copy file path to clipboard
vim.api.nvim_create_user_command("CopyPath", function(context)
  local full_path = vim.fn.glob("%:p")

  local file_path = nil
  if context["args"] == "nameonly" then
    file_path = vim.fn.fnamemodify(full_path, ":t")
  end

  -- get the file path relative to project root
  if context["args"] == "relative" then
    local project_marker = { ".git", "pyproject.toml" }
    local project_root = vim.fs.root(0, project_marker)
    if project_root == nil then
      vim.print("can not find project root")
      return
    end

    file_path = vim.fn.substitute(full_path, project_root, "<project-root>", "g")
  end

  if context["args"] == "absolute" then
    file_path = full_path
  end

  vim.fn.setreg("+", file_path)
  vim.print("Filepath copied to clipboard!")
end, {
  bang = false,
  nargs = 1,
  force = true,
  desc = "Copy current file path to clipboard",
  complete = function()
    return { "nameonly", "relative", "absolute" }
  end,
})

-- JSON format part of or the whole file
vim.api.nvim_create_user_command("JSONFormat", function(context)
  local range = context["range"]
  local line1 = context["line1"]
  local line2 = context["line2"]

  if range == 0 then
    -- the command is invoked without range, then we assume whole buffer
    local cmd_str = string.format("%s,%s!python -m json.tool", line1, line2)
    vim.fn.execute(cmd_str)
  elseif range == 2 then
    -- the command is invoked with some range
    local cmd_str = string.format("%s,%s!python -m json.tool", line1, line2)
    vim.fn.execute(cmd_str)
  else
    local msg = string.format("unsupported range: %s", range)
    vim.api.nvim_echo({ { msg } }, true, { err = true })
  end
end, {
  desc = "Format JSON string",
  range = "%",
})

-- LSP workspace diagnostic commands
vim.api.nvim_create_user_command("LspWorkspaceDiag", function()
  -- Trigger workspace diagnostics for all attached LSP clients
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/diagnostic") then
      vim.notify(
        string.format("Triggering workspace diagnostics for %s", client.name),
        vim.log.levels.INFO,
        { title = "LSP" }
      )
      -- Request workspace diagnostics
      client.request("workspace/diagnostic", {}, function() end, 0)
    end
  end
end, {
  desc = "Trigger LSP workspace diagnostics",
})

vim.api.nvim_create_user_command("LspInfo", function()
  -- Show detailed LSP information
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  
  if #clients == 0 then
    vim.notify("No LSP clients attached to current buffer", vim.log.levels.WARN, { title = "LSP" })
    return
  end
  
  for _, client in ipairs(clients) do
    local info = {
      string.format("LSP Client: %s", client.name),
      string.format("Root dir: %s", client.root_dir or "N/A"),
      string.format("Workspace folders: %s", vim.inspect(client.workspace_folders or {})),
      string.format("Supports workspace diagnostics: %s", client.supports_method("textDocument/diagnostic")),
    }
    
    vim.notify(table.concat(info, "\n"), vim.log.levels.INFO, { title = "LSP Info" })
  end
end, {
  desc = "Show LSP client information and workspace folders",
})

vim.api.nvim_create_user_command("LspRestart", function()
  -- Restart all LSP clients
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  
  for _, client in ipairs(clients) do
    vim.notify(string.format("Restarting %s", client.name), vim.log.levels.INFO, { title = "LSP" })
    vim.cmd("LspStop " .. client.name)
  end
  
  vim.defer_fn(function()
    vim.cmd("edit") -- Reopen buffer to trigger LSP attach
  end, 500)
end, {
  desc = "Restart all LSP clients for current buffer",
})

-- Test Nerd Font icons
vim.api.nvim_create_user_command("TestNerdFont", function()
  local test_icons = {
    { icon = "", name = "Folder" },
    { icon = "", name = "File" },
    { icon = "", name = "Git Branch" },
    { icon = "", name = "Python" },
    { icon = "", name = "JavaScript" },
    { icon = "", name = "Lua" },
    { icon = "", name = "Modified" },
    { icon = "", name = "Check" },
    { icon = "", name = "Error" },
    { icon = "", name = "Warning" },
  }
  
  local lines = { "Nerd Font Icon Test:", "" }
  for _, item in ipairs(test_icons) do
    table.insert(lines, string.format("%s  %s", item.icon, item.name))
  end
  
  table.insert(lines, "")
  table.insert(lines, "If you see boxes or question marks instead of icons,")
  table.insert(lines, "you need to install a Nerd Font. Run the script:")
  table.insert(lines, "  bash docs/install_nerd_font.sh")
  table.insert(lines, "")
  table.insert(lines, "After installation, configure your terminal to use the Nerd Font.")
  
  -- Create a scratch buffer to display the test
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  
  -- Open in a split
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "NerdFont Test")
end, {
  desc = "Test if Nerd Font icons are displaying correctly",
})

-- Toggle Nerd Font support
vim.api.nvim_create_user_command("ToggleNerdFont", function()
  vim.g.have_nerd_font = not vim.g.have_nerd_font
  local status = vim.g.have_nerd_font and "enabled" or "disabled"
  vim.notify(
    string.format("Nerd Font support %s. Restart nvim-tree to see changes.", status),
    vim.log.levels.INFO,
    { title = "Font Config" }
  )
end, {
  desc = "Toggle Nerd Font support on/off",
})
