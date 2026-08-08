-- lua-language-server. Neovim finds this file by name: `vim.lsp.enable("lua_ls")`
-- looks for lsp/lua_ls.lua anywhere on 'runtimepath'.
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      -- Teach it about Neovim's own API so editing this config gets
      -- completion and stops flagging `vim` as undefined.
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
      format = { enable = false }, -- stylua handles formatting
    },
  },
}
