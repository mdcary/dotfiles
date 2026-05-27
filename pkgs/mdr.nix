{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, xdotool
, webkitgtk_4_1
, gtk3
, libsoup_3
, glib
, cairo
, gdk-pixbuf
, dbus
, stdenv
}:

# Prebuilt binary distribution of CleverCloud/mdr. Upstream's flake fails to
# evaluate against current nixpkgs (`libxdo` was renamed) and ships no
# Cargo.lock, so source builds are also broken. The release tarballs contain
# a single `mdr` binary, which we install directly and patch on Linux.
let
  version = "0.3.0";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/CleverCloud/mdr/releases/download/v${version}/mdr-aarch64-apple-darwin.tar.gz";
      hash = "sha256-8qNbKqXnA6IqgsOceysD4kIAV8a4LyVjI0ALnAx8f/I=";
    };

    x86_64-darwin = {
      url = "https://github.com/CleverCloud/mdr/releases/download/v${version}/mdr-x86_64-apple-darwin.tar.gz";
      hash = "sha256-/YxjljuYfOFI4nD8/r/x9XRcwAymf8iL57BHuENkZu0=";
    };

    x86_64-linux = {
      url = "https://github.com/CleverCloud/mdr/releases/download/v${version}/mdr-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-TicoEujyjybzR3+lnlZN1sfsBgPlmkiAF2Fxsd/LZZY=";
    };
  };

  srcInfo =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "mdr: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "mdr";
  inherit version;

  src = fetchurl { inherit (srcInfo) url hash; };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.isLinux [
    xdotool
    webkitgtk_4_1
    gtk3
    libsoup_3
    glib
    cairo
    gdk-pixbuf
    dbus
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 mdr $out/bin/mdr
    runHook postInstall
  '';

  meta = with lib; {
    description = "A lightweight Markdown viewer with Mermaid diagram support";
    homepage = "https://github.com/CleverCloud/mdr";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "mdr";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
