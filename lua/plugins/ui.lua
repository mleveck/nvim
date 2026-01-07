return {
  -- Which-key for pending keybinds
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    config = function()
      require('which-key').setup({
        win = { border = { '─', '─', '─', ' ', ' ', ' ', ' ', ' ' } },
      })

      -- Document existing key chains
      require('which-key').add({
        { '<leader>c', group = '[C]ode' },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      })
    end,
  },

  -- Neo-tree file browser
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '<leader>e', ':Neotree toggle<CR>', desc = 'NeoTree reveal' },
    },
    opts = {
      filesystem = {
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        hijack_netrw_behavior = 'open_current',
      },
      buffers = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
      },
    },
  },

  -- Alabaster colorscheme
  {
    'p00f/alabaster.nvim',
    priority = 1000,
    config = function()
      vim.g.alabaster_floatborder = true
      vim.cmd.colorscheme('alabaster')
    end,
  },

  -- Zen mode for distraction-free editing
  {
    'folke/zen-mode.nvim',
    config = function()
      vim.keymap.set('n', '<leader>wo', '<cmd>ZenMode<cr>', { desc = 'Toggle Zenmode' })
    end,
  },
}
