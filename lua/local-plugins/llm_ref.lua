local M = {}

-- Default configuration
local config = {
    keymap_normal = nil,
    keymap_visual = nil,
    notify_on_copy = true,
}

-- Get git repository root directory
local function get_git_root()
    local handle = io.popen('git rev-parse --show-toplevel 2>/dev/null')
    if not handle then
        return nil
    end

    local result = handle:read('*a')
    handle:close()

    if result == '' then
        return nil
    end

    -- Trim whitespace
    result = result:gsub('%s+$', '')
    return result
end

-- Get base path for relative path calculations (git root or cwd)
local function get_base_path()
    local git_root = get_git_root()
    if git_root then
        return git_root
    end
    return vim.fn.getcwd()
end

-- Convert absolute file path to relative path from base
local function get_relative_path(file_path, base_path)
    -- Get absolute file path
    local abs_file = vim.fn.fnamemodify(file_path, ':p')
    local abs_base = vim.fn.fnamemodify(base_path, ':p')

    -- Ensure base path ends with separator
    if not abs_base:match('/$') then
        abs_base = abs_base .. '/'
    end

    -- If file starts with base, strip the base prefix
    if abs_file:sub(1, #abs_base) == abs_base then
        return abs_file:sub(#abs_base + 1)
    end

    -- If not under base, return the file path as-is
    return abs_file
end

-- Format the reference string
local function format_reference(file_path, line_start, line_end, code_lines)
    local ref

    if line_start == line_end then
        ref = string.format('%s:%d', file_path, line_start)
    else
        ref = string.format('%s:%d-%d', file_path, line_start, line_end)
    end

    -- Add code content if provided
    if code_lines and #code_lines > 0 then
        ref = ref .. '\n' .. table.concat(code_lines, '\n')
    end

    return ref
end

-- Main function to generate and copy reference
function M.get_reference(opts)
    opts = opts or {}

    -- Get current buffer file path
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' or file_path == nil then
        vim.notify('Buffer has no file path. Save the file first.', vim.log.levels.WARN)
        return
    end

    -- Check if this is a special buffer
    local buftype = vim.api.nvim_buf_get_option(0, 'buftype')
    if buftype ~= '' then
        vim.notify('Cannot generate reference for special buffer type: ' .. buftype, vim.log.levels.WARN)
        return
    end

    -- Get base path (git root or cwd)
    local base_path = get_base_path()

    -- Convert to relative path
    local relative_path = get_relative_path(file_path, base_path)

    -- Determine line numbers
    local line1 = opts.line1
    local line2 = opts.line2

    -- If no line numbers provided, use current cursor position
    if not line1 then
        local cursor = vim.api.nvim_win_get_cursor(0)
        line1 = cursor[1]
        line2 = cursor[1]
    end

    -- Generate reference
    local reference
    local code_lines = nil

    -- If this is a range (visual selection or explicit range)
    if line1 ~= line2 then
        -- Extract the selected lines
        code_lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
        reference = format_reference(relative_path, line1, line2, code_lines)
    else
        -- Single line, no code content
        reference = format_reference(relative_path, line1, line2, nil)
    end

    -- Copy to clipboard
    vim.fn.setreg('+', reference)

    -- Notify user
    if config.notify_on_copy then
        if line1 == line2 then
            vim.notify(string.format('Copied: %s:%d', relative_path, line1), vim.log.levels.INFO)
        else
            vim.notify(string.format('Copied: %s:%d-%d', relative_path, line1, line2), vim.log.levels.INFO)
        end
    end
end

-- Setup function
function M.setup(opts)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend('force', config, opts or {})

    -- Create user command with range support
    vim.api.nvim_create_user_command('GetLLMRef', function(cmd_opts)
        M.get_reference({
            line1 = cmd_opts.line1,
            line2 = cmd_opts.line2,
        })
    end, {
        range = true,
        desc = 'Generate LLM code reference from current position or selection',
    })

    -- Setup optional keymaps
    if config.keymap_normal then
        vim.keymap.set('n', config.keymap_normal, function()
            M.get_reference({
                line1 = vim.fn.line('.'),
                line2 = vim.fn.line('.'),
            })
        end, { desc = 'Get LLM reference for current line' })
    end

    if config.keymap_visual then
        vim.keymap.set('v', config.keymap_visual, ':GetLLMRef<CR>', { desc = 'Get LLM reference for visual selection' })
    end
end

return M
