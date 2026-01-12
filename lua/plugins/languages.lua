return {
  -- Conjure for REPL-driven development (Lisps + Python)
  {
    'Olical/conjure',
    ft = { 'clojure', 'fennel', 'scheme', 'lisp', 'python' },
    init = function()
      -- Conjure configuration (must be set before plugin loads)
      vim.g['conjure#mapping#doc_word'] = false
      vim.g['conjure#mapping#prefix'] = '<localleader>p'
    end,
  },

  -- Jupytext for Jupyter notebook integration
  {
    'GCBallesteros/jupytext.nvim',
    config = true,
    lazy = false,
  },

  -- Python documentation
  { 'girishji/pythondoc.vim' },

  -- Spellcheck for programming terms
  {
    'psliwka/vim-dirtytalk',
    build = ':DirtytalkUpdate',
    config = function()
      vim.opt.spelllang = { 'en', 'programming' }
    end,
  },

  -- Smooth scrolling
  {
    'karb94/neoscroll.nvim',
    event = 'WinScrolled',
    config = function()
      require('neoscroll').setup({
        mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
        hide_cursor = true,
        stop_eof = true,
        use_local_scrolloff = false,
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
        easing_function = nil,
        pre_hook = nil,
        post_hook = nil,
      })
    end,
  },

  -- Tmux integration
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
    {"neovim/nvim-lspconfig"},
}
