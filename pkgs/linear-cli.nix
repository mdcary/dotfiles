{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "linear-cli";
  version = "1.11.1";

  src = pkgs.fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
    # This is the EXACT checksum from the official installer script!
    sha256 = "4bbcf0c4e617c1898afb3732ba1baf556f098573c8e6181a5a2c84cfb4f48082";
  };

  # The installer script confirms it uses --strip-components 1
  # This means Nix should look for the binary in the root of the unpacked source.
  sourceRoot = ".";

  # We need to add the unpacker for .tar.xz
  nativeBuildInputs = [ pkgs.xz ];

  installPhase = ''
    mkdir -p $out/bin
    # The installer shows the binary is just named 'linear'
    # We find it and move it to our bin directory
    find . -type f -name "linear" -exec cp {} $out/bin/ \;
    chmod +x $out/bin/linear
  '';

  meta = with pkgs.lib; {
    description = "Linear CLI - list, start, and create issues";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
