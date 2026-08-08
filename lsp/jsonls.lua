-- JSON language server. Validates against the $schema declared inside each
-- file -- which is why biome.json gets full completion for free, since it
-- points at biomejs.dev's schema.
--
-- provideFormatter = false: biome owns JSON formatting here. Leaving it on
-- means two servers both advertise formatting for the same buffer.
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  init_options = { provideFormatter = false },
  settings = {
    json = {
      validate = { enable = true },
      -- Files without an inline $schema (package.json, tsconfig.json) would
      -- need SchemaStore to be mapped. Add b0o/SchemaStore.nvim if you want
      -- that; the inline-$schema case covers biome.json already.
    },
  },
}
