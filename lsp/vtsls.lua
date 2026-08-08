-- vtsls -- a wrapper around the official TypeScript server. Preferred over
-- typescript-language-server these days: faster and supports more of the
-- native tsserver feature set.
return {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", "bun.lockb", "bun.lock", ".git" },
  settings = {
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      inlayHints = {
        parameterNames = { enabled = "literals" },
        variableTypes = { enabled = false },
        functionLikeReturnTypes = { enabled = true },
      },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
    },
  },
}
