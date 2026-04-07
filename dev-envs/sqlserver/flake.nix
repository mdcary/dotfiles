{
  description = "uv + pyodbc Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Standard for WSL Ubuntu
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Often required if you use Microsoft SQL drivers later
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python3
          uv
          unixODBC
          
          # Uncomment your specific driver below if needed:
          unixODBCDrivers.msodbcsql17  # Microsoft SQL Server
          # unixODBCDrivers.psql         # PostgreSQL
          # unixODBCDrivers.sqlite3      # SQLite
        ];

        # Set environment variables to help uv and pyodbc find the underlying C libraries
        shellHook = ''
          # 1. Allow the pre-compiled pyodbc wheel to find libodbc.so at runtime
          # 2. Include stdenv.cc.cc.lib to prevent libstdc++ errors from standard PyPI wheels
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.unixODBC pkgs.stdenv.cc.cc.lib ]}:$LD_LIBRARY_PATH"

          # Optional: Tell uv where to put the virtual environment locally
          #export UV_PROJECT_ENVIRONMENT=".venv"

          echo "🐍 Python + ⚡ uv + 🗄️ unixODBC environment ready."
        '';
      };
    };
}
