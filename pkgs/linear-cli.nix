{ lib
, stdenvNoCC
, fetchurl
}:

let
  version = "1.11.1";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-aarch64-apple-darwin.tar.xz";
      sha256 = "bfdd3a0d727762018b5fdc2743ac9937fd708b0b3df70c73dad6acd627447694";
    };

    x86_64-darwin = {
      url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-apple-darwin.tar.xz";
      sha256 = "7bcc1554fa562f04d415cfd0af9e067ffc3b32c902128bec44b54487ad6dd509";
    };

    aarch64-linux = {
      url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-aarch64-unknown-linux-gnu.tar.xz";
      sha256 = "2e3554742be571cf3e9aa7d2a4807a2fcbbea063d6bbc056c7e541d201e0e192";
    };

    x86_64-linux = {
      url = "https://github.com/schpet/linear-cli/releases/download/v${version}/linear-x86_64-unknown-linux-gnu.tar.xz";
      sha256 = "4bbcf0c4e617c1898afb3732ba1baf556f098573c8e6181a5a2c84cfb4f48082";
    };
  };

  srcInfo =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "linear-cli: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "linear-cli";
  inherit version;

  src = fetchurl {
    inherit (srcInfo) url sha256;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 linear $out/bin/linear

    mkdir -p $out/share/doc/linear-cli
    for f in README.* readme.* LICENSE LICENSE.* CHANGELOG.*; do
      if [ -e "$f" ]; then
        install -m644 "$f" $out/share/doc/linear-cli/
      fi
    done

    mkdir -p $out/share/linear-cli
    for f in *; do
      if [ "$f" != "linear" ] && [ ! -d "$f" ] &&
         [ "$f" != "README.md" ] && [ "$f" != "LICENSE" ]; then
        cp -r "$f" $out/share/linear-cli/ 2>/dev/null || true
      fi
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI for linear.app with git- and directory-aware issue workflows";
    homepage = "https://github.com/schpet/linear-cli";
    license = licenses.mit;
    platforms = platforms.darwin ++ platforms.linux;
    mainProgram = "linear";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
