return {
    -- Treesitter (main branch)
    {
        "nvim-treesitter/nvim-treesitter",
        version = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({
                "bash",
                "c",
                "diff",
                "html",
                "lua",
                "luadoc",
                "markdown",
                "markdown_inline",
                "query",
                "vim",
                "vimdoc",
                "python",
                "clojure",
                "fennel",
                "go",
                "json",
                "yaml",
            })
        end,
    },

    -- Treesitter modules (incremental selection for main branch)
    {
        "MeanderingProgrammer/treesitter-modules.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            local ts = require("treesitter-modules")
            ts.setup({
                highlight = { enable = true },
                indent = { enable = true },
            })

            local treesitter_selection_active = false

            local function init_selection_with_cursor_at_start()
                ts.init_selection()
                vim.cmd("normal! o")
                treesitter_selection_active = true
            end

            local function smart_semicolon()
                if treesitter_selection_active and vim.api.nvim_get_mode().mode:match("[vV\22]") then
                    ts.node_incremental()
                    vim.cmd("normal! o")
                else
                    treesitter_selection_active = false
                    vim.cmd("normal! ;")
                end
            end

            local function smart_comma()
                if treesitter_selection_active and vim.api.nvim_get_mode().mode:match("[vV\22]") then
                    ts.node_decremental()
                    vim.cmd("normal! o")
                else
                    treesitter_selection_active = false
                    vim.cmd("normal! ,")
                end
            end

            vim.api.nvim_create_autocmd("ModeChanged", {
                pattern = "[vV\22]:*",
                callback = function()
                    treesitter_selection_active = false
                end,
            })

            vim.keymap.set(
                "n",
                "<leader>ss",
                init_selection_with_cursor_at_start,
                { desc = "Init selection (cursor at start)" }
            )
            vim.keymap.set("v", ";", smart_semicolon, { desc = "Node incremental or repeat motion" })
            vim.keymap.set("v", ",", smart_comma, { desc = "Node decremental or repeat motion" })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    enable = true,
                    lookahead = true,
                    selection_modes = {
                        ['@parameter.outer'] = 'v',
                        ['@function.outer'] = 'V',
                        ['@class.outer'] = '<c-v>',
                    },
                },
            })
            local select = require("nvim-treesitter-textobjects.select").select_textobject
            vim.keymap.set({"x", "o"}, "af", function()
                select("@function.outer", "textobjects")
                vim.cmd('normal! o')
            end)
            vim.keymap.set({"x", "o"}, "if", function()
                select("@function.inner", "textobjects")
            end)
            vim.keymap.set({"x", "o"}, "ac", function()
                select("@class.outer", "textobjects")
                vim.cmd('normal! o')
            end)
            vim.keymap.set({"x", "o"}, "ic", function()
                select("@class.inner", "textobjects")
            end)
            vim.keymap.set({"x", "o"}, "ib", function()
                select("@block.inner", "textobjects")
            end)
            vim.keymap.set({"x", "o"}, "ab", function()
                select("@block.outer", "textobjects")
            end)
        end,
    },

    -- Collection of various small independent plugins/modules
    {
        "echasnovski/mini.nvim",
        config = function()
            -- Better Around/Inside textobjects
            require("mini.ai").setup({ n_lines = 500 })
            -- NOT loading mini.surround - using nvim-surround instead

            -- Simple and easy statusline
            local statusline = require("mini.statusline")
            statusline.setup({ use_icons = vim.g.have_nerd_font })
            statusline.section_location = function()
                return "%2l:%-2v"
            end
        end,
    },

    -- Surround plugin (vim-surround style keybindings: ys, ds, cs)
    {
        "kylechui/nvim-surround",
        event = "VeryLazy",
        opts = {},
    },

    -- Highlight todo, notes, etc in comments
    {
        "folke/todo-comments.nvim",
        event = "VimEnter",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { signs = false },
    },

    -- Autoformat
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "Format buffer",
            },
        },
        opts = {
            notify_on_error = false,
            formatters_by_ft = {
                lua = { "stylua" },
                bash = { "bashls" },
                yaml = { "prettier" },
                markdown = { "prettier" },
            },
        },
    },

    -- Mason for installing LSP servers and tools
    {
        "williamboman/mason.nvim",
        config = true,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
            ensure_installed = { "lua-language-server", "basedpyright", "gopls", "stylua" },
        },
    },

    -- Useful status updates for LSP
    { "j-hui/fidget.nvim", opts = {} },
}
