local M = {}

-- Cache for fixture definitions
local fixture_cache = {}
local cache_dirty = true

-- Function to refresh the fixture cache
local function refresh_fixture_cache()
  fixture_cache = {}

  -- Use ripgrep to find all pytest fixtures
  local cmd = {
    'rg',
    '--vimgrep',
    '-U',
    '-A1',
    '@pytest\\.fixture',
  }

  local output = vim.fn.systemlist(cmd)

  local i = 1
  while i <= #output do
    local line = output[i]

    -- Skip separator lines
    if line ~= '--' then
      -- Check if this is a fixture decorator line
      local filename, lnum, col, text = line:match '([^:]+):(%d+):(%d+):(.*)'
      if filename and text and text:match '@pytest%.fixture' then
        -- Look for the next line which should be the function definition
        if i + 1 <= #output then
          local next_line = output[i + 1]
          -- Parse the function definition line (format: filename-line-def func_name():)
          local func_filename, func_lnum, func_text = next_line:match '([^%-]+)%-(%d+)%-(.*)'

          if func_filename and func_lnum and func_text and func_text:match 'def ' then
            -- Extract function name
            local func_name = func_text:match 'def%s+([%w_]+)'
            if func_name then
              local fixture_info = {
                filename = func_filename,
                lnum = tonumber(func_lnum),
                col = 1, -- Function definitions start at column 1
                text = func_text:gsub('^%s*', ''), -- trim leading whitespace
              }

              -- Store as list to handle multiple fixtures with same name
              if not fixture_cache[func_name] then
                fixture_cache[func_name] = {}
              end
              table.insert(fixture_cache[func_name], fixture_info)
            end
          end
          -- Skip the function definition line since we processed it
          i = i + 1
        end
      end
    end

    i = i + 1
  end

  cache_dirty = false
end

-- Function to jump to fixture definition
function M.goto_fixture(fixture_name)
  -- Get the fixture name from parameter or word under cursor
  local word = fixture_name or vim.fn.expand '<cword>'

  if not word or word == '' then
    vim.notify('No fixture name provided and no word under cursor', vim.log.levels.WARN)
    return
  end

  -- Refresh cache if needed
  if cache_dirty then
    refresh_fixture_cache()
  end

  -- Look up the fixture
  local fixtures = fixture_cache[word]
  if not fixtures or #fixtures == 0 then
    vim.notify(string.format('Fixture "%s" not found', word), vim.log.levels.WARN)
    return
  end

  -- If only one fixture, jump directly
  if #fixtures == 1 then
    local fixture = fixtures[1]
    vim.cmd('edit ' .. fixture.filename)
    vim.api.nvim_win_set_cursor(0, { fixture.lnum, fixture.col - 1 })
    vim.notify(string.format('Jumped to fixture: %s', word), vim.log.levels.INFO)
    return
  end

  -- Multiple fixtures - apply smart selection logic
  local current_file = vim.fn.expand '%:p'
  local current_dir = vim.fn.expand '%:p:h'

  -- 1. Check if one of the fixtures is in the current file
  for _, fixture in ipairs(fixtures) do
    local fixture_file = vim.fn.fnamemodify(fixture.filename, ':p')
    if fixture_file == current_file then
      vim.cmd('edit ' .. fixture.filename)
      vim.api.nvim_win_set_cursor(0, { fixture.lnum, fixture.col - 1 })
      vim.notify(string.format('Jumped to fixture "%s" in current file', word), vim.log.levels.INFO)
      return
    end
  end

  -- 2. Check if any fixture module is imported in current file
  local current_file_content = vim.fn.readfile(current_file)
  local imported_modules = {}

  -- Parse imports to find imported modules
  for _, line in ipairs(current_file_content) do
    -- Match from imports
    local from_module = line:match 'from%s+([%w%./_]+)%s+import'
    if from_module then
      local module_file = from_module:gsub('%.', '/') .. '.py'
      imported_modules[module_file] = true

      -- Handle relative imports
      if from_module:match '^%.' then
        local relative_path = from_module:gsub('^%.+', ''):gsub('%.', '/') .. '.py'
        imported_modules[relative_path] = true
      end
    end

    -- Match direct imports
    local import_module = line:match 'import%s+([%w%./_]+)'
    if import_module then
      local module_file = import_module:gsub('%.', '/') .. '.py'
      imported_modules[module_file] = true
    end
  end

  -- Check if any fixture comes from an imported module
  for _, fixture in ipairs(fixtures) do
    local fixture_path = fixture.filename

    -- Check direct match
    if imported_modules[fixture_path] then
      vim.cmd('edit ' .. fixture.filename)
      vim.api.nvim_win_set_cursor(0, { fixture.lnum, fixture.col - 1 })
      vim.notify(string.format('Jumped to fixture "%s" from imported module', word), vim.log.levels.INFO)
      return
    end

    -- Check if the fixture file matches any imported module pattern
    for module_pattern, _ in pairs(imported_modules) do
      if fixture_path:find(module_pattern, 1, true) then
        vim.cmd('edit ' .. fixture.filename)
        vim.api.nvim_win_set_cursor(0, { fixture.lnum, fixture.col - 1 })
        vim.notify(string.format('Jumped to fixture "%s" from imported module', word), vim.log.levels.INFO)
        return
      end
    end
  end

  -- 3. Check for conftest.py files in the same directory or parent directories
  local conftest_fixtures = {}
  for _, fixture in ipairs(fixtures) do
    local fixture_dir = vim.fn.fnamemodify(fixture.filename, ':p:h')
    local fixture_basename = vim.fn.fnamemodify(fixture.filename, ':t')

    if fixture_basename == 'conftest.py' then
      -- Check if this conftest.py is in current directory or a parent
      if current_dir:find(fixture_dir, 1, true) == 1 or fixture_dir:find(current_dir, 1, true) == 1 then
        table.insert(conftest_fixtures, fixture)
      end
    end
  end

  -- If we found conftest fixtures, prefer the closest one
  if #conftest_fixtures > 0 then
    -- Sort by directory depth (closer to current file first)
    table.sort(conftest_fixtures, function(a, b)
      local a_dir = vim.fn.fnamemodify(a.filename, ':p:h')
      local b_dir = vim.fn.fnamemodify(b.filename, ':p:h')
      local a_depth = select(2, a_dir:gsub('/', ''))
      local b_depth = select(2, b_dir:gsub('/', ''))
      return a_depth > b_depth -- Higher depth = closer to current file
    end)

    local fixture = conftest_fixtures[1]
    vim.cmd('edit ' .. fixture.filename)
    vim.api.nvim_win_set_cursor(0, { fixture.lnum, fixture.col - 1 })
    vim.notify(string.format('Jumped to fixture "%s" from conftest.py', word), vim.log.levels.INFO)
    return
  end

  -- 4. Fall back to quickfix list for all fixtures
  local qf_items = {}
  for _, fixture in ipairs(fixtures) do
    table.insert(qf_items, {
      filename = fixture.filename,
      lnum = fixture.lnum,
      col = fixture.col,
      text = fixture.text,
    })
  end

  vim.fn.setqflist(qf_items, 'r')
  vim.cmd 'copen'
  vim.notify(string.format('Found %d fixtures named "%s" - use :cnext/:cprev to navigate', #fixtures, word), vim.log.levels.INFO)
end

-- Function to list all fixtures (for debugging/exploration)
function M.list_fixtures()
  if cache_dirty then
    refresh_fixture_cache()
  end

  local qf_items = {}
  for name, fixture_list in pairs(fixture_cache) do
    for _, info in ipairs(fixture_list) do
      table.insert(qf_items, {
        filename = info.filename,
        lnum = info.lnum,
        col = info.col,
        text = info.text,
      })
    end
  end

  if #qf_items == 0 then
    vim.notify('No fixtures found', vim.log.levels.WARN)
    return
  end

  -- Sort alphabetically by filename then line number
  table.sort(qf_items, function(a, b)
    if a.filename == b.filename then
      return a.lnum < b.lnum
    end
    return a.filename < b.filename
  end)

  vim.fn.setqflist(qf_items, 'r')
  vim.cmd 'copen'

  -- Show count of unique fixture names vs total fixtures
  local unique_count = vim.tbl_count(fixture_cache)
  vim.notify(string.format('Found %d fixtures (%d unique names) - populated quickfix list', #qf_items, unique_count), vim.log.levels.INFO)
end

-- Function to manually refresh cache
function M.refresh_cache()
  cache_dirty = true
  refresh_fixture_cache()

  -- Count total fixtures and unique names
  local total_fixtures = 0
  local unique_names = vim.tbl_count(fixture_cache)
  for _, fixture_list in pairs(fixture_cache) do
    total_fixtures = total_fixtures + #fixture_list
  end

  vim.notify(string.format('Refreshed fixture cache (%d fixtures, %d unique names)', total_fixtures, unique_names), vim.log.levels.INFO)
end

-- Auto-refresh cache when files change
local function setup_autocommands()
  local group = vim.api.nvim_create_augroup('PytestGotoFixture', { clear = true })

  -- Refresh cache when Python files are saved
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    group = group,
    pattern = '*.py',
    callback = function()
      cache_dirty = true
    end,
  })

  -- Refresh cache when entering a Python project
  vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged' }, {
    group = group,
    callback = function()
      cache_dirty = true
    end,
  })
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Setup autocommands
  setup_autocommands()

  -- Create user commands
  vim.api.nvim_create_user_command('GotoFixture', function(opts)
    M.goto_fixture(opts.args ~= '' and opts.args or nil)
  end, {
    desc = 'Jump to pytest fixture definition under cursor or by name',
    nargs = '?',
    complete = function(arg_lead, cmd_line, cursor_pos)
      -- Refresh cache if needed
      if cache_dirty then
        refresh_fixture_cache()
      end

      -- Return fixture names for completion
      local fixtures = {}
      for name, _ in pairs(fixture_cache) do
        if name:match('^' .. vim.pesc(arg_lead)) then
          table.insert(fixtures, name)
        end
      end
      table.sort(fixtures)
      return fixtures
    end,
  })

  vim.api.nvim_create_user_command('ListFixtures', M.list_fixtures, {
    desc = 'List all pytest fixtures',
  })

  vim.api.nvim_create_user_command('RefreshFixtures', M.refresh_cache, {
    desc = 'Refresh pytest fixture cache',
  })

  -- Setup keymaps if provided
  if opts.keymap then
    vim.keymap.set('n', opts.keymap, M.goto_fixture, { desc = 'Jump to pytest fixture' })
  end

  -- Initial cache population
  vim.defer_fn(function()
    refresh_fixture_cache()
  end, 100)
end

return M
