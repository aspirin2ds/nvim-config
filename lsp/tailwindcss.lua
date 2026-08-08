-- Tailwind CSS language server: class-name completion, hover previews,
-- colour swatches, and warnings about conflicting classes.
--
-- Tailwind v4 is CSS-first -- there is no tailwind.config.js any more, the
-- config lives in the stylesheet behind `@import "tailwindcss"`. So the
-- config-file markers below are just a v3 fallback; in practice it roots on
-- package.json, which puts it at the app (apps/web) rather than the monorepo
-- top, which is what you want since that's where the stylesheet lives.
return {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "svelte",
    "vue",
  },
  root_markers = {
    { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts" },
    { "postcss.config.js", "postcss.config.ts" },
    "package.json",
    ".git",
  },
  settings = {
    tailwindCSS = {
      validate = true,
      classAttributes = { "class", "className", "classList", "ngClass" },
      lint = {
        cssConflict = "warning",
        invalidApply = "error",
        invalidConfigPath = "error",
        invalidScreen = "error",
        invalidTailwindDirective = "error",
        invalidVariant = "error",
        recommendedVariantOrder = "warning",
      },
      experimental = {
        -- shadcn puts classes inside cva() and cn() rather than a plain
        -- className string. Without these patterns you get no completion
        -- inside any component in components/ui.
        classRegex = {
          { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          { "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
        },
      },
    },
  },
}
