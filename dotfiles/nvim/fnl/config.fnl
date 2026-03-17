;; ~/.config/nvim/fnl/config.fnl

;; ==============================================================================
;; 1. BASE OPTIONS & KEYMAPS
;; ==============================================================================
(set vim.g.mapleader " ")
(set vim.g.maplocalleader " ")

;; ==============================================================================
;; 1. BASE OPTIONS & KEYMAPS
;; ==============================================================================
(set vim.g.mapleader " ")
(set vim.g.maplocalleader " ")

;; --- UI & Display ---
(set vim.opt.number true)

;; Show line numbers
(set vim.opt.relativenumber true)

;; Relative line numbers for easy jumping (e.g., 5j)
(set vim.opt.termguicolors true)

;; Enable 24-bit RGB colors
(set vim.opt.cursorline true)

;; Highlight the current line
(set vim.opt.signcolumn :yes)

;; Always show the gutter (prevents text shifting when errors appear)
(set vim.opt.scrolloff 8)

;; Keep 8 lines above/below the cursor when scrolling

;; --- Tabs & Indentation ---
(set vim.opt.expandtab true)

;; Convert Tabs to spaces
(set vim.opt.shiftwidth 2)

;; Indent size
(set vim.opt.tabstop 2)

;; Tab size
(set vim.opt.smartindent true)

;; Auto-indent new lines intelligently

;; --- Search ---
(set vim.opt.ignorecase true)

;; Case-insensitive search
(set vim.opt.smartcase true)

;; ...unless you type a capital letter
(set vim.opt.inccommand :split)

;; Show live preview of search/replace across the file

;; --- Quality of Life ---
(set vim.opt.clipboard :unnamedplus)

;; Sync with system clipboard
(set vim.opt.updatetime 250)

;; Faster completion and hover delays (default is 4000ms)
(set vim.opt.splitright true)

;; Vertical splits open to the right
(set vim.opt.splitbelow true)

;; Horizontal splits open below

;; ==============================================================================
;; 2. PLUGIN SPECIFICATION (Using lazy.nvim)
;; ==============================================================================
(local plugins
       [;; UI: Catppuccin Theme
        {1 :catppuccin/nvim
         :name :catppuccin
         :priority 1000
         :config (fn [] (vim.cmd.colorscheme :catppuccin-mocha))}
        ;; SYNTAX: Treesitter (Main Branch Rewrite)
        {1 :nvim-treesitter/nvim-treesitter
         :branch :main
         :build ":TSUpdate"
         :config (fn []
                   (let [ts (require :nvim-treesitter)
                         langs [:lua :fennel :python :javascript :markdown :c]]
                     ;; 1. Download parsers (Replaces `ensure_installed`)
                     ;; Note: This safely acts as a no-op if they are already installed.
                     (ts.install langs)
                     ;; 2. Enable Native Highlighting (Replaces `highlight = { enable = true }`)
                     (vim.api.nvim_create_autocmd :FileType
                                                  {:pattern langs
                                                   :callback (fn [args]
                                                               (vim.treesitter.start args.buf))})))}
        ;; LSP: Mason & Nvim-Lspconfig
        {1 :neovim/nvim-lspconfig
         :dependencies [:williamboman/mason.nvim
                        :williamboman/mason-lspconfig.nvim]
         :config (fn []
                   (let [mason (require :mason)
                         mason-lsp (require :mason-lspconfig)
                         ;; 1. Add :omnisharp to your server list
                         servers [:lua_ls :fennel_language_server :omnisharp]]
                     (mason.setup)
                     (mason-lsp.setup {:ensure_installed servers})
                     (vim.lsp.config :fennel_language_server
                                     {:settings {:fennel {:diagnostics {:globals [:vim]}}}})
                     (vim.lsp.config :lua_ls
                                     {:settings {:Lua {:diagnostics {:globals [:vim]}}}})
                     (vim.lsp.enable servers)
                     ;; 2. Native LSP Keybindings (Triggers when an LSP attaches)
                     (vim.api.nvim_create_autocmd :LspAttach
                                                  {:callback (fn [args]
                                                               ;; A tiny helper function for clean mappings
                                                               (let [map (fn [keys
                                                                              func
                                                                              desc]
                                                                           (vim.keymap.set :n
                                                                                           keys
                                                                                           func
                                                                                           {:buffer args.buf
                                                                                            : desc}))]
                                                                 ;; Standard Neovim Native Actions
                                                                 (map :gd
                                                                      vim.lsp.buf.definition
                                                                      "Go to Definition")
                                                                 (map :gD
                                                                      vim.lsp.buf.declaration
                                                                      "Go to Declaration")
                                                                 (map :K
                                                                      vim.lsp.buf.hover
                                                                      "Hover Documentation")
                                                                 (map :<leader>ca
                                                                      vim.lsp.buf.code_action
                                                                      "Code Action")
                                                                 (map :<leader>rn
                                                                      vim.lsp.buf.rename
                                                                      :Rename)
                                                                 ;; Fzf-Lua integrations for better UI on lists
                                                                 (map :gr
                                                                      "<cmd>FzfLua lsp_references<CR>"
                                                                      "LSP References")
                                                                 (map :gi
                                                                      "<cmd>FzfLua lsp_implementations<CR>"
                                                                      "LSP Implementations")
                                                                 (map :<leader>ds
                                                                      "<cmd>FzfLua lsp_document_symbols<CR>"
                                                                      "Document Symbols")
                                                                 (map :<leader>wd
                                                                      "<cmd>FzfLua lsp_workspace_diagnostics<CR>"
                                                                      "Workspace Diagnostics")))})))}
        ;; COMPLETION: blink.cmp
        {1 :saghen/blink.cmp
         :version "*"
         :dependencies [:rafamadriz/friendly-snippets]
         :opts {:keymap {:preset :default}
                :appearance {:use_nvim_cmp_as_default false
                             :nerd_font_variant :mono}
                :signature {:enabled true}}}
        ;; FUZZY FINDER: fzf-lua
        {1 :ibhagwan/fzf-lua
         :dependencies [:nvim-tree/nvim-web-devicons]
         :config (fn []
                   (let [fzf (require :fzf-lua)]
                     (fzf.setup {})
                     (vim.keymap.set :n :<leader>ff "<cmd>FzfLua files<CR>"
                                     {:desc "Find Files"})
                     (vim.keymap.set :n :<leader>fg "<cmd>FzfLua live_grep<CR>"
                                     {:desc "Live Grep"})))}
        ;; FILE EXPLORER: oil.nvim
        {1 :stevearc/oil.nvim
         :dependencies [:nvim-tree/nvim-web-devicons]
         :opts {:default_file_explorer true
                :delete_to_trash true
                :skip_confirm_for_simple_edits true
                :view_options {:show_hidden true}}
         ;; Lazy.nvim native keybinding
         :keys [{1 "-" 2 :<cmd>Oil<CR> :desc "Open Parent Directory"}]}
        ;; TMUX INTEGRATION: Smart-Splits (Navigation & Resizing)
        {1 :mrjones2014/smart-splits.nvim
         :lazy false
         :keys [;; Navigation
                {1 :<C-h>
                 2 (fn []
                     ((. (require :smart-splits) :move_cursor_left)))
                 :desc "Window Left"}
                {1 :<C-j>
                 2 (fn []
                     ((. (require :smart-splits) :move_cursor_down)))
                 :desc "Window Down"}
                {1 :<C-k>
                 2 (fn []
                     ((. (require :smart-splits) :move_cursor_up)))
                 :desc "Window Up"}
                {1 :<C-l>
                 2 (fn []
                     ((. (require :smart-splits) :move_cursor_right)))
                 :desc "Window Right"}
                ;; Resizing
                {1 :<A-h>
                 2 (fn []
                     ((. (require :smart-splits) :resize_left)))
                 :desc "Resize Left"}
                {1 :<A-j>
                 2 (fn []
                     ((. (require :smart-splits) :resize_down)))
                 :desc "Resize Down"}
                {1 :<A-k>
                 2 (fn []
                     ((. (require :smart-splits) :resize_up)))
                 :desc "Resize Up"}
                {1 :<A-l>
                 2 (fn []
                     ((. (require :smart-splits) :resize_right)))
                 :desc "Resize Right"}]}
        ;; KEYBIND DISCOVERY: which-key.nvim (With Group Labels!)
        {1 :folke/which-key.nvim
         :event :VeryLazy
         :opts {:preset :modern
                :spec [{1 :<leader>f :group "Find (Fzf)" :icon " "}
                       {1 :<leader>c :group "Code Actions" :icon " "}]}}
        ;; FORMATTING: conform.nvim
        {1 :stevearc/conform.nvim
         :opts {:formatters_by_ft {:lua [:stylua]
                                   :fennel [:fnlfmt]
                                   :cs [:csharpier]
                                   ;; Python: Sort imports/fix, then format
                                   :python [:ruff_fix :ruff_format]
                                   ;; Web & Docs: The Daemonized Prettier
                                   :javascript [:prettierd]
                                   :typescript [:prettierd]
                                   :css [:prettierd]
                                   :markdown [:prettierd]
                                   ;; Shell Scripts
                                   :sh [:shfmt]
                                   :bash [:shfmt]
                                   ;; PowerShell (Runs `pwsh -c Invoke-Formatter`)
                                   :ps1 [:powershell]}
                :format_on_save {:timeout_ms 500 :lsp_format :fallback}}}])

;; Run lazy.setup
(let [lazy (require :lazy)]
  (lazy.setup plugins
              {:lockfile (.. (vim.fn.stdpath :state) :/lazy-lock.json)
               :performance {:rtp {:reset false}}}))
