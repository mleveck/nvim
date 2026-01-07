-- Load LSP configs from lsp/ directory
local lsp_dir = vim.fn.stdpath('config') .. '/lsp'
for _, file in ipairs(vim.fn.glob(lsp_dir .. '/*.lua', false, true)) do
  local server_name = vim.fn.fnamemodify(file, ':t:r')
  local config = dofile(file)
  vim.lsp.config(server_name, config)
end

-- Enable all configured servers
vim.lsp.enable({ 'lua_ls', 'basedpyright', 'gopls' })

-- LSP attach keymaps (these fire when LSP attaches to buffer)
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Navigation
    map('gd', require('telescope.builtin').lsp_definitions, 'Goto Definition')
    map('gr', require('telescope.builtin').lsp_references, 'Goto References')
    map('gI', require('telescope.builtin').lsp_implementations, 'Goto Implementation')
    map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
    map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type Definition')

    -- Symbols
    map('<leader>dss', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
    map('<leader>dsf', function()
      require('telescope.builtin').lsp_document_symbols({ symbols = { 'function', 'method' } })
    end, 'Document Symbols Functions')
    map('<leader>dsc', function()
      require('telescope.builtin').lsp_document_symbols({ symbols = { 'class' } })
    end, 'Document Symbols Classes')
    map('<leader>dsm', function()
      -- Find enclosing class using treesitter
      local node = vim.treesitter.get_node()
      while node do
        if node:type() == 'class_definition' or node:type() == 'class_declaration' then
          break
        end
        node = node:parent()
      end
      if not node then
        vim.notify('Not inside a class', vim.log.levels.WARN)
        return
      end
      local start_row, _, end_row, _ = node:range()

      -- Get document symbols and filter manually
      local params = { textDocument = vim.lsp.util.make_text_document_params() }
      vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result)
        if err or not result then return end

        local items = {}
        local function collect_methods(symbols, parent_name)
          for _, symbol in ipairs(symbols) do
            local kind = vim.lsp.protocol.SymbolKind[symbol.kind]
            local range = symbol.range or symbol.location.range
            local lnum = range.start.line

            if (kind == 'Function' or kind == 'Method') and lnum >= start_row and lnum <= end_row then
              table.insert(items, {
                filename = vim.api.nvim_buf_get_name(0),
                lnum = lnum + 1,
                col = range.start.character + 1,
                text = symbol.name,
              })
            end
            if symbol.children then
              collect_methods(symbol.children, symbol.name)
            end
          end
        end
        collect_methods(result, nil)

        if #items == 0 then
          vim.notify('No methods found in current class', vim.log.levels.INFO)
          return
        end

        require('telescope.pickers').new({}, {
          prompt_title = 'Methods in Current Class',
          finder = require('telescope.finders').new_table({
            results = items,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.text,
                ordinal = entry.text,
                filename = entry.filename,
                lnum = entry.lnum,
                col = entry.col,
              }
            end,
          }),
          sorter = require('telescope.config').values.generic_sorter({}),
          previewer = require('telescope.config').values.qflist_previewer({}),
        }):find()
      end)
    end, 'Methods in Current Class')
    map('<leader>dsa', function()
      -- Find enclosing class using treesitter
      local node = vim.treesitter.get_node()
      while node do
        if node:type() == 'class_definition' or node:type() == 'class_declaration' then
          break
        end
        node = node:parent()
      end
      if not node then
        vim.notify('Not inside a class', vim.log.levels.WARN)
        return
      end
      local start_row, _, end_row, _ = node:range()

      -- Get document symbols and filter manually
      local params = { textDocument = vim.lsp.util.make_text_document_params() }
      vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, function(err, result)
        if err or not result then return end

        local items = {}
        local kind_names = {}
        for k, v in pairs(vim.lsp.protocol.SymbolKind) do
          if type(k) == 'number' then kind_names[k] = v end
        end

        local function collect_symbols(symbols)
          for _, symbol in ipairs(symbols) do
            local range = symbol.range or symbol.location.range
            local lnum = range.start.line
            local kind = kind_names[symbol.kind] or 'Unknown'

            if lnum >= start_row and lnum <= end_row then
              table.insert(items, {
                filename = vim.api.nvim_buf_get_name(0),
                lnum = lnum + 1,
                col = range.start.character + 1,
                text = string.format('[%s] %s', kind, symbol.name),
                name = symbol.name,
              })
            end
            if symbol.children then
              collect_symbols(symbol.children)
            end
          end
        end
        collect_symbols(result)

        if #items == 0 then
          vim.notify('No symbols found in current class', vim.log.levels.INFO)
          return
        end

        require('telescope.pickers').new({}, {
          prompt_title = 'All Symbols in Current Class',
          finder = require('telescope.finders').new_table({
            results = items,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.text,
                ordinal = entry.name,
                filename = entry.filename,
                lnum = entry.lnum,
                col = entry.col,
              }
            end,
          }),
          sorter = require('telescope.config').values.generic_sorter({}),
          previewer = require('telescope.config').values.qflist_previewer({}),
        }):find()
      end)
    end, 'All Symbols in Current Class')
    map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')

    -- Actions
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('gl', function()
      vim.diagnostic.open_float({ scope = 'line', border = 'rounded' })
    end, 'Line Diagnostics')

    -- Signature help in insert mode
    vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { buffer = event.buf, desc = 'Signature Help' })

    -- Toggle inlay hints
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
      end, 'Toggle Inlay Hints')
    end

    -- Disable semantic tokens (user preference from original config)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- Heavy border style
local border = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' }

-- Configure LSP hover with border (K key)
vim.keymap.set('n', 'K', function()
  vim.lsp.buf.hover({ border = border })
end, { desc = 'Hover Documentation' })

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  severity_sort = true,
  float = { border = border },
})
