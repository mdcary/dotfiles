{
  description = "System and Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 1. Add nix-darwin as an input
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, claude-code, ... }:
    let
      # Extract your DuckDB derivation into a helper function 
      # so both Linux and Mac configurations can use it easily.
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
    in
    {
      # --- 1. LINUX (WSL) ---
      # Remains a standalone Home Manager configuration
      homeConfigurations."cary-linux" = let
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { 
          duckdb-bin = mkDuckDb pkgs; 
          inherit claude-code; 
          isWork = true; 
        };
        modules = [ ./home.nix ];
      };

      # --- 2. MAC (Darwin) ---
      # Transitions to a system-level configuration that embeds Home Manager
      darwinConfigurations."cary" = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
      in darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # System-level Mac configurations go here
          ({ pkgs, ... }: {
            # Tell nix-darwin to let Determinate Systems manage the Nix daemon
            nix.enable = false;

            # nix.settings.experimental-features = "nix-command flakes";
            programs.zsh.enable = true; # Required for nix-darwin to hook into your shell properly
            system.stateVersion = 5;

            # ---> THIS IS THE BLOCK TO ADD <---
            users.users.cary = {
              name = "cary";
              home = "/Users/cary";
            };

            system.primaryUser = "cary";
            # ----------------------------------

            # Here is your Mac-only Homebrew configuration
            homebrew = {
              enable = true;
              onActivation.autoUpdate = true;
              onActivation.cleanup = "zap";
              taps = [
                "homebrew/cask"
                "homebrew/cask-fonts"
              ];
              casks = [
                "1password"
                "discord"
                "obsidian"
                "tailscale"
                "microsoft-teams"
                "zoom"
                "calibre"
                "1password"
                "1password-cli"
                "orbstack"
                "iterm2"
                "visual-studio-code"
                "audacity"
                "prusaslicer"
                "openscad"
                "raspberry-pi-imager"
                "appcleaner"
                "font-daddy-time-mono-nerd-font"
                "font-inconsolata-nerd-font"
              ];
            };
          })

          # Embed your existing home.nix for the user 'cary'
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { 
              duckdb-bin = mkDuckDb pkgs; 
              inherit claude-code; 
              isWork = false; 
            };
            home-manager.users.cary = import ./home.nix;
          }
        ];
      };
    };
}
