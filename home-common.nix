{ config, pkgs, duckdb-1-5-bin, claude-code, gws-cli, ... }:

{
  home.username = "cary";
  home.homeDirectory = "/home/cary";
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cache/.bun/bin"
  ];
  xdg.enable = true;
  xdg.configFile."nvim".source = ./dotfiles/nvim;
  programs.bun.enable = true;
  programs.uv.enable = true;

  programs.pandoc = {
    enable = true;

    defaults = {
      metadata = {
        author = "Cary Lee";
      };
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
  programs.zoxide.enable = true;
  programs.eza.enable = true;
  programs.starship.enable = true;

  programs.tmux = {
    enable = true;
    clock24 = true;
    terminal = "screen-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      catppuccin
    ];
    extraConfig = ''
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
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        hashKnownHosts = true;
        addKeysToAgent = "yes";
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

    pkgs.nerd-fonts.fira-code

    duckdb-1-5-bin

    gws-cli.packages.${pkgs.system}.default

    claude-code.packages.${pkgs.system}.default
  ];

  home.file = {
    ".config/containers/policy.json".text = ''
    {
      "default": [
        {
	  "type": "insecureAcceptAnything"
	}
      ]
    }
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
