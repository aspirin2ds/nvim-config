-- Key bindings that don't depend on any plugin.
--
-- The <leader> layout is one noun per letter:
--
--   b  buffer        s  search (content)
--   c  code          u  ui / toggles
--   f  file / find   w  window
--   g  git           x  diagnostics
--   h  harpoon       q  quit
--
-- Groups are split across files by what they need, so a group's keys may
-- live in more than one place:
--   here            -- needs nothing
--   lua/plugins.lua -- needs a plugin (f, s, g, h, and most of u/x)
--   lua/lsp.lua     -- needs an attached language server (c, and goto maps)
-- which-key names the groups, so pressing <leader> always shows the truth.

local map = vim.keymap.set

-- --------------------------------------------------------------- essentials
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save with Ctrl-S from any mode. <leader>w is the window group now.
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR><Esc>", { desc = "Save file" })

-- ------------------------------------------------------------------ window
-- Navigation keeps the bare <C-hjkl> form -- it's used constantly and a
-- leader prefix would only slow it down.
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

map("n", "<leader>ww", "<C-w>p", { desc = "Other window" })
map("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split below" })
map("n", "<leader>wv", "<C-w>v", { desc = "Split right" })
map("n", "<leader>w=", "<C-w>=", { desc = "Balance windows" })

-- ------------------------------------------------------------------ buffer
-- <S-h>/<S-l> are re-pointed at bufferline in lua/plugins.lua so they follow
-- the visual tab order; the rest of the b group lives there too.
map("n", "<leader>bb", "<cmd>edit #<CR>", { desc = "Switch to other buffer" })

-- ------------------------------------------------------------- diagnostics
-- <leader>xx (list) and the rest of the x group need fzf-lua, so they're in
-- lua/plugins.lua. These two need nothing.
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Diagnostic float at cursor" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
-- [d and ]d already navigate diagnostics -- those are Nvim defaults.

-- ---------------------------------------------------------------- toggles
-- The rest of the u group (format-on-save, inlay hints) is in the files that
-- own those features.
map("n", "<leader>uw", function()
  vim.o.wrap = not vim.o.wrap
  vim.notify("wrap: " .. tostring(vim.o.wrap))
end, { desc = "Toggle wrap" })

map("n", "<leader>us", function()
  vim.o.spell = not vim.o.spell
  vim.notify("spell: " .. tostring(vim.o.spell))
end, { desc = "Toggle spell" })

map("n", "<leader>ul", function()
  vim.o.relativenumber = not vim.o.relativenumber
  vim.notify("relativenumber: " .. tostring(vim.o.relativenumber))
end, { desc = "Toggle relative numbers" })

map("n", "<leader>ud", function()
  local on = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not on)
  vim.notify("diagnostics: " .. tostring(not on))
end, { desc = "Toggle diagnostics" })

-- --------------------------------------------------------------------- quit
map("n", "<leader>qq", "<cmd>qall<CR>", { desc = "Quit all" })
map("n", "<leader>qQ", "<cmd>qall!<CR>", { desc = "Quit all (discard changes)" })

-- ------------------------------------------------------------------ editing
-- Move the visual selection, keeping indentation correct
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Keep the cursor centred when jumping half-pages or cycling matches
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Stay in visual mode after shifting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})
