return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', 'lua/' },
  settings = {
    Lua = {
      completion = { callSnippet = 'Replace' },
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false },
    },
  },
}
