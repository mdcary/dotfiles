{ lib
, buildGoModule
, fetchFromGitHub
, makeWrapper
, chromium
}:

# simonw/rodney: "Chrome automation from the command line." A Go CLI that
# drives a persistent headless Chrome instance via go-rod/rod, keeping one
# Chrome process alive across multiple invocations.
#
# Not packaged in numtide/llm-agents.nix (which only carries showboat), so we
# build it from source here. rodney shells out to a Chrome/Chromium binary at
# runtime; we pin nixpkgs `chromium` via ROD_CHROME_BIN so it works without a
# system browser installed.
buildGoModule rec {
  pname = "rodney";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "rodney";
    rev = "v${version}";
    hash = "sha256-/iGsaMfK8zeUkTXwU63mAAb4VpsllG87EH8ycoFZs5k=";
  };

  vendorHash = "sha256-h4U43W3hLoF+p25/jNRaW8okeEzAZQEmKtwB5l4kGW4=";

  nativeBuildInputs = [ makeWrapper ];

  # rodney's tests launch a real Chrome and hit the network; skip them.
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/rodney \
      --set ROD_CHROME_BIN ${lib.getExe chromium}
  '';

  meta = with lib; {
    description = "Chrome automation from the command line";
    homepage = "https://github.com/simonw/rodney";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "rodney";
  };
}
