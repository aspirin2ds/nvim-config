-- Biome: linter + formatter for JS/TS/JSON/CSS.
--
-- Root markers are deliberately ONLY biome.json/jsonc -- no .git, no
-- package.json. In a monorepo the config lives at the top level, so biome
-- must root there to see the `overrides` section; rooting per-app would
-- silently drop those rules. (vtsls does the opposite and roots per-app,
-- because each app has its own tsconfig.json. Both are correct.)
--
-- workspace_required = true means: don't attach at all if no biome.json is
-- found upward. Without it, biome would start in single-file mode on any
-- random .ts file and report nothing useful.
return {
  cmd = { "biome", "lsp-proxy" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "json",
    "jsonc",
    "css",
    "graphql",
    "vue",
    "svelte",
    "astro",
  },
  root_markers = { "biome.json", "biome.jsonc" },
  workspace_required = true,
}
