{ config, pkgs, lib, nixpkgs-comby, gws-cli, ... }:

let
  # `pkgs.system` is deprecated; use the stdenv platform string.
  system = pkgs.stdenv.hostPlatform.system;

  repoDir = "${config.home.homeDirectory}/.config/home-manager";
in
{
  home.username = "cary";
  home.homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/cary" else "/home/cary";
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  xdg.enable = true;
  # Symlink the nvim config to the live repo dir instead of the read-only nix
  # store, so edits under dotfiles/nvim take effect without a home-manager rebuild.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/nvim";

  # reMarkable preset for pandoc: `pandoc -d remarkable notes.md -o notes.pdf`
  # renders markdown (mermaid fences included) at the tablet's native 4:3 page.
  # `-d NAME` / `--template NAME` resolve out of pandoc's user *data* dir, which
  # is ~/.local/share/pandoc — not ~/.config/pandoc. Out-of-store symlinks like
  # nvim's above, so the template stays tweakable without a rebuild.
  xdg.dataFile = {
    "pandoc/templates/remarkable.typst".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/remarkable.typst";
    "pandoc/defaults/remarkable.yaml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/remarkable.yaml";
    # Long-form reading; pulls in `remarkable` itself: `-d remarkable-article`.
    "pandoc/defaults/remarkable-article.yaml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/remarkable-article.yaml";
    # Reading without annotating; pulls in `remarkable` itself: `-d remarkable-read`.
    "pandoc/defaults/remarkable-read.yaml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/remarkable-read.yaml";
    "pandoc/filters/mermaid.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/mermaid.lua";
    "pandoc/filters/figure-appendix.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/figure-appendix.lua";
    "pandoc/filters/drop-empty-links.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/drop-empty-links.lua";
  };

  # Conjure connects to an nREPL server but never starts one, so keep a global
  # alias that stands one up in any project: `clj -M:repl/conjure`. It writes
  # .nrepl-port into the cwd, which Conjure then auto-detects on buffer open.
  #
  # The clojure CLI reads $XDG_CONFIG_HOME/clojure/deps.edn when that var is
  # set (it is here, to ~/.config) and ~/.clojure/deps.edn otherwise — so this
  # is the correct home for it on this machine, not home.file.
  #
  # cider-nrepl is optional but supplies completion, docs and jump-to-def to
  # the REPL client; plain nrepl alone gets you eval and little else.
  xdg.configFile."clojure/deps.edn".text = ''
    {:aliases
     {:repl/conjure
      {:extra-deps {nrepl/nrepl {:mvn/version "1.7.0"}
                    cider/cider-nrepl {:mvn/version "0.62.2"}}
       :main-opts ["-m" "nrepl.cmdline"
                   "--middleware" "[cider.nrepl/cider-middleware]"
                   "--interactive"]}}}
  '';

  programs.lazyworktree.enable = true;
  programs.lazysql.enable = true;
  programs.uv.enable = true;

  programs.pandoc = {
    enable = true;

    # typst rather than xelatex, so plain `pandoc x.md -o x.pdf` doesn't need
    # a ~600 MiB TeX install. These are the typst template's variable names
    # (`pandoc --print-default-template=typst`), not LaTeX's.
    defaults = {
      pdf-engine = "typst";
      variables = {
        mainfont = "DejaVu Serif";
        fontsize = "11pt";
        papersize = "us-letter";
        margin = { x = "1in"; y = "1in"; };
        section-numbering = "1.1";
      };
    };
  };

  programs.git = {
    enable = true;

    settings = {
      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
      merge.conflictStyle = "zdiff3";
      rerere.enabled = true;

      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        lg = "log --graph --oneline --decorate --all";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
        ic = "issue create";
        iv = "issue view";
      };

      editor = "nvim";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    flags = [ "--disable-up-arrow" ];

    settings = {
      keymap_mode = "vim-normal";
      search_mode = "fuzzy";
      inline_height = 20;
      ctrl_n_shortcuts = false;
    };
  };

  programs.lazygit.enable = true;

  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      yolo = "claude --dangerously-skip-permissions";
    };

    initContent = ''
      # Fast-moving developer tools are managed by mise, whose global config is
      # linked from dotfiles/mise/config.toml below. Keep this conditional so a
      # first login still works before Home Manager has installed mise.
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi

      # Only auto-attach if we are NOT already in tmux and it's an interactive shell
      if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
        # If we explicitly set TMUX_SESSION, use that, otherwise default to "main"
        SESSION_NAME=''${TMUX_SESSION:-main}
        exec tmux new-session -A -s "$SESSION_NAME"
      fi

      setopt NO_BEEP
    '';
  };

  programs.fzf = {
    enable = true;
    # Atuin owns Ctrl-R. Its zsh integration is sourced after fzf's, so without
    # this both bind the key and the winner is load-order trivia. Blanking the
    # command drops fzf's history widget only — Ctrl-T and Alt-C are untouched.
    historyWidget.command = "";
  };
  programs.zoxide.enable = true;
  programs.eza.enable = true;
  programs.starship.enable = true;

  programs.tmux = {
    enable = true;
    clock24 = true;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      catppuccin
    ];
    extraConfig = ''
      # --- Truecolor ---
      # Matched against the *client's* TERM (xterm-256color under Windows
      # Terminal), hence the `*` glob rather than a screen*/tmux* pattern.
      # Without this tmux only gains RGB when the attaching client happens to
      # export COLORTERM=truecolor, and otherwise quantizes 24-bit colours to
      # the xterm-256 palette — nvim's catppuccin-mocha #1E1E2E background
      # collapses to colour 235 (#262626) and reads as black against the
      # terminal. Takes effect at client attach, so `tmux kill-server` after a
      # rebuild.
      set -as terminal-features ",*:RGB"

      # --- Extended keys (for pi.dev and other modern TUIs) ---
      # By default tmux sends Shift+Enter, Ctrl+Enter and Enter as the same
      # key, so pi can't tell newline from submit. With extended-keys on, tmux
      # passes modified keys through, and CSI-u (tmux 3.5+) is the encoding pi
      # recommends. The extkeys feature makes tmux ask the outer terminal to
      # report modified keys at all. Restart the server (`tmux kill-server`)
      # for this to take effect.
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -as terminal-features ",*:extkeys"

      # Let apps inside tmux send escape sequences straight to the outer
      # terminal (inline images, hyperlinks), and copy to the system
      # clipboard over OSC 52.
      set -g allow-passthrough on
      set -g set-clipboard on

      # --- Prefix Setup ---
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # --- Mouse Support ---
      set -g mouse on

      # --- Appearance ---
      set -g status-position top
      set -g @catppuccin_flavor 'mocha'

      set -g history-limit 100000
      set -g @continuum-restore 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-save-interval '15'

      # --- Modern Session Management ---
      bind S display-popup -E "sesh connect \$(sesh list | fzf)"

      # --- Reload Configuration ---
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # --- Vi-Mode Copying ---
      set-window-option -g mode-keys vi

      # --- Floating Scratchpad ---
      bind g display-popup -d "#{pane_current_path}" -w 80% -h 80% -E "zsh"

      # --- Floating Linear Dashboard ---
      bind i display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "linear issue list --team MDC --sort manual --cycle active -A && read"

      # Keybindings to make copying feel like Neovim
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle

      # Don't exit copy mode when dragging with the mouse
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # --- Smart Splits (Navigation & Resizing) ---

      # Navigation
      bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
      bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
      bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
      bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

      # Resizing (Alt + hjkl)
      bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h' 'resize-pane -L 3'
      bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j' 'resize-pane -D 3'
      bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k' 'resize-pane -U 3'
      bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l' 'resize-pane -R 3'

      # Copy mode navigation
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      # Better split keys
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Open new vertical split in the current directory
      bind % split-window -h -c "#{pane_current_path}"

      # Open new horizontal split in the current directory
      bind '"' split-window -v -c "#{pane_current_path}"

      # Open new window (tab) in the home directory
      bind c new-window -c "~"

      # --- which-key style popup menu (alexwforsythe/tmux-which-key) ---
      # Loaded here (not via programs.tmux.plugins) on purpose: Home Manager
      # sources the `plugins` list *before* extraConfig, but this plugin needs
      # the XDG option set first. Without it the plugin tries to write its
      # config.yaml into its own read-only nix store dir and fails on every
      # start. XDG redirects config to ~/.config/tmux/plugins/tmux-which-key/
      # and the generated init.tmux to ~/.local/share/tmux/plugins/.
      # Trigger: prefix (C-a) then Space.
      #
      # Autobuild is disabled because it re-runs build.py on every start to
      # regenerate init.tmux — but that file is cp'd from the read-only nix
      # store (mode 0444), so the write fails, set -e aborts the loader, and
      # the menu never binds. With autobuild off we just source the already
      # generated init.tmux (the plugin's bundled default menu). To customize
      # the menu later we regenerate init.tmux out-of-band rather than at load.
      set -g @tmux-which-key-xdg-enable 1
      set -g @tmux-which-key-disable-autobuild 1
      run-shell ${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key/plugin.sh.tmux
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Wrap the nvim binary with its args instead of writing init.lua, leaving the
    # out-of-store config symlink above untouched.
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      cargo
      gcc
      gnumake
      tree-sitter

      # clojure-lsp is a GraalVM native image, so it needs no JVM itself; it
      # shells out to `clj -Spath` for classpaths, which the wrapper above
      # satisfies. Unlike lua_ls/fennel_language_server this comes from nix rather than
      # mason, so config.fnl enables it outside the ensure_installed list.
      clojure-lsp

      # Formatters
      stylua
      fnlfmt
      ruff
      prettierd
      shfmt
      cljfmt
    ]
    # csharpier drags in a full .NET 8 SDK (~1.1 GiB); C# is only written on
    # the Linux/WSL work box. config.fnl skips C# tooling on the Mac to match.
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.csharpier ];
  };

  # Recompile the fennel config after each rebuild. Hotpot only syncs on its
  # first boot and when a .fnl file is saved *inside* nvim, so edits that
  # arrive any other way (git pull, another editor, an agent) would otherwise
  # leave stale compiled lua behind. The .fnl files are real files in this
  # repo (out-of-store symlink above), so hotpot's mtime check is accurate and
  # a plain sync recompiles only what changed.
  home.activation.hotpotSync =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      HOTPOT_DIR="$HOME/.local/share/nvim/lazy/hotpot.nvim"
      NVIM_CONFIG="$HOME/.config/nvim"
      if [ -d "$HOTPOT_DIR" ] && [ -e "$NVIM_CONFIG/init.lua" ]; then
        ${config.programs.neovim.finalPackage}/bin/nvim --headless \
          "+Hotpot sync context=$NVIM_CONFIG" \
          "+qa" 2>&1 | sed 's/^/[hotpot-sync] /' || true
        echo
      else
        echo "[hotpot-sync] hotpot not bootstrapped yet; skipping"
      fi
    '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      ${if pkgs.stdenv.hostPlatform.isDarwin then ''
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        Include ~/.orbstack/ssh/config
      '' else ""}
    '';
    settings = {
      "alumnae nextcloud alumnae_docker alumnae_old" = {
        User = "ubuntu";
        IdentitiesOnly = true;
      };

      "alumnae" = {
        HostName = "18.118.144.106";
        User = "bitnami";
      };

      "axd" = {
        HostName = "ssh.nyc1.nearlyfreespeech.net";
        User = "caryme_alphaxidelta";
        IdentitiesOnly = true;
      };

      "nextcloud" = { HostName = "18.220.94.108"; };

      "alumnae_docker" = { HostName = "3.129.26.193"; };

      "alumnae_hetzner" = {
        HostName = "alumnae-docker";
        User = "cary";
        IdentitiesOnly = true;
      };

      # 1Password's agent socket only exists on macOS.
      "codeberg.org" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        HostName = "codeberg.org";
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };

      "purple_folder" = {
        HostName = "178.156.160.41";
        User = "ubuntu";
        IdentitiesOnly = true;
      };

      "fip" = {
        HostName = "5.161.230.35";
        User = "cary";
        IdentitiesOnly = true;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/cm-%r@%h:%p";
        ControlPersist = "10m";
      };

      "gringotts" = {
        HostName = "192.168.8.3";
        User = "cary";
        WarnWeakCrypto = "no";
      };

      "*" = {
        ForwardAgent = false;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        AddKeysToAgent = "yes";
        Compression = true;
        HashKnownHosts = true;
      };
    };
  };

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Bootstrap for fast-moving developer tools. The selected tools themselves
    # live in dotfiles/mise/config.toml rather than in the Nix store.
    mise

    ripgrep
    bat
    fd
    jq
    sesh
    just

    ffmpeg

    imagemagick
    dos2unix

    curl
    wget
    unzip
    zip
    perl
    glow

    # Keep the large cloud SDK in Nix for now; it is used across work shells.
    google-cloud-sdk
    ghostscript

    babashka
    # The wrapper prepends its own Zulu JDK 21 to PATH, so `clj` works without a
    # JDK in home.packages. Add temurin-bin-21 separately if you ever want bare
    # `java`/`javac` — /usr/bin/java is only Apple's "install a JRE" stub.
    clojure
    leiningen
    clj-kondo

    # Document & media utilities
    exiftool
    poppler-utils
    qpdf
    typst

    # Network & sync
    rclone
    mosh
    aria2

    # System utilities
    pwgen
    watch
    nmap

    tree
    pdftk

    # Just the families the pandoc/typst presets and reMarkable skill name,
    # instead of all of google-fonts (2.3 GiB).
    inter
    literata
    source-serif
    atkinson-hyperlegible
    # Metric-compatible Calibri stand-in; the board-deck SVGs name Carlito.
    carlito

    pkgs.nerd-fonts.fira-code

    sqlite

    # comby is broken in current nixos-unstable; pull it from a pinned nixpkgs commit.
    (import nixpkgs-comby { inherit system; }).comby

    gws-cli.packages.${system}.default

    (pkgs.callPackage ./pkgs/ferrite.nix { })
  ]
  # Linux only. Rootless podman (configured via ~/.config/containers below):
  # the Mac uses OrbStack.
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.podman
    pkgs.podman-compose
    # Renders the mermaid fences in the pandoc reMarkable preset. Linux only:
    # it wraps nixpkgs chromium, which doesn't exist for macOS, so on the Mac
    # it failed at launch. mermaid.lua leaves the fences as code without it.
    pkgs.mermaid-cli
  ];

  fonts.fontconfig.enable = true;

  # Keep this editable in the repository. `mise install` reads the selected
  # versions but does not rewrite the file; updates are deliberate commits.
  xdg.configFile."mise/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/mise/config.toml";

  home.file = {
    ".config/containers/policy.json" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      text = ''
      {
        "default": [
          {
            "type": "insecureAcceptAnything"
          }
        ]
      }
      '';
    };

    # netavark 2.0's only real firewall driver is nftables, and its ruleset
    # uses an inet-family `fib` expression that the Microsoft WSL2 kernel can
    # never satisfy (CONFIG_NFT_FIB_IPV6 unset -> nft_fib_inet.ko is not
    # built), so every bridge-network container fails with
    # "nft did not return successfully while applying ruleset".
    # The iptables driver was removed in netavark 2.0, leaving "none".
    # That is safe for rootless podman on this box: published ports are
    # forwarded by rootlessport, egress NAT is done by pasta, and
    # container<->container traffic rides the bridge — none of them need
    # netavark's rules. Trade-off: no inter-network isolation between podman
    # networks, and rootful podman would lose egress NAT (we run rootless only).
    # force: this file replaced a hand-written copy of the same content.
    ".config/containers/containers.conf" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      force = true;
      text = ''
        [network]
        firewall_driver = "none"
      '';
    };
  };

  # Weekly: drop home-manager generations (and other profiles of this user)
  # older than 14 days, then collect garbage. Runs as a systemd user timer on
  # Linux and a launchd agent on macOS.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.home-manager.enable = true;
}
