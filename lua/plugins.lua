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
  { src = "https://github.com/folke/tokyonight.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

-- ---------------------------------------------------------------- colorscheme
require("tokyonight").setup({ style = "night" })
vim.cmd.colorscheme("tokyonight")

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
