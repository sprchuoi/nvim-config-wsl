-- For what diagnostic is enabled in which type checking mode, check doc:
-- https://github.com/microsoft/pyright/blob/main/docs/configuration.md#diagnostic-settings-defaults
-- Currently, the pyright also has some issues displaying hover documentation:
-- https://www.reddit.com/r/neovim/comments/1gdv1rc/what_is_causeing_the_lsp_hover_docs_to_looks_like/

local new_capability = {
  -- this will remove some of the diagnostics that duplicates those from ruff, idea taken and adapted from
  -- here: https://github.com/astral-sh/ruff-lsp/issues/384#issuecomment-1989619482
  textDocument = {
    publishDiagnostics = {
      tagSupport = {
        valueSet = { 2 },
      },
    },
    hover = {
      contentFormat = { "plaintext" },
      dynamicRegistration = true,
    },
  },
}

return {
  cmd = { "pyright-langserver", "--stdio" },
  settings = {
    pyright = {
      -- disable import sorting and use Ruff for this
      disableOrganizeImports = true,
      disableTaggedHints = false,
    },
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",        -- Scan entire workspace, not just open files
        typeCheckingMode = "standard",
        useLibraryCodeForTypes = true,
        -- Automatically detect workspace root and scan all Python files
        autoImportCompletions = true,
        indexing = true,                     -- Enable workspace indexing
        -- Specify Python path explicitly
        pythonPath = vim.fn.exepath("python3") or "/usr/bin/python3",
        -- we can this setting below to redefine some diagnostics
        diagnosticSeverityOverrides = {
          deprecateTypingAliases = false,
        },
        -- inlay hint settings are provided by pylance?
        inlayHints = {
          callArgumentNames = "partial",
          functionReturnTypes = true,
          pytestParameters = true,
          variableTypes = true,
        },
      },
    },
  },
  capabilities = new_capability,
  root_dir = function(fname)
    -- Find Python workspace root by looking for these markers
    local markers = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "pyrightconfig.json",
      ".git",
    }
    return vim.fs.root(fname, markers)
  end,
}
