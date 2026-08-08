-- basedpyright -- a maintained fork of pyright with stricter defaults and
-- inlay hints. Swap cmd/name to "pyright-langserver" if you'd rather have
-- the upstream one.
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    basedpyright = {
      analysis = {
        -- "recommended" is very noisy on existing codebases; "standard"
        -- is the sane starting point.
        typeCheckingMode = "standard",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
        },
      },
    },
  },
}
