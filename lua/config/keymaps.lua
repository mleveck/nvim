local map = vim.keymap.set

-- Clear search highlight
map('n', '<leader>nh', '<cmd>nohlsearch<CR>')

-- Copy current file path
map('n', '<leader>cp', '<cmd>let @+ = expand("%")<CR>', { desc = 'Copy file path' })

-- Escape from insert mode
map('i', 'jj', '<Esc>')

-- Diagnostics
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix' })

-- Config shortcuts
map('n', '<leader>Lc', '<cmd>e ~/.config/nvim/init.lua<CR>', { desc = 'Edit nvim config' })
map('n', '<leader>Lp', '<cmd>e ~/.config/nvim/lua/plugins/<CR>', { desc = 'Edit nvim plugins' })

-- Terminal escape
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation (tmux-navigator will override these)
map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move to left window' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move to right window' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move to lower window' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move to upper window' })

-- Python module path navigation for gf
_G.python_includeexpr = function()
  local fname = vim.v.fname
  return fname:gsub('%.', '/') .. '.py'
end
