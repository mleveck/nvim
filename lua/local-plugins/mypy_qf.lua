local uv = vim.uv
local M = {}
local watcher

local function stop_watcher()
  if watcher then
    watcher:stop()
    watcher:close()
    watcher = nil
  end
end

local function parse_mypy(lines)
  local items = {}
  for _, line in ipairs(lines) do
    -- handle "file:line:col: msg" and "file:line: msg"
    local file, lnum, col, msg = line:match("^([^:]+):(%d+):(%d+):%s*(.*)")
    if not file then
      file, lnum, msg = line:match("^([^:]+):(%d+):%s*(.*)")
      col = 1
    end
    if file then
      table.insert(items, {
        filename = vim.fn.fnamemodify(file, ":p"),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = msg,
      })
    end
  end
  return items
end

local function refresh_qf(path)
  local lines = vim.fn.readfile(path)
  local items = parse_mypy(lines)
  vim.fn.setqflist({}, "r", { title = "mypy", items = items })
end

function M.start(path)
  path = vim.fn.expand(path)
  stop_watcher()

  if vim.fn.filereadable(path) == 1 then
    refresh_qf(path)
  else
    vim.notify(("mypy_qf: waiting for %s to appear"):format(path), vim.log.levels.INFO)
  end

  watcher = uv.new_fs_event()
  watcher:start(path, {}, function(err)
    if err then
      vim.schedule(function()
        vim.notify("mypy_qf watcher error: " .. err, vim.log.levels.ERROR)
      end)
      return
    end
    vim.schedule(function()
      refresh_qf(path)
    end)
  end)
end

function M.stop()
  stop_watcher()
end

vim.api.nvim_create_user_command("MypyWatchStart", function(opts)
  M.start(opts.args)
end, { nargs = 1, complete = "file" })

vim.api.nvim_create_user_command("MypyWatchStop", function()
  M.stop()
end, {})

return M
