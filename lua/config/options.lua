local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false
opt.breakindent = true
opt.undofile = true
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
