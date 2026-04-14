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
}
