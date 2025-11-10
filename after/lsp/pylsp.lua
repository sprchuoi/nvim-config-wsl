-- Python LSP Server (pylsp) configuration
-- This is an alternative to pyright with different features
-- Install: pip install python-lsp-server pylsp-mypy python-lsp-ruff

return {
  cmd = { "pylsp" },
  filetypes = { "python" },
  settings = {
    pylsp = {
      plugins = {
        -- Disable plugins that conflict with ruff
        pycodestyle = {
          enabled = false,  -- Use ruff instead
        },
        mccabe = {
          enabled = false,
        },
        pyflakes = {
          enabled = false,  -- Use ruff instead
        },
        flake8 = {
          enabled = false,  -- Use ruff instead
        },
        autopep8 = {
          enabled = false,  -- Use ruff format instead
        },
        yapf = {
          enabled = false,
        },
        
        -- Enable useful plugins
        pylsp_mypy = {
          enabled = true,
          live_mode = true,
          strict = false,
        },
        
        -- Rope for refactoring
        rope_completion = {
          enabled = true,
        },
        rope_autoimport = {
          enabled = true,
          memory = true,
        },
        
        -- Jedi for completions
        jedi_completion = {
          enabled = true,
          include_params = true,
          include_class_objects = true,
          include_function_objects = true,
          fuzzy = false,
        },
        jedi_definition = {
          enabled = true,
          follow_imports = true,
          follow_builtin_imports = true,
        },
        jedi_hover = {
          enabled = true,
        },
        jedi_references = {
          enabled = true,
        },
        jedi_signature_help = {
          enabled = true,
        },
        jedi_symbols = {
          enabled = true,
          all_scopes = true,
        },
      },
    },
  },
  
  -- Workspace root detection
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
