{
  description = "System and Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # comby is broken in current nixos-unstable; pin to the last known-good commit.
    nixpkgs-comby.url = "github:NixOS/nixpkgs/a421ac6595024edcfbb1ef950a3712b89161c359";
    gws-cli.url = "github:googleworkspace/cli";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-comby, home-manager, darwin, gws-cli, ... }:
    {
      # --- Linux (WSL) - Work ---
      homeConfigurations."cary@work" = let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit nixpkgs-comby gws-cli;
        };
        modules = [ ./home-common.nix ./home-work.nix ];
      };

      # --- Linux - Personal ---
      homeConfigurations."cary@home" = let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit nixpkgs-comby gws-cli;
        };
        modules = [ ./home-common.nix ./home-personal.nix ];
      };

      # --- macOS (Darwin) ---
      darwinConfigurations."cary" = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
      in darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ({ pkgs, ... }: {
            nix.enable = false;
            nixpkgs.config.allowUnfree = true;
            programs.zsh.enable = true;
            system.stateVersion = 5;

            users.users.cary = {
              name = "cary";
              home = "/Users/cary";
            };
            system.primaryUser = "cary";

            homebrew = {
              enable = true;
              onActivation.autoUpdate = true;
              onActivation.cleanup = "zap";
              # Newer Homebrew refuses `brew bundle --cleanup` without a force
              # flag; pass it explicitly so non-interactive activation works.
              onActivation.extraFlags = [ "--force-cleanup" ];
              casks = [
                "musescore"
                "1password"
                "gimp"
                "libreoffice"
                "font-raleway"
                "1password-cli"
                "macfuse"
                "discord"
                "obsidian"
                "tailscale-app"
                "microsoft-teams"
                "zoom"
                "calibre"
                "orbstack"
                "iterm2"
                "visual-studio-code"
                "blender"
                "audacity"
                "adobe-digital-editions"
                "prusaslicer"
                "openscad"
                "raspberry-pi-imager"
                "appcleaner"
                "font-daddy-time-mono-nerd-font"
                "font-inconsolata-nerd-font"
                "claude"
                "vuescan"
                "google-chrome"
                "vlc"
                "firefox"
                "handbrake-app"
                "google-drive"
                "naps2"
                "steam"
                "macwhisper"
                "spotify"
              ];
            };
          })

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit nixpkgs-comby gws-cli;
            };
            home-manager.users.cary = { imports = [ ./home-common.nix ./home-personal.nix ]; };
          }
        ];
      };
    };
}
