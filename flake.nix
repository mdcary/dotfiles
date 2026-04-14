{
  description = "Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Add the automated Claude Code flake
    claude-code.url = "github:sadjow/claude-code-nix";
    # Add the Google Workspace CLI flake here
    gws.url = "github:googleworkspace/cli";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, claude-code, gws, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "msodbcsql17"
          ];
        };
      };

      # Add taws here
      taws-bin = pkgs.stdenv.mkDerivation rec {
        pname = "taws";
        version = "1.3.0-rc.7"; # Ensure this matches the current release

        src = pkgs.fetchurl {
          url = "https://github.com/huseyinbabal/taws/releases/download/v${version}/taws-x86_64-unknown-linux-musl.tar.gz";
          # Use a placeholder hash first, then update it with the one Nix complains about
          hash = "sha256-14ahXuOUXHO6B7rSkdnfk0xwHB65WZ3UEly8Nqi1NUA="; 
        };

        # stdenv automatically handles .tar.gz unpacking
        sourceRoot = ".";

        installPhase = ''
          mkdir -p $out/bin
          cp taws $out/bin/
          chmod +x $out/bin/taws
        '';
      };

      # Package the pre-compiled binary instead of compiling from source
      duckdb-1-5-bin = pkgs.stdenv.mkDerivation rec {
        pname = "duckdb-bin";
        version = "1.5.0";

        src = pkgs.fetchurl {
          url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-amd64.zip";
          # You'll need to grab the real hash from the first failed run, just like before!
          hash = "sha256-F5pIHt8EjdH+8PCX1mkztLX1pXN9QDTGReQV7HIsApI=";
        };

        nativeBuildInputs = [ pkgs.unzip ];

        sourceRoot = ".";

        installPhase = ''
          mkdir -p $out/bin
          cp duckdb $out/bin/
          chmod +x $out/bin/duckdb
        '';
      };
    in
    {
      homeConfigurations."cary@work" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit duckdb-1-5-bin claude-code taws-bin;
        };

        modules = [ ./home-common.nix ./home-work.nix ];
      };

      homeConfigurations."cary@home" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          inherit duckdb-1-5-bin claude-code;
        };

        modules = [ ./home-common.nix ./home-personal.nix ];
      };
    };
}
