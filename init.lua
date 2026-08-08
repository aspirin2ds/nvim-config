-- ~/.config/nvim/init.lua
--
-- Entry point. Deliberately thin -- it should read like a table of contents.
-- Each require() below is a file in lua/. Read them in this order.
--
-- Neovim 0.12+ only. This config leans on things that used to need plugins:
--   plugin management -> vim.pack        (:h vim.pack)
--   LSP config        -> vim.lsp.enable  (:h lsp-config)
--   completion        -> vim.o.autocomplete

require("options") -- editor settings
require("keymaps") -- key bindings that don't depend on plugins
require("plugins") -- vim.pack + plugin setup
require("lsp") -- language servers + completion

-- Machine-specific overrides. lua/local.lua is gitignored, so this is where
-- anything that shouldn't sync goes -- work-only paths, a different
-- colourscheme on one box, experiments. Optional: pcall means a machine
-- without the file starts normally.
--
-- Loaded last so it can override anything above. The one exception is
-- vim.g.clipboard, which has to be set before the clipboard provider
-- initialises -- put that in lua/options.lua instead.
pcall(require, "local")
