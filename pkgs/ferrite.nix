{ lib
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, makeWrapper
, fontconfig
, zlib
, libxkbcommon
, wayland
, vulkan-loader
, libGL
, xorg
, stdenv
}:

# Prebuilt binary distribution of OlaProeis/Ferrite. The upstream flake
# requires fetching crates from crates.io, which currently rejects nix's
# fetchurl User-Agent with HTTP 403 — so source builds fail in our setup.
# Release tarballs contain the binary directly, which we install and (on
# Linux) patch + wrap so the egui/winit runtime can dlopen graphics libs.
let
  version = "0.3.0";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/OlaProeis/Ferrite/releases/download/v${version}/ferrite-macos-arm64.tar.gz";
      hash = "sha256-rXZHZnhwa/0ExNh03qf0BE3Z7OeEI0Rxfgk6oLuBK8Y=";
    };

    x86_64-darwin = {
      url = "https://github.com/OlaProeis/Ferrite/releases/download/v${version}/ferrite-macos-x64.tar.gz";
      hash = "sha256-PyTYZ8+1wUeLyE6buhRPK9dQdSixu3QyPO7M5T8+v6E=";
    };

    x86_64-linux = {
      url = "https://github.com/OlaProeis/Ferrite/releases/download/v${version}/ferrite-linux-x64.tar.gz";
      hash = "sha256-M4sgG/Bxco3bCLdGYAglfo4+cyXHF1hsv+XMXtzGPtg=";
    };
  };

  srcInfo =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "ferrite: unsupported system ${stdenvNoCC.hostPlatform.system}");

  # Libraries the egui/winit runtime dlopen()s rather than linking against,
  # so autoPatchelfHook can't discover them — we inject via LD_LIBRARY_PATH.
  runtimeLibs = [
    vulkan-loader
    libGL
    libxkbcommon
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libxcb
  ];
in
stdenvNoCC.mkDerivation {
  pname = "ferrite";
  inherit version;

  src = fetchurl { inherit (srcInfo) url hash; };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook makeWrapper ];

  buildInputs = lib.optionals stdenv.isLinux [ fontconfig zlib stdenv.cc.cc.lib ];

  dontConfigure = true;
  dontBuild = true;

  installPhase =
    if stdenv.isLinux then ''
      runHook preInstall
      install -Dm755 ferrite $out/bin/ferrite
      runHook postInstall
    '' else ''
      runHook preInstall
      mkdir -p $out/Applications $out/bin
      cp -r Ferrite.app $out/Applications/
      ln -s $out/Applications/Ferrite.app/Contents/MacOS/ferrite $out/bin/ferrite
      runHook postInstall
    '';

  postFixup = lib.optionalString stdenv.isLinux ''
    wrapProgram $out/bin/ferrite \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
  '';

  meta = with lib; {
    description = "A fast, lightweight text editor for Markdown, JSON, YAML, and TOML files";
    homepage = "https://github.com/OlaProeis/Ferrite";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "ferrite";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
