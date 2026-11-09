{ stdenv, fetchurl }:

# huseyinbabal/taws: a terminal UI for AWS. Prebuilt static (musl) release
# binary; x86_64-linux only, matching the one machine that installs it.
stdenv.mkDerivation rec {
  pname = "taws";
  version = "1.3.0-rc.7";
  src = fetchurl {
    url = "https://github.com/huseyinbabal/taws/releases/download/v${version}/taws-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-14ahXuOUXHO6B7rSkdnfk0xwHB65WZ3UEly8Nqi1NUA=";
  };
  sourceRoot = ".";
  installPhase = ''
    mkdir -p $out/bin
    cp taws $out/bin/
    chmod +x $out/bin/taws
  '';
}
