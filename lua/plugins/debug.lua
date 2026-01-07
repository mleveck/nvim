return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Required dependency for nvim-dap-ui
      'nvim-neotest/nvim-nio',

      -- Installs the debug adapters for you
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      -- Language-specific debuggers
      'leoluz/nvim-dap-go',
      'mfussenegger/nvim-dap-python',
    },
    keys = function(_, keys)
      local dap = require('dap')
      local dapui = require('dapui')
      return {
        { '<leader>dc', dap.continue, desc = 'Debug: Start/Continue' },
        { '<leader>di', dap.step_into, desc = 'Debug: Step Into' },
        { '<leader>dn', dap.step_over, desc = 'Debug: Step Over' },
        { '<leader>dr', dap.step_out, desc = 'Debug: Return/Step Out' },
        { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
        {
          '<leader>B',
          function()
            dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
          end,
          desc = 'Debug: Set Breakpoint',
        },
        { '<leader>dt', dapui.toggle, desc = 'Debug: See last session result.' },
        unpack(keys),
      }
    end,
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')

      require('mason-nvim-dap').setup({
        automatic_installation = true,
        handlers = {},
        ensure_installed = {
          'delve',
        },
      })

      -- Dap UI setup
      dapui.setup({
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      })

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- Install golang specific config
      require('dap-go').setup({
        delve = {
          detached = vim.fn.has('win32') == 0,
        },
      })

      -- Python debugger setup
      require('dap-python').setup('python')
      table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Launch Brr',
        program = 'brr/runner/runner.py',
        cwd = '${workspaceFolder}',
        args = function()
          local args_string = vim.fn.input('Arguments: ')
          return vim.split(args_string, ' +')
        end,
      })

      table.insert(dap.configurations.python, {
        type = 'python',
        request = 'launch',
        name = 'Train LLM',
        program = 'llm/apps/scoring/predictive_scoring/entrypoints/train/cli.py',
        env = { BR_PERSON = 'matt.leveck@openlabsusa.org' },
        cwd = '${workspaceFolder}',
        args = function()
          local args_string = vim.fn.input('Arguments: ')
          return vim.split(args_string, ' +')
        end,
      })
    end,
  },
}
