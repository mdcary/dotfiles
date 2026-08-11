{ config, pkgs, lib, nixpkgs-comby, claude-code, codex-cli, gws-cli, llm-agents, ... }:

let
  # `pkgs.system` is deprecated; use the stdenv platform string.
  system = pkgs.stdenv.hostPlatform.system;

  repoDir = "${config.home.homeDirectory}/.config/home-manager";
in
{
  home.username = "cary";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/cary" else "/home/cary";
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cache/.bun/bin"
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
    # Layered on top for long-form reading: `-d remarkable -d remarkable-article`.
    "pandoc/defaults/remarkable-article.yaml".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/remarkable-article.yaml";
    "pandoc/filters/mermaid.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/mermaid.lua";
    "pandoc/filters/figure-appendix.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/pandoc/figure-appendix.lua";
  };

  programs.bun.enable = true;
  programs.lazyworktree.enable = true;
  programs.lazysql.enable = true;
  programs.uv.enable = true;
  programs.codex.enable = true;
  programs.codex.package = codex-cli.packages.${system}.default;

  programs.pandoc = {
    enable = true;

    defaults = {
      pdf-engine = "xelatex";
      variables = {
        mainfont = "DejaVu Serif";
        sansfont = "DejaVu Sans";
        monofont = "FiraCode Nerd Font";
        fontsize = "11pt";

        geometry = [
          "margin=1in"
          "heightrounded"
        ];

        colorlinks = true;
        linkcolor = "blue";
        urlcolor = "blue";

        numbersections = true;
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
      docker = "podman";
      vim = "nvim";
      vi = "nvim";
      yolo = "claude --dangerously-skip-permissions";
    };

    initContent = ''
      export EDITOR=nvim

      # Only auto-attach if we are NOT already in tmux and it's an interactive shell
      if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
        # If we explicitly set TMUX_SESSION, use that, otherwise default to "main"
        SESSION_NAME=''${TMUX_SESSION:-main}
        exec tmux new-session -A -s "$SESSION_NAME"
      fi

      setopt NO_BEEP
    '';
  };

  programs.fzf.enable = true;
  programs.antigravity-cli.enable = true; # Changed from programs.gemini-cli.enable
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
      dotnet-sdk

      # Formatters
      stylua
      fnlfmt
      csharpier
      ruff
      prettierd
      shfmt
    ];
  };

  # Recompile fennel config after each rebuild. The .fnl sources live in
  # /nix/store with mtime=epoch-0, so hotpot's mtime-based sync would
  # never notice a change without an explicit `force`.
  home.activation.hotpotSync =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      HOTPOT_DIR="$HOME/.local/share/nvim/lazy/hotpot.nvim"
      NVIM_CONFIG="$HOME/.config/nvim"
      if [ -d "$HOTPOT_DIR" ] && [ -e "$NVIM_CONFIG/init.lua" ]; then
        ${config.programs.neovim.finalPackage}/bin/nvim --headless \
          "+Hotpot sync force context=$NVIM_CONFIG" \
          "+qa" 2>&1 | sed 's/^/[hotpot-sync] /' || true
      else
        echo "[hotpot-sync] hotpot not bootstrapped yet; skipping"
      fi
    '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      ${if pkgs.stdenv.isDarwin then ''
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

      "codeberg.org" = {
        HostName = "codeberg.org";
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };

      "purple_folder" = {
        HostName = "178.156.160.41";
        User = "ubuntu";
        IdentitiesOnly = true;
      };

      "flourish" = {
        HostName = "ssh.nyc1.nearlyfreespeech.net";
        User = "caryme_flourishinplace";
      };

      "fip" = {
        HostName = "5.161.230.35";
        User = "cary";
        IdentitiesOnly = true;
      };

      "gringotts" = {
        HostName = "192.168.8.3";
        User = "cary";
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
    hello
    ripgrep
    bat
    fd
    jq
    sesh
    just
    podman
    podman-compose
    sl
    cloudflared

    nodejs

    texlive.combined.scheme-small

    ffmpeg

    imagemagick
    dos2unix

    curl
    wget
    unzip
    zip
    perl

    google-cloud-sdk
    ghostscript

    babashka
    deno

    # Document & media utilities
    exiftool
    poppler-utils
    qpdf
    typst
    # Renders the mermaid fences in the pandoc reMarkable preset. Ships its own
    # wrapped chromium, so the filter's chromium probe stays dormant.
    mermaid-cli

    # Network & sync
    rclone
    mosh
    aria2

    # System utilities
    pwgen
    watch
    diskus
    nmap

    tree
    pdftk

    google-fonts

    pkgs.nerd-fonts.fira-code

    duckdb
    sqlite

    # comby is broken in current nixos-unstable; pull it from a pinned nixpkgs commit.
    (import nixpkgs-comby { inherit system; }).comby

    gws-cli.packages.${system}.default

    claude-code.packages.${system}.default

    (pkgs.callPackage ./pkgs/ferrite.nix { })

    # simonw's "executable document" demo tool — a Go binary, pulled prebuilt
    # from numtide/llm-agents.nix (cache.numtide.com) rather than rebuilt here.
    llm-agents.packages.${system}.showboat

    # simonw/rodney: Chrome automation CLI. Not in llm-agents.nix, so built
    # from source here and wrapped to use nixpkgs chromium at runtime.
    (pkgs.callPackage ./pkgs/rodney.nix { })
  ];

  fonts.fontconfig.enable = true;

  home.file = {
    ".config/containers/policy.json" = lib.mkIf pkgs.stdenv.isLinux {
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
    ".config/containers/containers.conf" = lib.mkIf pkgs.stdenv.isLinux {
      force = true;
      text = ''
        [network]
        firewall_driver = "none"
      '';
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
