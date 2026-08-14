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
  { src = "https://github.com/folke/flash.nvim" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- harpoon dependency
  { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
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
    flash = true,
    native_lsp = { enabled = true },
    -- bufferline is NOT listed here. Catppuccin handles it through a
    -- separate "special" module passed to bufferline's own highlights
    -- option -- see the bufferline section below.
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
  -- Registry refreshes and package checks can take hundreds of milliseconds.
  -- Keep them off the critical startup path and avoid repeating the work for
  -- every Nvim process opened during the day.
  start_delay = 3000,
  debounce_hours = 24,
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
    local buf = ev.buf
    local function start()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if pcall(vim.treesitter.start, buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    if vim.v.vim_did_enter == 1 then
      start()
    else
      -- Loading a parser can take over 100 ms on the first buffer. Let Nvim
      -- draw the file first; highlighting is ready immediately afterward.
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.defer_fn(start, 20)
        end,
      })
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

-- Parser discovery invokes the tree-sitter CLI and is relatively expensive,
-- even when every parser is already installed. Run :TSSync after adding a
-- language (or on a new machine) instead of paying that cost on every launch.

-- -------------------------------------------------------------------- fzf-lua
-- Needs the `fzf` binary on PATH. Uses ripgrep for live_grep when present.
local fzf = require("fzf-lua")
fzf.setup({ "default" })

local map = vim.keymap.set

-- The split: f is "which FILE", s is "find TEXT". If you're naming a file,
-- it's f; if you're searching content, it's s.
map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })
map("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New file" })

map("n", "<leader>sg", fzf.live_grep, { desc = "Grep in project" })
map("n", "<leader>sw", fzf.grep_cword, { desc = "Grep word under cursor" })
map("v", "<leader>sw", fzf.grep_visual, { desc = "Grep selection" })
map("n", "<leader>sb", fzf.blines, { desc = "Search in current buffer" })
map("n", "<leader>sh", fzf.helptags, { desc = "Search help" })
map("n", "<leader>sk", fzf.keymaps, { desc = "Search keymaps" })
map("n", "<leader>sc", fzf.commands, { desc = "Search commands" })
map("n", "<leader>sr", fzf.resume, { desc = "Resume last picker" })

-- Diagnostics list -- the rest of the x group is in lua/keymaps.lua.
map("n", "<leader>xx", fzf.diagnostics_workspace, { desc = "All diagnostics" })
map("n", "<leader>xX", fzf.diagnostics_document, { desc = "Buffer diagnostics" })

-- Top-level shortcuts for the three things used most often.
map("n", "<leader><space>", fzf.files, { desc = "Find files" })
map("n", "<leader>,", fzf.buffers, { desc = "Switch buffer" })
map("n", "<leader>/", fzf.live_grep, { desc = "Grep in project" })

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

map("n", "<leader>uf", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify("format on save: " .. tostring(not vim.g.disable_autoformat))
end, { desc = "Toggle format on save" })

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

-- ----------------------------------------------------------------- bufferline
-- Open buffers rendered as tabs. Note these are BUFFERS, not Vim's native
-- :tabs -- native tabs are window layouts, which is a different thing.
require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(_, _, diag)
      local s = {}
      if diag.error then
        s[#s + 1] = " " .. diag.error
      end
      if diag.warning then
        s[#s + 1] = " " .. diag.warning
      end
      return table.concat(s, " ")
    end,
    separator_style = "slant",
    show_buffer_close_icons = false,
    always_show_bufferline = false, -- hide it when only one buffer is open
    offsets = {
      -- Keep the tabs above the editor, not above the file tree.
      { filetype = "NvimTree", text = "Files", highlight = "Directory", separator = true },
    },
  },
  -- catppuccin moved this out of `integrations` in v2; the old
  -- catppuccin.groups.integrations.bufferline path no longer exists.
  highlights = require("catppuccin.special.bufferline").get_theme(),
})

-- These override the plain :bprevious/:bnext from lua/keymaps.lua so the
-- order follows what you see in the tabline (which you can reorder).
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin/unpin buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })

-- A plain :bdelete closes any window showing the buffer, which wrecks a
-- split layout. Point every such window at another buffer first, then
-- delete. (This is what bufdelete.nvim does; it's small enough to inline.)
map("n", "<leader>bd", function()
  local target = vim.api.nvim_get_current_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == target then
      vim.api.nvim_win_call(win, function()
        if not pcall(vim.cmd, "bprevious") or vim.api.nvim_win_get_buf(win) == target then
          vim.cmd("enew")
        end
      end)
    end
  end
  pcall(vim.api.nvim_buf_delete, target, { force = false })
end, { desc = "Delete buffer (keep layout)" })
map("n", "<S-Left>", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })
map("n", "<S-Right>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
-- <leader>1-4 used to jump to bufferline positions. They're harpoon slots
-- now (below): bufferline positions shift as buffers open and close, so
-- they're the one thing you can't build muscle memory for.

-- -------------------------------------------------------------------- harpoon
-- Pin the handful of files you're actually working in and jump straight to
-- them. Unlike buffer positions, a slot stays put until you change it.
local harpoon = require("harpoon")
harpoon:setup({
  settings = {
    save_on_toggle = true,
    sync_on_ui_close = true,
  },
})

map("n", "<leader>ha", function()
  harpoon:list():add()
end, { desc = "Add file to harpoon" })
map("n", "<leader>hh", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon menu" })
map("n", "<leader>hc", function()
  harpoon:list():clear()
end, { desc = "Clear harpoon list" })

for i = 1, 4 do
  map("n", "<leader>" .. i, function()
    harpoon:list():select(i)
  end, { desc = "Harpoon file " .. i })
end
map("n", "<C-p>", function()
  harpoon:list():prev()
end, { desc = "Harpoon previous" })
map("n", "<C-n>", function()
  harpoon:list():next()
end, { desc = "Harpoon next" })

-- ---------------------------------------------------------------------- flash
-- Jump anywhere on screen: press s, then the characters you're aiming at,
-- then the label that appears. Also upgrades f/t/;/, and / search.
--
-- NOTE: this takes over `s` (normally "substitute character"). Use `cl` for
-- that instead. If you'd rather keep `s`, change the lhs below to something
-- free like `<leader>s`.
require("flash").setup({
  modes = {
    char = { jump_labels = true }, -- label mode for f/t/;/,
  },
})

map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })
map({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash treesitter select" })
map("o", "r", function()
  require("flash").remote()
end, { desc = "Remote flash (operate at distance)" })
map({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter search" })
map("c", "<C-s>", function()
  require("flash").toggle()
end, { desc = "Toggle flash while searching" })

-- ------------------------------------------------------------------ which-key
-- Press <leader> and wait -- it lists what's available. The add() call below
-- only names the prefix groups; the individual entries come from the `desc`
-- field on every keymap in this config, which is why they're all filled in.
local wk = require("which-key")
wk.setup({ preset = "helix", delay = 400 })
wk.add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "file/find" },
  { "<leader>g", group = "git" },
  { "<leader>h", group = "harpoon" },
  { "<leader>q", group = "quit" },
  { "<leader>s", group = "search" },
  { "<leader>u", group = "ui/toggle" },
  { "<leader>w", group = "window" },
  { "<leader>x", group = "diagnostics" },
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
