{ config, pkgs, ... }:

{
  programs.git.settings.user = {
    name = "Cary Lee";
    email = "carylee@gmail.com";
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Cary Lee";
        email = "carylee@gmail.com";
      };
    };
  };

  home.packages = with pkgs; [
    isync
    notmuch
    # nixpkgs builds wrangler from source (broken on aarch64-darwin); use the
    # prebuilt npm package instead. See pkgs/wrangler/default.nix.
    (callPackage ./pkgs/wrangler { })
  ];

  programs.zsh.shellAliases = {
    soffice = "/Applications/LibreOffice.app/Contents/MacOS/soffice";
  };
}
