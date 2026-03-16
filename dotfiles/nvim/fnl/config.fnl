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

   ;; SYNTAX: Treesitter
   {1 :nvim-treesitter/nvim-treesitter
    :build ":TSUpdate"
    :config (fn []
              (let [ts (require :nvim-treesitter.configs)]
                (ts.setup {:ensure_installed [:lua :fennel :python :javascript :markdown :c]
                           :highlight {:enable true}})))}

   ;; LSP: Mason & Nvim-Lspconfig
   {1 :neovim/nvim-lspconfig
    :dependencies [:williamboman/mason.nvim
                   :williamboman/mason-lspconfig.nvim]
    :config (fn []
              (let [mason (require :mason)
                    mason-lsp (require :mason-lspconfig)
                    lsp (require :lspconfig)]
                (mason.setup)
                (mason-lsp.setup {:ensure_installed [:lua_ls :fennel_language_server]})
                (lsp.lua_ls.setup {})
                (lsp.fennel_language_server.setup {})))}

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
  (lazy.setup plugins))
