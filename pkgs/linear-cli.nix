{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "linear-cli";
  version = "1.11.1";

  src = pkgs.fetchurl {
    # Changed extension to .tar.xz
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
    sha256 = "sha256-S7zwxOYXwYmK+zcyuhuvVW8JhXPI5hgaWiyEz7T0gII";
  };

  # Direct Nix to look in the current directory after unpacking
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp linear $out/bin/
    chmod +x $out/bin/linear
  '';

  meta = with pkgs.lib; {
    description = "Linear CLI - list, start, and create issues";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.isc;
    platforms = [ "x86_64-linux" ];
  };
}
