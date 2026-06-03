{ lib, buildNpmPackage, nodejs, makeWrapper }:

# Cloudflare publishes wrangler prebuilt to npm. nixpkgs builds it from source
# via pnpm, which is currently broken on aarch64-darwin (EBADF in the
# tsup/generate-json-schema build step). Install the prebuilt package instead.
#
# To bump the version:
#   1. Edit `version` below and `wrangler` in ./package.json to match.
#   2. Regenerate the lockfile:
#        (cd pkgs/wrangler && rm -f package-lock.json &&
#         npm install --package-lock-only --ignore-scripts)
#   3. Set npmDepsHash to lib.fakeHash, build once, copy the "got:" hash here.

buildNpmPackage rec {
  pname = "wrangler";
  version = "4.97.0";

  src = ./.;

  npmDepsHash = "sha256-x2W9vZ5uZD6yCwz5FXXkGy1P5Q6vvRbZJ3a5DsSFchw=";

  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib/node_modules

    makeWrapper ${nodejs}/bin/node $out/bin/wrangler \
      --add-flags $out/lib/node_modules/wrangler/bin/wrangler.js
    ln -s $out/bin/wrangler $out/bin/wrangler2

    runHook postInstall
  '';

  meta = {
    description = "Cloudflare Workers CLI (prebuilt npm package)";
    homepage = "https://developers.cloudflare.com/workers/wrangler/";
    license = lib.licenses.asl20;
    mainProgram = "wrangler";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
