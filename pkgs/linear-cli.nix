{ pkgs, ... }:

# We create a wrapper that mimics the installer's result 
# but uses the source code to avoid the binary corruption.
pkgs.writeShellScriptBin "linear" ''
  # We use the Deno from your Nix store
  # We point it directly at the main entry point of the tool
  exec ${pkgs.deno}/bin/deno run \
    --allow-all \
    --no-check \
    https://raw.githubusercontent.com/schpet/linear-cli/main/main.ts "$@"
''
