{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "linear-cli";
  version = "1.11.1"; # Current version as of early 2026

  src = pkgs.fetchurl {
    # Note: Using the x86_64-linux binary. 
    # If you are on ARM (Apple Silicon via WSL/VM), use 'aarch64-unknown-linux-gnu'
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
  };

  # This source is a tarball, so Nix will unpack it automatically.
  # We just need to move the binary to the right place.
  setSourceRoot = "sourceRoot = \".\";";

  installPhase = ''
    mkdir -p $out/bin
    cp linear $out/bin/
    chmod +x $out/bin/linear
  '';

  meta = with pkgs.lib; {
    description = "A CLI to list, start and create issues in Linear";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
  };
}
