;; ~/.config/nvim/fnl/config.fnl

;; ==============================================================================
;; 1. BASE OPTIONS & KEYMAPS
;; ==============================================================================
(set vim.g.mapleader " ")
(set vim.g.maplocalleader " ")

(set vim.opt.number true)
(set vim.opt.relativenumber true)
(set vim.opt.clipboard "unnamedplus")
(set vim.opt.ignorecase true)
(set vim.opt.smartcase true)
(set vim.opt.termguicolors true)

;; ==============================================================================
;; 2. PLUGIN SPECIFICATION (Using lazy.nvim)
;; ==============================================================================
(local plugins
  [
   ;; UI: Catppuccin Theme
   {1 :catppuccin/nvim
    :name :catppuccin
    :priority 1000
    :config (fn [] (vim.cmd.colorscheme :catppuccin-mocha))}

   ;; SYNTAX: Treesitter (Main Branch Rewrite)
   {1 :nvim-treesitter/nvim-treesitter
    :branch "main"
    :build ":TSUpdate"
    :config (fn []
              (let [ts (require :nvim-treesitter)
                    langs [:lua :fennel :python :javascript :markdown :c]]
                
                ;; 1. Download parsers (Replaces `ensure_installed`)
                ;; Note: This safely acts as a no-op if they are already installed.
                (ts.install langs)
                
                ;; 2. Enable Native Highlighting (Replaces `highlight = { enable = true }`)
                (vim.api.nvim_create_autocmd
                 :FileType
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
                (vim.api.nvim_create_autocmd
                 :LspAttach
                 {:callback (fn [args]
                              ;; A tiny helper function for clean mappings
                              (let [map (fn [keys func desc]
                                          (vim.keymap.set :n keys func {:buffer args.buf :desc desc}))]
                                
                                ;; Standard Neovim Native Actions
                                (map "gd" vim.lsp.buf.definition "Go to Definition")
                                (map "gD" vim.lsp.buf.declaration "Go to Declaration")
                                (map "K" vim.lsp.buf.hover "Hover Documentation")
                                (map "<leader>ca" vim.lsp.buf.code_action "Code Action")
                                (map "<leader>rn" vim.lsp.buf.rename "Rename")

                                ;; Fzf-Lua integrations for better UI on lists
                                (map "gr" "<cmd>FzfLua lsp_references<CR>" "LSP References")
                                (map "gi" "<cmd>FzfLua lsp_implementations<CR>" "LSP Implementations")
                                (map "<leader>ds" "<cmd>FzfLua lsp_document_symbols<CR>" "Document Symbols")
                                (map "<leader>wd" "<cmd>FzfLua lsp_workspace_diagnostics<CR>" "Workspace Diagnostics")))})))}
   

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
                (vim.keymap.set :n "<leader>ff" "<cmd>FzfLua files<CR>" {:desc "Find Files"})
                (vim.keymap.set :n "<leader>fg" "<cmd>FzfLua live_grep<CR>" {:desc "Live Grep"})))}

   ;; FORMATTING: conform.nvim
   {1 :stevearc/conform.nvim
    :opts {:formatters_by_ft {:lua [:stylua]
                              :fennel [:fnlfmt]}
           :format_on_save {:timeout_ms 500
                            :lsp_format :fallback}}}
  ])

;; Run lazy.setup
(let [lazy (require :lazy)]
  (lazy.setup plugins 
              {:lockfile (.. (vim.fn.stdpath :state) "/lazy-lock.json")
               :performance {:rtp {:reset false}}}))
