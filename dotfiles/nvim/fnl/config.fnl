;; ~/.config/nvim/fnl/config.fnl

;; ==============================================================================
;; 1. BASE OPTIONS & KEYMAPS
;; ==============================================================================
(set vim.g.mapleader " ")
(set vim.g.maplocalleader ",")

;; --- UI & Display ---
(set vim.opt.number true)

;; Relative line numbers for easy jumping (e.g., 5j)
(set vim.opt.termguicolors true)

;; Enable 24-bit RGB colors
(set vim.opt.cursorline true)

;; Highlight the current line
(set vim.opt.cursorlineopt :number)

;; Only highlight the line number, not the whole line — avoids j/k redraw lag
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

;; Auto-indent new lines intelligently
(vim.cmd "filetype plugin indent on")

;; --- Search ---
(set vim.opt.ignorecase true)

;; Case-insensitive search
(set vim.opt.smartcase true)

;; ...unless you type a capital letter
(set vim.opt.inccommand :split)

;; Show live preview of search/replace across the file

;; --- Quality of Life ---
(set vim.opt.clipboard :unnamedplus)

;; Paste from system clipboard in Insert mode using Ctrl+v
(vim.keymap.set :i :<C-v> :<C-r>+)

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
       [;; LISP COMPILER: hotpot.nvim (already loaded by init.lua;
        ;; listed here so Lazy can manage updates)
        {1 :rktjmp/hotpot.nvim :version :^2.0.0 :lazy false}
        ;; UI: Catppuccin Theme
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
        ;; Neovim
        ;; LSP: Mason & Nvim-Lspconfig
        ;{1 :MeanderingProgrammer/render-markdown.nvim
        ;:dependencies [:nvim-treesitter/nvim-treesitter :nvim-mini/mini.nvim]
        ;;;@module 'render-markdown'
        ;;;@type render.md.UserConfig
        ;:opts {}}
        {1 :Olical/conjure :ft [:fennel :clojure]}
        {1 :junegunn/goyo.vim}
        {1 :toppair/peek.nvim
         :event [:VeryLazy]
         :build "deno task --quiet build:fast"
         :config (fn []
                   (let [peek (require :peek)
                         ;; Only WSL needs special handling: peek's default
                         ;; `app = "webview"` wants a GUI display, which WSL
                         ;; lacks but macOS / desktop Linux have. So on WSL we
                         ;; point peek straight at the Windows browser and let
                         ;; it append the URL; everywhere else we keep peek's
                         ;; default. (This file is shared across machines.)
                         ;;
                         ;; We hand peek the browser executable directly rather
                         ;; than routing through `cmd.exe /c start`. That shell
                         ;; chain kept breaking: bare `cmd.exe` went unfound when
                         ;; WSL stopped appending System32 to PATH
                         ;; (appendWindowsPath), and `start` adds quirks of its
                         ;; own (the empty title arg, UNC-path warnings). $BROWSER
                         ;; is exported in home-work.nix; fall back to
                         ;; explorer.exe (opens the default browser) if unset.
                         browser (or (os.getenv :BROWSER)
                                     :/mnt/c/Windows/explorer.exe)
                         opts (if (= 1 (vim.fn.has :wsl))
                                  {:app [browser]}
                                  {})]
                     (peek.setup opts)
                     (vim.api.nvim_create_user_command :PeekOpen peek.open {})
                     (vim.api.nvim_create_user_command :PeekClose peek.close {})))}
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
        ;; Eager-loaded (per oil's README) so it registers its directory
        ;; buffer handler before `nvim .` / `:e dir/` are used.
        {1 :stevearc/oil.nvim
         :lazy false
         :dependencies [:nvim-tree/nvim-web-devicons]
         :opts {:default_file_explorer true
                :delete_to_trash true
                :skip_confirm_for_simple_edits true
                :view_options {:show_hidden true}}
         ;; Lazy.nvim native keybinding
         :keys [{1 "-" 2 :<cmd>Oil<CR> :desc "Open Parent Directory"}]}
        ;; THE SWISS ARMY KNIFE: snacks.nvim
        {1 :folke/snacks.nvim
         :priority 1000
         :lazy false
         :opts {:notifier {:enabled true :timeout 3000}
                ;; Beautiful popup notifications
                :dashboard {:enabled false}
                ;; Startup screen with recent files
                :bigfile {:enabled true}
                ;; Auto-disables LSP/Treesitter on massive files so Nvim doesn't freeze
                :quickfile {:enabled true}
                ;; Renders files instantly before plugins even load
                :words {:enabled false}
                ;; Auto-highlights matching variables under your cursor — disabled,
                ;; the CursorMoved LSP documentHighlight calls caused j/k lag
                :zen {:enabled true
                      :wo {:number false
                           :relativenumber false
                           :fillchars "eob: "
                           :signcolumn (.. "" :no)}
                      :opts {:showmode false
                             :laststatus 0
                             :cmdheight 0
                             ;; --- Hides the bottom right ruler ---
                             :ruler false}
                      :win {:backdrop {:transparent false :blend 99}}
                      :on_open (fn []
                                 (set vim.opt.number false)
                                 (set vim.opt.ruler false)
                                 (vim.fn.system "tmux set-option status off"))
                      :on_close (fn []
                                  (set vim.opt.number true)
                                  (set vim.opt.ruler true)
                                  (vim.fn.system "tmux set-option status on"))}}
         ;; Distraction-free coding mode
         :keys [{1 :<leader>z
                 2 (fn []
                     ((. (require :snacks) :zen :zen)))
                 :desc "Toggle Zen Mode"}
                {1 :<leader>gB
                 2 (fn []
                     ((. (require :snacks) :gitbrowse :open)))
                 :desc "Open line in Github/Browser"}
                {1 :<leader>nd
                 2 (fn []
                     ((. (require :snacks) :notifier :hide)))
                 :desc "Dismiss All Notifications"}
                {1 "]]"
                 2 (fn []
                     ((. (require :snacks) :words :jump) 1 true))
                 :desc "Next Variable Reference"}
                {1 "[["
                 2 (fn []
                     ((. (require :snacks) :words :jump) -1 true))
                 :desc "Prev Variable Reference"}]}
        ;; TMUX INTEGRATION: Smart-Splits (Navigation & Resizing)
        ;; `:opts` is required — without it, setup() never runs and the
        ;; `@pane-is-vim` tmux variable is never written, so the tmux side
        ;; can't tell when to forward C-h/j/k/l to nvim.
        {1 :mrjones2014/smart-splits.nvim
         :lazy false
         :opts {}
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
                :delay 200
                :notify false
                :spec [{1 :<leader>f :group "Find (Fzf)" :icon " "}
                       {1 :<leader>c :group :Code :icon " "}
                       {1 :<leader>r :group :Refactor :icon " "}
                       {1 :<leader>d :group :Diagnostics :icon " "}
                       {1 :<leader>w :group :Workspace :icon " "}
                       {1 :<leader>g :group :Git :icon " "}
                       {1 :<leader>n :group :Notifications :icon " "}]}}
        {1 :obsidian-nvim/obsidian.nvim
         :version "*"
         ;;@module 'obsidian'
         ;;@type obsidian.config
         :init (fn []
                 ;; auto set conceallevel=2 when a markdown file opens
                 (vim.api.nvim_create_autocmd [:FileType]
                                              {:pattern [:markdown]
                                               :callback (fn []
                                                           (set vim.opt_local.conceallevel
                                                                2)
                                                           (set vim.opt_local.concealcursor
                                                                :nc))}))
         :opts {:legacy_commands false
                :note_id_func (fn [title]
                                ;; By default, obsidian.nvim generates "16893949-Zettelkasten" IDs.
                                ;; This function overrides that to use clean, slugified filenames 
                                ;; (e.g., "Architecture Diagram" -> "architecture-diagram").
                                (if title
                                    (-> title
                                        (: :lower)
                                        (: :gsub "[^%w_ -]" "") ; strip bad characters
                                        (: :gsub "%s+" "-"))
                                    ; replace spaces with hyphens
                                    (tostring (os.time))))
                :workspaces [{:name :public :path "~/vaults/public"}
                             {:name :constellation
                              :path "~/vaults/constellation"}]}}
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
(let [lazy (require :lazy)
      api (require :hotpot.api)
      context (assert (api.context (vim.fn.stdpath :config)))]
  (lazy.setup plugins
              {:lockfile (.. (vim.fn.stdpath :state) :/lazy-lock.json)
               :performance {:rtp {:paths [(context.locate :destination)]}}}))
