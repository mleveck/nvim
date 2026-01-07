local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Python module paths in markdown
autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.bo.includeexpr = 'v:lua.python_includeexpr()'
  end,
})
