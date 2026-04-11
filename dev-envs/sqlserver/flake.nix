{
  description = "uv + pyodbc Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; 
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; 
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python3
          uv
          openssl
          
          # 1. ADD YOUR DRIVERS HERE
          unixodbc
          unixodbcDrivers.psql
          unixodbcDrivers.sqlite
          unixodbcDrivers.msodbcsql18 # (Uncomment if using Microsoft SQL Server)
        ];

        shellHook = ''
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.unixODBC pkgs.stdenv.cc.cc.lib ]}:$LD_LIBRARY_PATH"
          export UV_PROJECT_ENVIRONMENT=".venv"

          # 2. CREATE A LOCAL ODBC CONFIG DIRECTORY
          mkdir -p .odbc
          
          # 3. WRITE THE DRIVER PATHS TO odbcinst.ini
          # Nix will automatically inject the correct /nix/store/... paths below
          cat > .odbc/odbcinst.ini <<EOF
          [PostgreSQL]
          Description=PostgreSQL driver for Nix
          Driver=${pkgs.unixodbcDrivers.psql}/lib/psqlodbca.so

          [SQLite3]
          Description=SQLite3 driver for Nix
          Driver=${pkgs.unixodbcDrivers.sqlite}/lib/libsqlite3odbc.so
          EOF

          # (Optional: If you are using MS SQL Server, finding the .so is tricky because of version numbers. 
          # You would add this dynamically:)
          echo "[ODBC Driver 18 for SQL Server]" >> .odbc/odbcinst.ini
          echo "Driver=$(find ${pkgs.unixodbcDrivers.msodbcsql18} -name "libmsodbcsql-1*.so*" | head -n 1)" >> .odbc/odbcinst.ini

          # 4. TELL UNIXODBC WHERE TO LOOK FOR THE CONFIG
          export ODBCSYSINI=$PWD/.odbc

          echo "🐍 Python + ⚡ uv + 🗄️ unixODBC environment ready."
        '';
      };
    };
}
