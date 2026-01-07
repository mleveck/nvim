return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    -- NO tag/version pin - use latest
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup({
        defaults = require('telescope.themes').get_ivy({
          file_ignore_patterns = {
            'build/lib',
          },
          mappings = {
            i = {
              ['<C-k>'] = 'move_selection_previous',
              ['<C-j>'] = 'move_selection_next',
              ['<C-U>'] = 'results_scrolling_up',
              ['<C-D>'] = 'results_scrolling_down',
              ['<C-F>'] = 'preview_scrolling_down',
              ['<C-B>'] = 'preview_scrolling_up',
              ['<C-H>'] = require('telescope.actions.layout').toggle_preview,
            },
          },
          theme = 'ivy',
        }),
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_ivy(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search Help' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search Keymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search Files' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current Word' })
      vim.keymap.set('n', '<leader>sgf', builtin.live_grep, { desc = 'Search by Grep' })
      vim.keymap.set('n', '<leader>sgs', function()
        builtin.live_grep({ fuzzy = false })
      end, { desc = 'Grep Strict' })
      vim.keymap.set('n', '<leader>sgd', function()
        builtin.live_grep({ glob_pattern = '**README.md' })
      end, { desc = 'grep READMEs' })
      vim.keymap.set('n', '<leader>sgt', function()
        builtin.live_grep({ glob_pattern = '**tests/**' })
      end, { desc = 'grep tests' })
      vim.keymap.set('n', '<leader>sgp', function()
        local conf = require('telescope.config').values
        local finders = require('telescope.finders')
        local make_entry = require('telescope.make_entry')
        local pickers = require('telescope.pickers')
        local flatten = vim.tbl_flatten

        local opts = {}
        pickers
          .new(opts, {
            prompt_title = 'Live Grep (append two spaces + glob for filtering)',
            finder = finders.new_job(function(prompt)
              if not prompt or prompt == '' then
                return nil
              end

              local search_term, glob_pattern
              local double_space_pos = prompt:find('  ')

              if double_space_pos then
                search_term = prompt:sub(1, double_space_pos - 1)
                glob_pattern = prompt:sub(double_space_pos + 2)
              else
                search_term = prompt
              end

              local vimgrep_arguments = flatten({
                conf.vimgrep_arguments,
              })

              if glob_pattern and glob_pattern ~= '' then
                table.insert(vimgrep_arguments, '--glob')
                table.insert(vimgrep_arguments, glob_pattern)
              end

              return flatten({
                vimgrep_arguments,
                '--',
                search_term,
              })
            end, make_entry.gen_from_vimgrep(opts), opts.max_results, opts.cwd),
            previewer = conf.grep_previewer(opts),
            sorter = require('telescope.sorters').empty(),
          })
          :find()
      end, { desc = 'grep with pattern' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search Diagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search Resume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_ivy({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = 'Fuzzily search in current buffer' })

      -- Live grep in open files
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep({
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        })
      end, { desc = 'Search in Open Files' })

      -- Search Neovim config files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files({ cwd = vim.fn.stdpath('config') })
      end, { desc = 'Search Neovim files' })
      vim.keymap.set('n', '<leader>sc', function()
        builtin.find_files({ cwd = '~/.config' })
      end, { desc = 'Search Config files' })
    end,
  },
}
