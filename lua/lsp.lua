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

-- More than one server can attach to the same buffer, and that's intended:
-- a .tsx file gets vtsls (types), biome (lint), and tailwindcss (classes)
-- at once. They cover different things and don't overlap -- except on
-- formatting, which is resolved in the LspAttach handler below.
local servers = {
  "lua_ls",
  "gopls",
  "vtsls",
  "basedpyright",
  "biome",
  "tailwindcss",
  "jsonls",
}

local function enable_servers()
  vim.lsp.enable(servers)
end

if vim.v.vim_did_enter == 1 then
  enable_servers()
else
  -- Starting several project servers delays the first screen even though the
  -- clients themselves are asynchronous. Enable them once the UI is ready;
  -- vim.lsp.enable() also considers the buffer opened during startup.
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.defer_fn(enable_servers, 30)
    end,
  })
end

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
    map("gI", fzf.lsp_implementations, "Go to implementation")
    map("gy", fzf.lsp_typedefs, "Go to type definition")

    -- Deliberately NOT a bare `gr`. Nvim 0.11+ ships grn/gra/grr/gri/grt,
    -- so `gr` is a prefix of five built-ins -- mapping it directly makes Vim
    -- wait the full 'timeoutlen' on every press to see whether more keys are
    -- coming. Overriding grr keeps the native grammar and the nicer picker.
    map("grr", fzf.lsp_references, "List references")

    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>cs", fzf.lsp_document_symbols, "Document symbols")
    map("<leader>ci", fzf.lsp_incoming_calls, "Incoming calls")
    map("<leader>co", fzf.lsp_outgoing_calls, "Outgoing calls")
    -- NOTE: formatting is NOT mapped here. conform owns <leader>cf (see
    -- lua/plugins.lua) so the same key works in buffers with no LSP at all.

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- Biome is the formatter for JS/TS/JSON/CSS. vtsls also advertises
    -- formatting, and its style is prettier-like -- double quotes, forced
    -- semicolons -- which is the opposite of most biome.json setups. Turn it
    -- off so nothing can pick the wrong one by accident.
    if client.name == "vtsls" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
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

    -- Inlay hints, off by default. Lives in the u (toggles) group.
    if client:supports_method("textDocument/inlayHint") then
      map("<leader>uh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
      end, "Toggle inlay hints")
    end
  end,
})
