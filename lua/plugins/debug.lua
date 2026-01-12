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
    keys = {
      { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<leader>dn', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<leader>dr', function() require('dap').step_out() end, desc = 'Debug: Return/Step Out' },
      { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
      { '<leader>B', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = 'Debug: Set Breakpoint' },
      { '<leader>dt', function() require('dapui').toggle() end, desc = 'Debug: Toggle DAP UI' },
    },
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
