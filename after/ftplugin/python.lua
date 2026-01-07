vim.opt.helplang = "py"
vim.opt_local.errorformat = {
    -- Match standard mypy output (file:line:column: type: message)
    '%f:%l:%c: %t%*[^:]: %m',
    '%f:%l: %t%*[^:]: %m',
    -- IGNORE lines that don't match the above (like environment info)
    '%-G%.%#'
}

vim.opt_local.makeprg = "ops/run_mypy --no-error-summary"
require("local-plugins.pytest_fixtures").setup({keymap="<leader>gf"})
