{
  description = "Home Manager configuration of cary";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, claude-code, ... }:
    let
      # This helper detects if we are on Mac or Linux
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # We define a function to create the config for a specific system
      mkHomeConfig = system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Platform-specific DuckDB Logic
        duckdb-bin = let
          suffix = if pkgs.stdenv.isDarwin then "osx-arm64.zip" else "linux-amd64.zip";
          hash = if pkgs.stdenv.isDarwin 
                 then "sha256-K8mZpP7VvMvXvXvXvXvXvXvXvXvXvXvXvXvXvXvXvX=" # You will get a hash error; copy the real one from the error message
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

      in home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit duckdb-bin claude-code; };
        modules = [ ./home.nix ];
      };
    in
    {
      # This allows 'nix run home-manager' to work on both machines
      homeConfigurations = {
        "cary" = mkHomeConfig "aarch64-darwin"; # For the Mac
        "cary-linux" = mkHomeConfig "x86_64-linux"; # For WSL
      };
    };
}
