local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false
opt.breakindent = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.path = opt.path + "**"
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.inccommand = "split"
opt.cursorline = true
opt.scrolloff = 5
opt.wildmode = "longest:full,full"
opt.wildignore = opt.wildignore + "**/node_modules/**,**/.git/**,**/venv/**,**/__pycache__/**"

-- Ensure persistent undo behaves like the old config
local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
    -- vim.fn.mkdir third arg uses Unix perms; Lua 5.1 lacks 0o prefix, so use decimal 448 (octal 0700)
    vim.fn.mkdir(undodir, "p", 448)
end
opt.undofile = true
opt.undodir = undodir

-- Schedule clipboard to avoid startup delay
vim.schedule(function()
    opt.clipboard = "unnamedplus"
end)

-- Filetype additions
vim.filetype.add({
    extension = {
        jinja = "jinja",
        jinja2 = "jinja",
        j2 = "jinja",
    },
})
