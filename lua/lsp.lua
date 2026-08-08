-- Language servers and completion -- both native to Neovim 0.12.
--
-- Each server's config is a plain table returned from lsp/<name>.lua. Neovim
-- picks those up automatically from anywhere on 'runtimepath', so there is no
-- registration step: write the file, add the name below, done.
--
--   :lsp              show status of enabled servers
--   :checkhealth vim.lsp
--
-- nvim-lspconfig is NOT installed. It's now just a catalog of these same
-- tables; with four servers it's less work to write them yourself. Add it
-- later if you want its several-hundred-server library.

vim.lsp.enable({
  "lua_ls",
  "gopls",
  "vtsls",
  "basedpyright",
})

-- ------------------------------------------------------------------ completion
-- 0.12 has insert-mode autocompletion built in. No nvim-cmp, no sources,
-- no snippet engine wiring.
vim.o.completeopt = "menu,menuone,noselect,popup,fuzzy"
vim.o.autocomplete = true -- trigger without pressing <C-x><C-o>
vim.o.pumheight = 12

-- ------------------------------------------------------------------- on attach
-- These maps only make sense when a server is actually attached, so they're
-- set per-buffer rather than globally.
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP keymaps and per-server features",
  callback = function(ev)
    local buf = ev.buf
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
    end

    -- Neovim 0.11+ already provides sensible defaults for grn/gra/grr/gri
    -- and K -- see :h lsp-defaults. These add the gd-style bindings most
    -- people expect, backed by fzf-lua so multiple results are pickable.
    local fzf = require("fzf-lua")
    map("gd", fzf.lsp_definitions, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", fzf.lsp_references, "List references")
    map("gI", fzf.lsp_implementations, "Go to implementation")
    map("gy", fzf.lsp_typedefs, "Go to type definition")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>cs", fzf.lsp_document_symbols, "Document symbols")
    map("<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer")

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- Highlight other references to the symbol under the cursor.
    if client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("lsp_highlight_" .. buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        buffer = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        buffer = buf,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- Inlay hints, off by default -- toggle with <leader>ch.
    if client:supports_method("textDocument/inlayHint") then
      map("<leader>ch", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
      end, "Toggle inlay hints")
    end
  end,
})
