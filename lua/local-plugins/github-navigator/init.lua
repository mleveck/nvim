local M = {}

-- Default configuration
local config = {
  keymap = '<leader>go',
  prompt_checkout = true,
  auto_focus = true,
}

-- Get list of all git branches (local and remote)
local function get_all_branches()
  local handle = io.popen 'git branch -a 2>/dev/null'
  if not handle then
    return {}
  end

  local result = handle:read '*a'
  handle:close()

  local branches = {}
  for line in result:gmatch '[^\r\n]+' do
    local branch = line:gsub('^%s*%*?%s*', '') -- Remove leading whitespace and *
    branch = branch:gsub('^remotes/origin/', '') -- Remove remotes/origin/ prefix
    if branch ~= 'HEAD' and branch ~= '' and not branch:match '->' then
      branches[branch] = true
    end
  end

  return branches
end

-- Parse GitHub URL to extract repo info, branch, file path, and line number
local function parse_github_url(url)
  -- Remove any trailing whitespace
  url = url:gsub('%s+$', '')

  -- Extract basic parts: owner, repo, blob/tree, and the rest
  local owner, repo, rest = url:match 'https://github%.com/([^/]+)/([^/]+)/blob/(.+)'
  local blob_or_tree = 'blob'
  if not owner then
    owner, repo, rest = url:match 'https://github%.com/([^/]+)/([^/]+)/tree/(.+)'
    if not owner then
      return nil
    end
    blob_or_tree = 'tree'
  end

  -- Extract line number or line range if present
  local line_num = nil
  local path_part = rest

  -- Handle line ranges like #L30-L35 (use first line)
  if rest:match '#L(%d+)%-L%d+$' then
    line_num = tonumber(rest:match '#L(%d+)%-L%d+$')
    path_part = rest:gsub('#L%d+%-L%d+$', '')
  -- Handle single line like #L30
  elseif rest:match '#L(%d+)$' then
    line_num = tonumber(rest:match '#L(%d+)$')
    path_part = rest:gsub('#L%d+$', '')
  end

  -- Get all available branches
  local branches = get_all_branches()

  -- Try to find the longest matching branch name
  local best_branch = nil
  local best_file_path = nil
  local best_match_length = 0

  -- Split the path and try different combinations
  local parts = {}
  for part in path_part:gmatch '[^/]+' do
    table.insert(parts, part)
  end

  -- Try each possible branch/file split
  for i = 1, #parts - 1 do -- -1 because we need at least one part for the file path
    local potential_branch = table.concat(parts, '/', 1, i)
    local potential_file = table.concat(parts, '/', i + 1)

    if branches[potential_branch] and #potential_branch > best_match_length then
      best_branch = potential_branch
      best_file_path = potential_file
      best_match_length = #potential_branch
    end
  end

  -- If no branch found, fallback to first part as branch
  if not best_branch then
    best_branch = parts[1]
    best_file_path = table.concat(parts, '/', 2)
  end

  return {
    owner = owner,
    repo = repo,
    branch = best_branch,
    file_path = best_file_path,
    line_number = line_num,
  }
end

-- Get current git branch
local function get_current_branch()
  local handle = io.popen 'git branch --show-current 2>/dev/null'
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if result then
    return result:gsub('%s+$', '') -- trim whitespace
  end

  return nil
end

-- Get git remote URL
local function get_git_remote()
  local handle = io.popen 'git config --get remote.origin.url 2>/dev/null'
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if result then
    return result:gsub('%s+$', '') -- trim whitespace
  end

  return nil
end

-- Check if we're in the correct repository
local function is_correct_repo(parsed_url)
  local remote_url = get_git_remote()
  if not remote_url then
    return false
  end

  -- Handle both SSH and HTTPS URLs, removing .git suffix
  -- Also handle custom SSH configs like git@github-user:owner/repo.git
  local ssh_pattern = 'git@github[^:]*:([^/]+)/(.+)%.git'
  local https_pattern = 'https://github%.com/([^/]+)/(.+)%.git'

  local owner, repo = remote_url:match(ssh_pattern)
  if not owner then
    owner, repo = remote_url:match(https_pattern)
  end

  if owner and repo then
    return owner == parsed_url.owner and repo == parsed_url.repo
  end

  return false
end

-- Checkout branch if needed
local function checkout_branch_if_needed(target_branch)
  local current_branch = get_current_branch()

  if not current_branch then
    vim.notify('Could not detect current git branch', vim.log.levels.ERROR)
    return false
  end

  if current_branch == target_branch then
    return true
  end

  if config.prompt_checkout then
    vim.notify(string.format('Switching from branch "%s" to "%s"...', current_branch, target_branch), vim.log.levels.INFO)
  end

  -- Try simple checkout first
  local checkout_cmd = string.format('git checkout "%s"', target_branch)
  local handle = io.popen(checkout_cmd .. ' 2>&1')
  if not handle then
    vim.notify('Failed to execute git checkout', vim.log.levels.ERROR)
    return false
  end

  local result = handle:read '*a'
  local success, exit_type, exit_code = handle:close()

  -- Handle case where exit_code might be nil but success is true
  if success and (exit_code == 0 or exit_code == nil) then
    vim.notify('Switched to branch: ' .. target_branch, vim.log.levels.INFO)
    return true
  end

  -- If simple checkout failed, try to fetch and checkout remote branch
  vim.notify('Local checkout failed, trying to fetch from remote...', vim.log.levels.INFO)

  -- Fetch from remote
  local fetch_handle = io.popen 'git fetch origin 2>&1'
  if fetch_handle then
    local fetch_result = fetch_handle:read '*a'
    fetch_handle:close()
  end

  -- Try checkout with remote tracking
  local remote_checkout_cmd = string.format('git checkout -b "%s" "origin/%s"', target_branch, target_branch)
  local remote_handle = io.popen(remote_checkout_cmd .. ' 2>&1')
  if not remote_handle then
    vim.notify('Failed to checkout remote branch: ' .. target_branch .. '\nOriginal error: ' .. result, vim.log.levels.ERROR)
    return false
  end

  local remote_result = remote_handle:read '*a'
  local remote_success, remote_exit_type, remote_exit_code = remote_handle:close()

  -- Handle case where exit_code might be nil but success is true
  if remote_success and (remote_exit_code == 0 or remote_exit_code == nil) then
    vim.notify('Switched to branch: ' .. target_branch, vim.log.levels.INFO)
    return true
  else
    vim.notify('Failed to checkout branch: ' .. target_branch .. '\nLocal error: ' .. result .. '\nRemote error: ' .. remote_result, vim.log.levels.ERROR)
    return false
  end
end

-- Navigate to file and line
local function navigate_to_file(file_path, line_number)
  -- Check if file exists
  local file_full_path = vim.fn.getcwd() .. '/' .. file_path
  if vim.fn.filereadable(file_full_path) == 0 then
    vim.notify('File not found: ' .. file_path, vim.log.levels.ERROR)
    return false
  end

  -- Open the file
  vim.cmd('edit ' .. vim.fn.fnameescape(file_path))

  -- Jump to line if specified
  if line_number then
    vim.cmd(tostring(line_number))
    vim.cmd 'normal! zz' -- Center the line on screen
  end

  if config.auto_focus then
    vim.cmd 'normal! zz'
  end

  vim.notify(string.format('Opened %s%s', file_path, line_number and (' at line ' .. line_number) or ''), vim.log.levels.INFO)
  return true
end

-- Main function to open GitHub URL
function M.open_github_url(url)
  -- If no URL provided, try to get from clipboard
  if not url or url == '' then
    url = vim.fn.getreg '+'
    if not url or url == '' then
      vim.notify('No URL provided and clipboard is empty', vim.log.levels.ERROR)
      return
    end
  end

  -- Parse the URL
  local parsed = parse_github_url(url)
  if not parsed then
    vim.notify('Invalid GitHub URL format', vim.log.levels.ERROR)
    return
  end

  -- Check if we're in the correct repository
  if not is_correct_repo(parsed) then
    vim.notify(string.format('Current repository does not match URL repo: %s/%s', parsed.owner, parsed.repo), vim.log.levels.ERROR)
    return
  end

  -- Checkout branch if needed
  if not checkout_branch_if_needed(parsed.branch) then
    return
  end

  -- Navigate to the file
  navigate_to_file(parsed.file_path, parsed.line_number)
end

-- Setup function
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  -- Create user command
  vim.api.nvim_create_user_command('GitHubOpen', function(args)
    M.open_github_url(args.args)
  end, {
    nargs = '?',
    desc = 'Open GitHub URL in current buffer',
  })

  -- Set up keymapping
  if config.keymap then
    vim.keymap.set('n', config.keymap, function()
      M.open_github_url()
    end, { desc = 'Open GitHub URL from clipboard' })
  end
end

return M

