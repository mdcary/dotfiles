{ config, pkgs, duckdb-1-5-bin, claude-code, ... }:

let
  # Import our custom package
  linear-cli = pkgs.callPackage ./pkgs/linear-cli.nix { };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cary";
  home.homeDirectory = "/home/cary";
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
  xdg.enable = true;
  xdg.configFile."nvim".source = ./dotfiles/nvim;
  programs.bun.enable = true;
  programs.uv.enable = true;
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Cary Lee";
        email = "clee@mdclarity.com";
      };
    };
  };
  programs.git = {
    enable = true;
  
    settings = {
      user = {
        name = "Cary Lee";
        email = "clee@mdclarity.com";
      };
  
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
  
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
  
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

      # Create command aliases for frequently used operations
      aliases = {
        co = "pr checkout";        # Alias: `gh co` → `gh pr checkout`
        pv = "pr view";            # Alias: `gh pv` → `gh pr view`
        ic = "issue create";       # Alias: `gh ic` → `gh issue create`
        iv = "issue view";         # Alias: `gh iv` → `gh issue view`
      };

      # Set your preferred editor for creating issues/PRs
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
      # disable up-arrow binding
      keymap_mode = "vim-normal"; # optional if you use vim mode
      search_mode = "fuzzy";
      inline_height = 20;

      # important one:
      ctrl_n_shortcuts = false;
    };
  };

  programs.mr = {
    enable = true;

    settings = {
      "src/mdc/Infrastructure" = {
        checkout = "git clone git@github.com:MdClarity/Infrastructure.git Infrastructure";
      };
        
      "src/mdc/MdClarity" = {
        checkout = "git clone git@github.com:MdClarity/MdClarity.git MdClarity";
      };

      "src/mdc/payer-monitor" = {
        checkout = "git clone git@github.com:MdClarity/contract-manager.git payer-monitor";
      };

      "src/mdc/server-scripts" = {
        checkout = "git clone git@github.com:MdClarity/server-scripts.git";
      };

      "src/mdc/external-system-interfaces" = {
        checkout = "git clone git@github.com:MdClarity/external-system-interfaces.git";
      };
    };
  };

  programs.awscli = {
    enable = true;
  
    settings = {
      "profile dev-admin" = {
        sso_session = "dev";
        sso_account_id = "367268567544";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
        default = true;
      };
  
      "profile prod-admin" = {
        sso_session = "dev";
        sso_account_id = "096002140659";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };
  
      "profile bedrock" = {
        sso_session = "dev";
        sso_account_id = "367268567544";
        sso_role_name = "llm-tool-access";
        region = "us-east-2";
      };
  
      "profile billing" = {
        sso_session = "dev";
        sso_account_id = "637217033209";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };
  
      "profile devops" = {
        sso_session = "dev";
        sso_account_id = "789261558096";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };
  
      "profile tools" = {
        sso_session = "dev";
        sso_account_id = "616967731364";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };
  
      "sso-session dev" = {
        sso_start_url = "https://mdclarity.awsapps.com/start/#";
        sso_region = "us-west-2";
        sso_registration_scopes = "sso:account:access";
      };
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
      docker = "podman";
      yolo = "claude --dangerously-skip-permissions";
    };

    initContent = ''
      export EDITOR=nvim
      if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
        exec tmux new-session -A -s main
      fi

      setopt NO_BEEP

      mktree() {
        local repo=$1
        local branch_id=$2

        # Check if both arguments were provided
        if [[ -z "$repo" || -z "$branch_id" ]]; then
          echo "Usage: mktree <repo> <branch-identifier>"
          return 1
        fi

        local src_dir="$HOME/src/mdc/$repo"
        local branch_name="cary/$branch_id"
        local tree_dir="$HOME/trees/$repo/$branch_id"

        # 1. Verify the source repository exists
        if [[ ! -d "$src_dir" ]]; then
          echo "Error: Base repository '$src_dir' does not exist."
          return 1
        fi

        # 2. Navigate to the base repo
        cd "$src_dir" || return 1

        # 3. Ensure the parent trees directory exists
        mkdir -p "$HOME/trees/$repo"

        # 4. Attempt to create worktree from an existing branch. 
        # If it fails (branch doesn't exist), create a new branch.
        echo "Setting up worktree for '$branch_name'..."
        if ! git worktree add "$tree_dir" "$branch_name" 2>/dev/null; then
          echo "Branch not found locally/remotely. Creating new branch..."
          git worktree add -b "$branch_name" "$tree_dir"
        fi

        # 5. Navigate directly into the new worktree
        cd "$tree_dir" || return 1
        echo "✅ Success! You are now in: $PWD"
      }
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
      set -g status-position top # 2026 trend: status bar at the top
      set -g @catppuccin_flavor 'mocha'

      set -g history-limit 100000
      set -g @continuum-restore 'on'
      set -g @resurrect-strategy-nvim 'session' #
      set -g @continuum-save-interval '15'

      # --- Modern Session Management ---
      # Quick session switching (replaces manual prefix+s)
      bind S display-popup -E "sesh connect \$(sesh list | fzf)" #

      # --- Reload Configuration ---
      # Press Prefix + r to reload the tmux config and display a message
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # --- Vi-Mode Copying (The "Vim-ify" block) ---
      set-window-option -g mode-keys vi # Use Vim keys in copy mode

      # --- Floating Scratchpad ---
      # Prefix + g toggles a centered floating terminal popup
      bind g display-popup -d "#{pane_current_path}" -w 80% -h 80% -E "zsh"

      # --- Floating Linear Dashboard (Bonus) ---
      # If you want a dedicated popup just for your Linear issues:
      bind i display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "linear issue list --team MDC --sort manual --cycle active -A && read"

      # Keybindings to make copying feel like Neovim
      bind-key -T copy-mode-vi 'v' send -X begin-selection     # 'v' to begin selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel # 'y' to yank
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle  # 'Ctrl-v' for block visual mode

      # Don't exit copy mode when dragging with the mouse
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # --- Smart Splits (Navigation & Resizing) ---
      # '@pane-is-vim' is a pane-local option set natively by smart-splits.nvim
      
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
    # sensible baseline; adjust as desired
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        hashKnownHosts = true;
        addKeysToAgent = "yes";
      };
    };
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    hello
    ripgrep
    bat
    fd
    jq
    sesh

    ffmpeg

    linear-cli

    podman
    podman-compose

    curl
    wget
    unzip
    zip
    perl

    duckdb-1-5-bin

    claude-code.packages.${pkgs.system}.default

    wslu

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".config/containers/policy.json".text = ''
    {
      "default": [
        {
	  "type": "insecureAcceptAnything"
	}
      ]
    }
    '';

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cary/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
