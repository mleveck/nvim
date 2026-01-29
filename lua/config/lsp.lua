-- Load LSP configs from lsp/ directory
local lsp_dir = vim.fn.stdpath('config') .. '/lsp'
for _, file in ipairs(vim.fn.glob(lsp_dir .. '/*.lua', false, true)) do
  local server_name = vim.fn.fnamemodify(file, ':t:r')
  local config = dofile(file)
  vim.lsp.config(server_name, config)
end

-- Enable all configured servers
vim.lsp.enable({ 'lua_ls', 'basedpyright', 'gopls', 'clangd' })

-- Helper functions for Python module-wide class search
local function find_python_module_root(filepath)
  local dir = vim.fn.fnamemodify(filepath, ':p:h')

  -- Find the immediate parent directory with __init__.py
  local init_file = dir .. '/__init__.py'
  if vim.fn.filereadable(init_file) == 1 then
    return dir
  end

  return nil
end

local function find_python_files_in_module(module_root)
  local cmd = { 'find', module_root, '-name', '*.py', '-type', 'f' }
  return vim.fn.systemlist(cmd)
end

local function get_classes_from_files(files, callback)
  local all_classes = {}

  if #files == 0 then
    callback({})
    return
  end

  -- Process files in batches to avoid "too many open files" error
  local batch_size = 25
  local current_batch = 1
  local total_batches = math.ceil(#files / batch_size)

  local function process_batch()
    local start_idx = (current_batch - 1) * batch_size + 1
    local end_idx = math.min(current_batch * batch_size, #files)
    local batch_files = {}

    for i = start_idx, end_idx do
      table.insert(batch_files, files[i])
    end

    local batch_completed = 0
    local buffers_to_unload = {}

    for _, filepath in ipairs(batch_files) do
      local bufnr = vim.fn.bufnr(filepath)
      local was_loaded = bufnr ~= -1 and vim.fn.bufloaded(bufnr) == 1

      if bufnr == -1 then
        bufnr = vim.fn.bufadd(filepath)
        vim.fn.bufload(bufnr)
        table.insert(buffers_to_unload, bufnr)
      elseif not was_loaded then
        vim.fn.bufload(bufnr)
        table.insert(buffers_to_unload, bufnr)
      end

      local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr)
      }

      vim.lsp.buf_request(bufnr, 'textDocument/documentSymbol', params, function(err, result)
        batch_completed = batch_completed + 1

        if not err and result then
          local function collect_classes(symbols)
            for _, symbol in ipairs(symbols) do
              local kind = vim.lsp.protocol.SymbolKind[symbol.kind]
              if kind == 'Class' then
                local range = symbol.range or symbol.location.range
                table.insert(all_classes, {
                  filename = filepath,
                  lnum = range.start.line + 1,
                  col = range.start.character + 1,
                  text = symbol.name,
                  detail = symbol.detail or '',
                })
              end
              if symbol.children then
                collect_classes(symbol.children)
              end
            end
          end
          collect_classes(result)
        end

        if batch_completed == #batch_files then
          -- Unload buffers we temporarily loaded
          for _, buf in ipairs(buffers_to_unload) do
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_delete(buf, { force = true, unload = true })
            end
          end

          -- Process next batch or finish
          if current_batch < total_batches then
            current_batch = current_batch + 1
            vim.schedule(process_batch)
          else
            callback(all_classes)
          end
        end
      end)
    end
  end

  process_batch()
end

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
    map('<leader>dsC', function()
      local current_file = vim.api.nvim_buf_get_name(0)
      local module_root = find_python_module_root(current_file)

      if not module_root then
        vim.notify('Not inside a Python module (no __init__.py found)', vim.log.levels.WARN)
        return
      end

      local python_files = find_python_files_in_module(module_root)

      -- Safety check: limit to avoid lockups on large modules
      local max_files = 200
      if #python_files > max_files then
        vim.notify(
          string.format('Module has %d files (limit: %d). Use <leader>ws for workspace symbols instead.',
            #python_files, max_files),
          vim.log.levels.WARN
        )
        return
      end

      vim.notify(
        string.format('Searching %d files in module: %s',
          #python_files, vim.fn.fnamemodify(module_root, ':t')),
        vim.log.levels.INFO
      )

      get_classes_from_files(python_files, function(classes)
        if #classes == 0 then
          vim.notify('No classes found in module', vim.log.levels.INFO)
          return
        end

        require('telescope.pickers').new({}, {
          prompt_title = 'Classes in Module: ' .. vim.fn.fnamemodify(module_root, ':t'),
          finder = require('telescope.finders').new_table({
            results = classes,
            entry_maker = function(entry)
              local relative_path = vim.fn.fnamemodify(entry.filename, ':~:.')
              local display_text = string.format('%s (%s)', entry.text, relative_path)

              return {
                value = entry,
                display = display_text,
                ordinal = entry.text .. ' ' .. relative_path,
                filename = entry.filename,
                lnum = entry.lnum,
                col = entry.col,
                symbol_type = 'Class',
              }
            end,
          }),
          sorter = require('telescope.config').values.prefilter_sorter {
            tag = "symbol_type",
            sorter = require('telescope.config').values.generic_sorter({}),
          },
          previewer = require('telescope.config').values.qflist_previewer({}),
        }):find()
      end)
    end, 'Module Classes')
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
