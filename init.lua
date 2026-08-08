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
