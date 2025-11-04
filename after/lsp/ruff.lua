return {
  init_options = {
    -- the settings can be found here: https://docs.astral.sh/ruff/editors/settings/
    settings = {
      organizeImports = true,
    },
  },
  root_dir = function(fname)
    -- Find Python workspace root for Ruff
    local markers = {
      "pyproject.toml",
      "ruff.toml",
      ".ruff.toml",
      "setup.py",
      ".git",
    }
    return vim.fs.root(fname, markers)
  end,
}
