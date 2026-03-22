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

      # Define DuckDB 1.5 here
      duckdb-1-5 = pkgs.duckdb.overrideAttrs (oldAttrs: rec {
        version = "1.5.0";
        src = pkgs.fetchFromGitHub {
          owner = "duckdb";
          repo = "duckdb";
          rev = "v${version}";
          hash = "sha256-nTtLs3we5LVV1yBRWqJJDCBVxA+TPKwW+t/5oONUSS4="; 
        };
      });
    in
    {
      homeConfigurations."cary" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass the custom duckdb package into home.nix via 'extraSpecialArgs'
        extraSpecialArgs = { inherit duckdb-1-5; };

        modules = [ ./home.nix ];
      };
    };
}
