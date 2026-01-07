return {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'pyrightconfig.json', '.git' },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = 'off',
      },
    },
  },
}
