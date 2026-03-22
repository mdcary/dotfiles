{
  description = "Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
          ];
        };
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
      homeConfigurations."cary" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass the custom duckdb package into home.nix via 'extraSpecialArgs'
        extraSpecialArgs = { inherit duckdb-1-5-bin; };

        modules = [ ./home.nix ];
      };
    };
}
