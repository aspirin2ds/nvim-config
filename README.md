# nvim

A from-scratch Neovim config. No distro, no framework.

It leans on what Neovim 0.12 provides natively, so several things most configs
install a plugin for aren't here:

| Usually a plugin | Here |
| --- | --- |
| lazy.nvim / packer | `vim.pack` |
| nvim-lspconfig | `vim.lsp.enable` + `lsp/*.lua` |
| nvim-cmp / blink.cmp | `vim.o.autocomplete` |

## Requirements

Neovim **0.12+** (`vim.pack` and `vim.o.autocomplete` don't exist before it).

These are **not** installed by this repo and must exist on the machine first:

| Tool | Needed for | Debian/Ubuntu |
| --- | --- | --- |
| `git` | vim.pack | `apt install git` |
| C compiler | building treesitter parsers | `apt install build-essential` |
| `ripgrep` | `<leader>/` and all grep pickers | `apt install ripgrep` |
| `fzf` | fzf-lua (every picker) | [release binary](https://github.com/junegunn/fzf/releases) |
| `node` + `npm` | mason installs vtsls, tailwindcss, json-lsp | [nodejs.org](https://nodejs.org) — apt's is too old |
| `python3-venv`, `python3-pip` | mason installs basedpyright | `apt install python3-venv python3-pip` |
| Go toolchain | mason builds gopls | `apt install golang` |
| A **Nerd Font** | icons in the file tree and tabline | [nerdfonts.com](https://www.nerdfonts.com) |

Without a Nerd Font everything still works, but icons render as tofu boxes.

Everything else — plugins, language servers, formatters, treesitter parsers —
installs itself on first launch.

## Install

```sh
git clone https://github.com/aspirin2ds/nvim-config.git ~/.config/nvim
nvim
```

**Launch twice on a new machine.** The first run installs plugins and mason
fetches the tree-sitter CLI; parsers compile on the second. To try it without
touching an existing config:

```sh
git clone https://github.com/aspirin2ds/nvim-config.git ~/.config/nvim-test
NVIM_APPNAME=nvim-test nvim
```

## Keymaps

`<leader>` is <kbd>Space</kbd>. Press it and wait — which-key lists everything.

One noun per letter:

| Prefix | Group |
| --- | --- |
| `<leader>b` | buffer |
| `<leader>c` | code (LSP) |
| `<leader>f` | file / find *(which file)* |
| `<leader>g` | git |
| `<leader>h` | harpoon |
| `<leader>q` | quit |
| `<leader>s` | search *(find text)* |
| `<leader>u` | ui / toggles |
| `<leader>w` | window |
| `<leader>x` | diagnostics |

The `f` / `s` split is the one worth internalising: **`f` when you know the
file name, `s` when you're searching content.**

### Most used

| Key | Action |
| --- | --- |
| `<leader><space>` | Find files |
| `<leader>,` | Switch buffer |
| `<leader>/` | Grep in project |
| `<leader>e` / `<leader>E` | Toggle file tree / reveal current file |
| `<C-s>` | Save |
| `s` / `S` | Flash jump / treesitter select |

### Navigation

| Key | Action |
| --- | --- |
| `<C-h/j/k/l>` | Move between windows |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<leader>1`–`4` | Jump to harpoon slot |
| `<C-p>` / `<C-n>` | Previous / next harpoon file |
| `[d` / `]d` | Previous / next diagnostic |
| `[h` / `]h` | Previous / next git hunk |

### LSP

| Key | Action |
| --- | --- |
| `gd` / `gD` | Definition / declaration |
| `gI` / `gy` | Implementation / type definition |
| `grr` / `grn` / `gra` | References / rename / code action |
| `K` | Hover |
| `<leader>ca` / `<leader>cr` | Code action / rename |
| `<leader>cf` | Format buffer or selection |
| `<leader>cs` | Document symbols |

`grn`, `gra`, `grr`, `gri`, `grt` are Neovim 0.11+ built-ins. Nothing maps a
bare `gr` on purpose — `gr` is a prefix of all five, so mapping it directly
makes Vim wait `timeoutlen` on every press.

### Find / search

| Key | Action |
| --- | --- |
| `<leader>ff` / `<leader>fr` / `<leader>fb` | Files / recent / buffers |
| `<leader>sg` / `<leader>sw` | Grep project / word under cursor |
| `<leader>sb` | Search in current buffer |
| `<leader>sh` / `<leader>sk` | Help / keymaps |
| `<leader>sr` | Resume last picker |

### Diagnostics and toggles

| Key | Action |
| --- | --- |
| `<leader>xx` / `<leader>xX` | All / buffer diagnostics |
| `<leader>xd` | Diagnostic float at cursor |
| `<leader>uf` | Toggle format-on-save |
| `<leader>uh` | Toggle inlay hints |
| `<leader>uw` / `<leader>us` | Toggle wrap / spell |

## Language servers

Configured in `lsp/*.lua`, one plain table per server, auto-discovered by
Neovim. Installed by mason on first launch.

| Server | For |
| --- | --- |
| `lua_ls` | Lua (including this config) |
| `gopls` | Go |
| `vtsls` | TypeScript / JavaScript |
| `basedpyright` | Python |
| `biome` | JS/TS/JSON/CSS lint + format |
| `tailwindcss` | Tailwind class completion |
| `jsonls` | JSON schema validation |

Several attach to the same buffer on purpose — a `.tsx` file gets vtsls for
types, biome for lint, and tailwindcss for classes. They cover different
things.

**Root detection differs per server, deliberately.** In a monorepo, vtsls and
tailwindcss root per-app (each has its own `tsconfig.json` / stylesheet) while
biome roots at the repo top, where `biome.json` and its `overrides` live.

## Formatting

conform.nvim, format-on-save enabled (`<leader>uf` toggles, `:FormatToggle!`
for the current buffer only).

| Filetype | Formatter |
| --- | --- |
| Lua | stylua |
| Shell | shfmt |
| Python | ruff |
| JS/TS/JSON/CSS | **biome** |
| HTML/YAML/Markdown | prettier |
| Go | gopls (gofumpt) |

Biome, not prettier, formats everything biome supports. Their defaults are
opposites — prettier wants double quotes and forced semicolons, a typical
`biome.json` wants single quotes and `semicolons: asNeeded`. Running the wrong
one rewrites whole files and breaks `lint`. vtsls has its formatting capability
disabled on attach so it can't win that race either.

## Plugins

Twelve, plus two dependencies (`nvim-web-devicons`, `plenary.nvim`). Managed
by `vim.pack`.

| Plugin | Role |
| --- | --- |
| catppuccin | Colorscheme (mocha) |
| nvim-treesitter | Parsing, highlighting, text objects |
| mason + mason-tool-installer | Installs servers and formatters |
| fzf-lua | All pickers |
| conform.nvim | Formatting |
| nvim-tree | File explorer |
| bufferline.nvim | Buffers as tabs |
| flash.nvim | Jump motions |
| harpoon | Pinned file slots |
| gitsigns.nvim | Git signs, hunks, blame |
| which-key.nvim | Shows what `<leader>` does |

nvim-treesitter tracks the **`main`** branch. `master` is frozen and does not
work on 0.12.

## Layout

```
init.lua              4 requires, a table of contents
lua/options.lua       editor settings
lua/keymaps.lua       maps needing no plugin
lua/plugins.lua       vim.pack + plugin setup and maps
lua/lsp.lua           vim.lsp.enable + completion + LspAttach maps
lsp/*.lua             one table per language server
nvim-pack-lock.json   plugin revisions — committed on purpose
```

A `<leader>` group can span files, because each key lives with whatever it
depends on. which-key always reflects reality.

## Maintenance

```vim
:lua vim.pack.update()   " review the diff, :w to confirm
:Mason                   " manage language servers
:TSSync                  " install missing treesitter parsers
:checkhealth             " diagnose
```

After an update that leaves you working:

```sh
git -C ~/.config/nvim add -A
git -C ~/.config/nvim commit -m "update plugins"
git -C ~/.config/nvim push
```

`nvim-pack-lock.json` pins every plugin to an exact commit. It is committed
deliberately — it's what makes this reproduce on another machine, and it's the
rollback path:

```sh
git checkout HEAD~1 nvim-pack-lock.json
```

then `:lua vim.pack.update()`.

Mason's tools are **not** covered by that lockfile; it tracks its own versions.
Add [mason-lock.nvim](https://github.com/zapling/mason-lock.nvim) if server
drift across machines becomes a problem.

## Gotchas

- **`s` is flash**, not substitute-character. Use `cl`.
- **`<leader>e` is the file tree.** The diagnostic float is `<leader>xd`.
- **Two launches** on a fresh machine before treesitter parsers exist.
- **`lua/local.lua` is gitignored** — put machine-specific settings there and
  `pcall(require, "local")` from `init.lua`.
