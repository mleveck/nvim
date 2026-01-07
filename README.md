# Neovim Configuration

Modern Neovim 0.11+ configuration with native LSP, blink.cmp, and modular structure.

## Features

- **Native LSP** - Uses `vim.lsp.config()` and `vim.lsp.enable()` (no lspconfig required for basic setup)
- **blink.cmp** - Fast completion engine (Rust-based, ~6x faster than nvim-cmp)
- **Treesitter main branch** - With treesitter-modules.nvim for incremental selection
- **Modular structure** - Split into logical files instead of one monolithic init.lua

## Structure

```
~/.config/nvim/
├── init.lua                    # Minimal bootstrap (~40 lines)
├── lsp/                        # Native LSP server configs (0.11+ pattern)
│   ├── lua_ls.lua
│   ├── basedpyright.lua
│   └── gopls.lua
├── lua/
│   ├── config/
│   │   ├── options.lua         # vim.opt settings
│   │   ├── keymaps.lua         # Non-plugin keymaps
│   │   ├── autocmds.lua        # Autocommands
│   │   └── lsp.lua             # LSP attach keymaps & config
│   ├── plugins/
│   │   ├── editor.lua          # treesitter, mini.nvim, conform, mason
│   │   ├── ui.lua              # which-key, neo-tree, colorscheme
│   │   ├── git.lua             # gitsigns, neogit, gitlinker, diffview
│   │   ├── completion.lua      # blink.cmp, lazydev
│   │   ├── telescope.lua       # Telescope + extensions
│   │   ├── debug.lua           # DAP setup
│   │   └── languages.lua       # conjure, jupytext, neoscroll, tmux-navigator
│   └── local-plugins/          # Custom plugins
│       ├── github-navigator/
│       └── pytest_fixtures.lua
└── after/ftplugin/             # Filetype-specific settings
    ├── python.lua
    ├── go.lua
    └── markdown.lua
```

## Key Bindings

### General
| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jj` | Escape (insert mode) |
| `<leader>cp` | Copy current file path |
| `<leader>e` | Toggle Neo-tree |
| `<leader>wo` | Toggle Zen mode |

### LSP
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `gD` | Go to declaration |
| `gl` | Line diagnostics |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |
| `<leader>dss` | Document symbols |
| `<leader>th` | Toggle inlay hints |

### Telescope
| Key | Action |
|-----|--------|
| `<leader>sf` | Find files |
| `<leader>sgf` | Live grep |
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader><leader>` | Find buffers |
| `<leader>/` | Fuzzy search in buffer |

### Git
| Key | Action |
|-----|--------|
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| `<leader>gy` | Yank git link |
| `]c` / `[c` | Next/prev git change |

### Treesitter Selection
| Key | Action |
|-----|--------|
| `<leader>ss` | Init selection (cursor at start) |
| `;` | Expand selection (visual mode) |
| `,` | Shrink selection (visual mode) |

### Debug
| Key | Action |
|-----|--------|
| `<leader>dc` | Start/continue |
| `<leader>di` | Step into |
| `<leader>dn` | Step over |
| `<leader>dr` | Step out |
| `<leader>b` | Toggle breakpoint |
| `<leader>dt` | Toggle DAP UI |

## LSP Servers

Configured in `lsp/` directory, installed via Mason:
- **lua_ls** - Lua
- **basedpyright** - Python (type checking disabled)
- **gopls** - Go

### Adding a New LSP Server

1. **Create config file** at `lsp/<server_name>.lua`:

```lua
return {
  cmd = { 'server-command' },
  filetypes = { 'filetype1', 'filetype2' },
  root_markers = { 'marker_file', '.git' },
  settings = {
    -- server-specific settings (optional)
  },
}
```

2. **Enable the server** in `lua/config/lsp.lua`:

```lua
vim.lsp.enable({ 'lua_ls', 'basedpyright', 'gopls', 'your_new_server' })
```

3. **Auto-install via Mason** (optional) in `lua/plugins/editor.lua`:

```lua
opts = {
  ensure_installed = { 'lua-language-server', 'basedpyright', 'gopls', 'your-server', 'stylua' },
},
```

### Example: Adding TypeScript

```lua
-- lsp/ts_ls.lua
return {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_markers = { 'tsconfig.json', 'package.json', '.git' },
}
```

### Native LSP Config Fields

| Field | Description |
|-------|-------------|
| `cmd` | Command to start the server |
| `filetypes` | File types to attach to (required!) |
| `root_markers` | Files that indicate project root |
| `settings` | Server-specific configuration |
| `init_options` | Options sent to server on init |
| `capabilities` | Client capabilities (see below) |

Find server names at `:Mason` or [mason-lspconfig mappings](https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md)

### LSP Capabilities

By default, servers use Neovim's built-in capabilities. blink.cmp automatically adds completion capabilities (snippet support, etc.).

**Global modifications** are in `lua/config/lsp.lua`:
- Semantic tokens disabled via `client.server_capabilities.semanticTokensProvider = nil`

**Per-server capabilities** can be set in `lsp/<server>.lua`:

```lua
return {
  cmd = { 'gopls' },
  filetypes = { 'go' },
  root_markers = { 'go.mod', '.git' },
  capabilities = {
    textDocument = {
      completion = {
        completionItem = { snippetSupport = false },
      },
    },
  },
}
```

**Extending default capabilities** (if needed in `lua/config/lsp.lua`):

```lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}
-- Then merge into each config before vim.lsp.config()
```

## Plugin Highlights

- **blink.cmp** - Completion with `<C-j>`/`<C-k>` navigation, `<CR>` to accept
- **nvim-surround** - `ys`, `ds`, `cs` for surround operations
- **mini.ai** - Enhanced text objects (`vaf` for function, `vac` for class)
- **Conjure** - REPL for Python and Lisps (`<localleader>p` prefix)
- **vim-tmux-navigator** - Seamless tmux/nvim pane navigation with `<C-hjkl>`

## Local Plugins

### github-navigator
Open GitHub URLs from clipboard: `<leader>go`

### pytest_fixtures
Jump to pytest fixture definitions: `<leader>gf` (Python files only)

## Requirements

- Neovim 0.11+
- Git
- A Nerd Font (optional, for icons)
- ripgrep (for Telescope grep)
- make (for telescope-fzf-native)
