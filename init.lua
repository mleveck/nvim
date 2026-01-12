-- Set leader before plugins load
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- Load configuration modules
require('config.options')
require('config.keymaps')
require('config.autocmds')

-- Install lazy.nvim if not present
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Setup plugins
require('lazy').setup({
  { import = 'plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘', config = '🛠', event = '📅', ft = '📂',
      init = '⚙', keys = '🗝', plugin = '🔌', runtime = '💻',
      require = '🌙', source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
    },
  },
})

-- Load LSP configuration after plugins
require('config.lsp')

-- Setup local plugins
require('local-plugins.github-navigator').setup({
  keymap = '<leader>go',
  prompt_checkout = true,
  auto_focus = true,
})

-- Watch mypy output file and keep quickfix updated
--require('local-plugins.mypy_qf').start('.tmp/mypy_watch.log')

-- LLM code reference generator
require('local-plugins.llm_ref').setup({
    -- Optional: configure keymaps
     keymap_normal = '<leader>lr',
     keymap_visual = '<leader>lr',
})
