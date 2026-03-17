{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "linear-cli";
  version = "latest"; # You can pin a specific version here if you prefer

  src = pkgs.fetchFromGitHub {
    owner = "schpet";
    repo = "linear-cli";
    rev = "v1.11.1"; # Or a specific tag like "v0.1.0"
    hash = "sha256-os/p8P1ZFqdMFuqci0XtbDpJQP31PDfCtYSX9xFv8D4=";
  };

  nativeBuildInputs = [ pkgs.deno ];

  buildPhase = ''
    # Deno needs a writable HOME for caching during the build
    export HOME=$TMPDIR
  '';

  installPhase = ''
    mkdir -p $out/bin
    # We use deno install to create the executable wrapper
    deno install \
      --root $out \
      --allow-all \
      --name linear \
      ./main.ts
  '';

  meta = with pkgs.lib; {
    description = "A CLI to list, start and create issues in Linear";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
    maintainers = [ ];
  };
}
