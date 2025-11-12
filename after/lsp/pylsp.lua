-- Python LSP Server configuration (pylsp)
-- Install with:
--   pip install "python-lsp-server[all]" pylsp-mypy python-lsp-ruff rope

-- pylsp focuses on completion/refactor via Jedi/Rope,
-- while Ruff handles linting/formatting, and Mypy handles type checking.

return {
  cmd = { "pylsp" },
  filetypes = { "python" },

  settings = {
    pylsp = {
      configurationSources = { "pylsp_mypy" },
      plugins = {
        --  Disable overlapping or redundant tools (Ruff covers lint/format)
        pycodestyle = { enabled = false },
        pyflakes    = { enabled = false },
        flake8      = { enabled = false },
        mccabe      = { enabled = false },
        autopep8    = { enabled = false },
        yapf        = { enabled = false },
        pydocstyle  = { enabled = false },

        --  Type checking (Mypy)
        pylsp_mypy = {
          enabled = true,
          live_mode = true,   -- Type check as you type
          strict = false,     -- Set to true for stricter analysis
          dmypy = false,      -- Disable daemon mode for portability
          report_progress = true,
        },

        --  Ruff (if python-lsp-ruff is installed)
        ruff = {
          enabled = true,
          extendSelect = { "E", "F", "W", "I" }, -- Error, formatting, import sort, etc.
          ignore = { "E501" },  -- Example: ignore line-length
          format = { "text" },
        },

        --  Rope: refactoring, imports, renaming
        rope_completion = { enabled = true },
        rope_autoimport = {
          enabled = true,
          memory = true,
          code_actions = true,
        },

        --  Jedi: completion, definitions, hover, references
        jedi_completion = {
          enabled = true,
          fuzzy = false,
          include_params = true,
          include_class_objects = true,
          include_function_objects = true,
        },
        jedi_definition = {
          enabled = true,
          follow_imports = true,
          follow_builtin_imports = true,
          follow_builtin_definitions = true,
        },
        jedi_hover = { enabled = true },
        jedi_references = { enabled = true },
        jedi_signature_help = { enabled = true },
        jedi_symbols = {
          enabled = true,
          all_scopes = true,
          include_import_symbols = true,
        },
      },
    },
  },

  --  Workspace root detection
  root_dir = require("lspconfig.util").root_pattern(
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git"
  ),
}
