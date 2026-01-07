-- Use hard tabs instead of spaces for Go files
vim.bo.expandtab = false
vim.opt_local.list = true
vim.opt_local.listchars = {
  tab = '  ',  -- Two spaces effectively hide the tab character
  trail = '·',
  nbsp = '␣'
}-- Set tab widths
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4
