-- Editor settings. Every line here is something you can look up with
-- :h 'optionname' -- if you don't know why one is here, delete it and see.

local o = vim.o

-- Leader must be set before any mapping that uses it.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Clipboard. Only forced when this is a remote session.
--
-- Over SSH, auto-detection picks the *tmux* provider when $TMUX is set, which
-- writes to a tmux paste buffer on the server -- the text never leaves the
-- box, and the + register still reads back correctly, so it looks like it
-- worked. Failing that it falls through to xclip, which needs an X display a
-- headless server doesn't have. OSC 52 instead hands the text to the terminal
-- emulator as an escape sequence, so it reaches whatever machine you're
-- actually sitting at.
--
-- Nvim can auto-detect OSC 52 support, but only "if no other clipboard-tool
-- is found and when 'clipboard' is unset" -- and a multiplexer inhibits the
-- detection anyway (:h clipboard-osc52). So force it.
--
-- Copy goes out over OSC 52; paste deliberately does NOT. An OSC 52 *read*
-- asks the terminal to send the clipboard back, which many terminals refuse
-- for security -- and Nvim's builtin provider then blocks for a full second,
-- prints "Waiting for OSC 52 response... Press Ctrl-C to interrupt", and
-- waits nine more before giving up. With 'clipboard' = unnamedplus below,
-- every single `p` would pay that. So the paste half reads the unnamed
-- register instead: yanking here and putting here works, and text yanked on
-- the client machine is pasted with the terminal's own paste (bracketed
-- paste), which is how you'd do it anyway.
--
-- Running locally this block is skipped on purpose: pbcopy on macOS (or
-- wl-copy / xclip on a Linux desktop) is the better provider. OSC 52 *reads*
-- are refused by many terminals for security even when writes are allowed,
-- which would make pasting from the system clipboard unreliable.
--
-- Requires, outside Nvim, on the remote side:
--   tmux    set -g set-clipboard on   (the default "external" refuses to
--                                      forward OSC 52 from apps in a pane)
--   iTerm2  Settings > General > Selection >
--           "Applications in terminal may access clipboard"
--
-- Must be set before anything calls has('clipboard'), which is what
-- initialises the provider -- hence the position at the top of this file.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local paste = function()
    return vim.split(vim.fn.getreg('"'), "\n")
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

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

-- Persistent undo across restarts, plus swap-based recovery for unsaved edits.
-- Undo history lives in ~/.local/state/nvim/undo; swap files use Nvim's
-- standard state directory and are removed after a clean exit.
o.undofile = true
o.swapfile = true

-- UI
o.signcolumn = "yes" -- always on, so text doesn't jump when a sign appears
o.cursorline = true
o.scrolloff = 8 -- keep 8 lines of context above/below the cursor
o.termguicolors = true
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
