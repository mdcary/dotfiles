{ config, pkgs, ... }:

{
  programs.git.settings.user = {
    name = "Cary Lee";
    email = "carylee@gmail.com";
  };
}
