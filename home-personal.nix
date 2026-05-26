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
  ];

  programs.zsh.shellAliases = {
    soffice = "/Applications/LibreOffice.app/Contents/MacOS/soffice";
  };
}
