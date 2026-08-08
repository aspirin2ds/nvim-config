-- Editor settings. Every line here is something you can look up with
-- :h 'optionname' -- if you don't know why one is here, delete it and see.

local o = vim.o

-- Leader must be set before any mapping that uses it.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable netrw. nvim-tree replaces it, and both being active causes the
-- two to fight over directory buffers. This has to happen before any plugin
-- loads, which is why it's here rather than in lua/plugins.lua.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers: absolute for the cursor line, relative elsewhere. Makes
-- motions like 5j / 12k readable straight off the gutter.
o.number = true
o.relativenumber = true

-- Indentation. 2 spaces by default; treesitter/LSP override per-language.
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true

-- Search
o.ignorecase = true
o.smartcase = true -- ...unless the pattern contains a capital
o.inccommand = "split" -- live preview of :s substitutions

-- Splits open where you expect them to
o.splitright = true
o.splitbelow = true

-- Persistent undo across restarts. Lives in ~/.local/state/nvim/undo.
o.undofile = true
o.swapfile = false

-- UI
o.signcolumn = "yes" -- always on, so text doesn't jump when a sign appears
o.cursorline = true
o.scrolloff = 8 -- keep 8 lines of context above/below the cursor
o.termguicolors = true
o.showmode = false -- the statusline already says it
o.winborder = "rounded" -- 0.12: default border for all floating windows

-- Timings
o.updatetime = 250 -- faster CursorHold (diagnostics, gitsigns blame)
o.timeoutlen = 400 -- how long to wait for a mapping sequence

-- Use the system clipboard for yank/put. Drop this line if you'd rather
-- keep Neovim's registers separate from the OS.
o.clipboard = "unnamedplus"

-- Show whitespace that usually matters
o.list = true
o.listchars = "tab:» ,trail:·,nbsp:␣"

-- Diagnostics: virtual text is noisy by default, so keep it terse.
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
})
