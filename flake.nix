{
  description = "System and Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
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

  outputs = { self, nixpkgs, home-manager, darwin, claude-code, gws-cli, ... }:
    let
      mkDuckDb = pkgs: let
        suffix = if pkgs.stdenv.isDarwin then "osx-arm64.zip" else "linux-amd64.zip";
        hash = if pkgs.stdenv.isDarwin
               then "sha256-7itTKqSg1LrPp38gSUW/ykRJ/2FW46zFenXcXTxsvz8="
               else "sha256-F5pIHt8EjdH+8PCX1mkztLX1pXN9QDTGReQV7HIsApI=";
      in pkgs.stdenv.mkDerivation rec {
        pname = "duckdb-bin";
        version = "1.5.0";
        src = pkgs.fetchurl {
          url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-${suffix}";
          inherit hash;
        };
        nativeBuildInputs = [ pkgs.unzip ];
        sourceRoot = ".";
        installPhase = "mkdir -p $out/bin && cp duckdb $out/bin/ && chmod +x $out/bin/duckdb";
      };

      mkTaws = pkgs: pkgs.stdenv.mkDerivation rec {
        pname = "taws";
        version = "1.3.0-rc.7";
        src = pkgs.fetchurl {
          url = "https://github.com/huseyinbabal/taws/releases/download/v${version}/taws-x86_64-unknown-linux-musl.tar.gz";
          hash = "sha256-14ahXuOUXHO6B7rSkdnfk0xwHB65WZ3UEly8Nqi1NUA=";
        };
        sourceRoot = ".";
        installPhase = ''
          mkdir -p $out/bin
          cp taws $out/bin/
          chmod +x $out/bin/taws
        '';
      };
    in
    {
      # --- Linux (WSL) - Work ---
      homeConfigurations."cary@work" = let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          duckdb-bin = mkDuckDb pkgs;
          taws-bin = mkTaws pkgs;
          inherit claude-code gws-cli;
        };
        modules = [ ./home-common.nix ./home-work.nix ];
      };

      # --- Linux - Personal ---
      homeConfigurations."cary@home" = let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          duckdb-bin = mkDuckDb pkgs;
          inherit claude-code gws-cli;
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
              brews = [
                "yt-dlp"
              ];
              casks = [
                "1password"
                "1password-cli"
                "discord"
                "obsidian"
                "tailscale-app"
                "microsoft-teams"
                "zoom"
                "calibre"
                "orbstack"
                "iterm2"
                "visual-studio-code"
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
              duckdb-bin = mkDuckDb pkgs;
              inherit claude-code gws-cli;
            };
            home-manager.users.cary = { imports = [ ./home-common.nix ./home-personal.nix ]; };
          }
        ];
      };
    };
}
