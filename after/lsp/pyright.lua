-- Simplified Pyright configuration for Neovim LSP
-- Reference:
--   https://github.com/microsoft/pyright/blob/main/docs/configuration.md#diagnostic-settings-defaults

local new_capability = {
  textDocument = {
    publishDiagnostics = {
      -- Disable duplicated diagnostics (especially with Ruff)
      tagSupport = { valueSet = { 2 } },
    },
    hover = {
      contentFormat = { "plaintext" }, -- Force hover to plain text to avoid Markdown mess
      dynamicRegistration = true,
    },
  },
}

return {
  cmd = { "pyright-langserver", "--stdio" },

  settings = {
    pyright = {
      disableOrganizeImports = true, -- Let Ruff handle import sorting
      disableTaggedHints = false,
    },
    python = {
      analysis = {
        -- 🔍 General analysis behavior
        autoSearchPaths = true,
        diagnosticMode = "workspace",  -- Check all files in workspace, not just open ones
        typeCheckingMode = "standard", -- "off" | "basic" | "standard" | "strict"
        autoImportCompletions = true,
        indexing = true,

        --  Python interpreter path (auto-detect if available)
        pythonPath = vim.fn.exepath("python3") or "/usr/bin/python3",

        --  Path settings for imports and stubs
        stubPath = vim.fn.stdpath("data") .. "/lazy/python-type-stubs",
        extraPaths = {},

        --  Better navigation and type resolution
        followImports = true,
        useLibraryCodeForTypes = true,

        --  Customize diagnostics
        diagnosticSeverityOverrides = {
          reportMissingImports = "information",
          reportUnusedVariable = "warning",
          reportGeneralTypeIssues = "warning",
          deprecateTypingAliases = false,
        },

        --  Inlay hints
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = "partial",
          pytestParameters = true,
        },
      },
    },
  },

  capabilities = new_capability,

  root_dir = function(fname)
    local util = require("lspconfig.util")
    local markers = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      "Pipfile",
      "pyrightconfig.json",
      ".git",
    }

    -- Try to detect root by common Python project markers
    local root = util.root_pattern(unpack(markers))(fname)

    -- Fallback: if no marker is found, use the current working directory
    return root or vim.loop.cwd()
  end,
}
