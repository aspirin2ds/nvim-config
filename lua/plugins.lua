-- Plugins, managed by vim.pack (built into Neovim 0.12+, :h vim.pack).
--
--   :lua vim.pack.update()        fetch updates, review the diff, :w to confirm
--   :lua vim.pack.update({"foo"}) update just one
--   :lua vim.pack.del({"foo"})    uninstall (also removes it from the lockfile)
--
-- Installed revisions are pinned in nvim-pack-lock.json. Commit that file --
-- it's what makes this config reproduce identically on another machine.
--
-- vim.pack has no event/ft/cmd lazy-loading. That's fine at this size; if a
-- plugin ever measurably hurts startup, wrap its add() in an autocmd.

vim.pack.add({
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

-- ---------------------------------------------------------------- colorscheme
-- The repo is catppuccin/nvim but the Lua module is "catppuccin", hence the
-- explicit name= above -- without it vim.pack would call the plugin "nvim".
-- Flavours: latte (light), frappe, macchiato, mocha (darkest).
require("catppuccin").setup({
  flavour = "mocha",
  background = { light = "latte", dark = "mocha" },
  integrations = {
    fzf = true,
    gitsigns = true,
    mason = true,
    treesitter = true,
    which_key = true,
    nvimtree = true,
    native_lsp = { enabled = true },
  },
})
vim.cmd.colorscheme("catppuccin")

-- ---------------------------------------------------------------------- mason
-- Mason installs language servers / formatters into
-- ~/.local/share/nvim/mason and puts them on Neovim's PATH. That's why the
-- lsp/*.lua files can just say cmd = { "gopls" } and have it resolve.
--
-- Note this is NOT covered by nvim-pack-lock.json -- mason tracks its own
-- versions. If you want those pinned too, add mason-lock.nvim later.
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    "lua-language-server", -- Lua  (needed to edit this config)
    "gopls", -- Go
    "vtsls", -- TypeScript / JavaScript
    "basedpyright", -- Python
    "stylua", -- Lua formatter
    "shfmt", -- shell formatter
    "biome", -- JS/TS/JSON/CSS linter + formatter
    "tailwindcss-language-server", -- Tailwind class completion
    "json-lsp", -- JSON schema validation
    "prettier", -- YAML/Markdown/HTML only (biome handles the rest)
    "ruff", -- Python formatter + linter
    "tree-sitter-cli", -- required by nvim-treesitter's main branch
  },
  run_on_start = true,
})

-- ----------------------------------------------------------------- treesitter
-- The `main` branch is a full rewrite and is required on 0.12 -- `master` is
-- frozen. Unlike the old version it compiles parsers locally, so it needs the
-- tree-sitter CLI (installed by mason above) plus a C compiler.
--
-- Neovim already ships parsers for: c lua markdown query vim vimdoc.
local ts_parsers = {
  "bash",
  "css",
  "go",
  "gomod",
  "gosum",
  "gotmpl",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "python",
  "tsx",
  "typescript",
  "yaml",
}

-- Turn on highlighting + indentation for any buffer whose parser is present.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Start treesitter where a parser exists",
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- :TSSync installs whatever is missing from ts_parsers above.
vim.api.nvim_create_user_command("TSSync", function()
  if vim.fn.executable("tree-sitter") == 0 then
    vim.notify("tree-sitter CLI not found -- wait for mason to finish, then restart", vim.log.levels.WARN)
    return
  end
  local installed = require("nvim-treesitter.config").get_installed()
  local missing = vim.tbl_filter(function(p)
    return not vim.tbl_contains(installed, p)
  end, ts_parsers)
  if #missing == 0 then
    vim.notify("treesitter: all parsers present")
    return
  end
  vim.notify("treesitter: installing " .. table.concat(missing, ", "))
  require("nvim-treesitter").install(missing)
end, { desc = "Install missing treesitter parsers" })

-- Run it automatically once the CLI is actually available. On a brand-new
-- machine mason is still downloading during the first launch, so this no-ops
-- the first time and does the real work on the second.
vim.schedule(function()
  if vim.fn.executable("tree-sitter") == 1 then
    pcall(vim.cmd.TSSync)
  end
end)

-- -------------------------------------------------------------------- fzf-lua
-- Needs the `fzf` binary on PATH. Uses ripgrep for live_grep when present.
local fzf = require("fzf-lua")
fzf.setup({ "default" })

local map = vim.keymap.set
map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Grep in project" })
map("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
map("n", "<leader>fh", fzf.helptags, { desc = "Find help" })
map("n", "<leader>fr", fzf.resume, { desc = "Resume last picker" })
map("n", "<leader>fd", fzf.diagnostics_workspace, { desc = "Find diagnostics" })
map("n", "<leader>/", fzf.blines, { desc = "Search in current buffer" })

-- -------------------------------------------------------------------- conform
-- Formatting. The LSP can format some of these, but not all -- stylua, shfmt
-- and prettier aren't language servers, so nothing was running them before.
--
-- Go is deliberately absent from formatters_by_ft: gopls already formats with
-- gofumpt (see lsp/gopls.lua), and lsp_format = "fallback" below picks that up.
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    python = { "ruff_format" },

    -- biome, NOT prettier, for everything biome supports. Prettier's
    -- defaults (double quotes, forced semicolons, width 80) fight a typical
    -- biome.json (single quotes, semicolons asNeeded, width 100) -- running
    -- the wrong one rewrites whole files and breaks `bun run lint`.
    -- "biome" formats only. Swap to "biome-check" to also apply safe lint
    -- fixes (removes unused imports) on every save.
    javascript = { "biome" },
    javascriptreact = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    json = { "biome" },
    jsonc = { "biome" },
    css = { "biome" },

    -- biome doesn't handle these yet, so prettier keeps them.
    html = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
  },
  default_format_opts = { lsp_format = "fallback" },
  format_on_save = function(bufnr)
    -- Set vim.g.disable_autoformat (global) or vim.b[bufnr].disable_autoformat
    -- (this buffer) to skip. Toggle with :FormatToggle below.
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
})

-- The single format key. Lives here rather than in the LspAttach handler so
-- it works in buffers with no language server attached at all.
map({ "n", "v" }, "<leader>cf", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer/selection" })

vim.api.nvim_create_user_command("FormatToggle", function(args)
  if args.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("format on save (buffer): " .. tostring(not vim.b.disable_autoformat))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("format on save (global): " .. tostring(not vim.g.disable_autoformat))
  end
end, { bang = true, desc = "Toggle format-on-save (! for current buffer only)" })

-- ------------------------------------------------------------------ nvim-tree
-- File explorer. netrw is disabled in lua/options.lua so the two don't fight.
require("nvim-web-devicons").setup({})
require("nvim-tree").setup({
  view = { width = 34, preserve_window_proportions = true },
  renderer = {
    group_empty = true, -- collapse a/b/c when each has one child
    indent_markers = { enable = true },
  },
  filters = {
    dotfiles = false, -- show .env, .github etc
    git_ignored = true, -- but hide node_modules, dist, build output
  },
  update_focused_file = { enable = true }, -- follow the buffer you're editing
  git = { enable = true },
  diagnostics = { enable = true }, -- LSP error/warn badges on files
  actions = { open_file = { resize_window = false } },
})

map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
map("n", "<leader>E", "<cmd>NvimTreeFindFile<CR>", { desc = "Reveal file in explorer" })

-- ------------------------------------------------------------------ which-key
-- Press <leader> and wait -- it lists what's available. The add() call below
-- only names the prefix groups; the individual entries come from the `desc`
-- field on every keymap in this config, which is why they're all filled in.
local wk = require("which-key")
wk.setup({ preset = "helix", delay = 400 })
wk.add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
})

-- ------------------------------------------------------------------- gitsigns
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local function bmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end
    bmap("n", "]h", gs.next_hunk, "Next git hunk")
    bmap("n", "[h", gs.prev_hunk, "Previous git hunk")
    bmap("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
    bmap("n", "<leader>gb", gs.blame_line, "Blame line")
    bmap("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
    bmap("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
  end,
})
