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

    # DDEV local-dev for the church WordPress mirror (~/src/church/website).
    # Docker provider = OrbStack (declared as a cask in flake.nix); it supplies
    # docker + docker-compose, so these two are the only nix pieces DDEV needs.
    ddev
    mkcert
  ];

  # OrbStack's docker / orb / docker-compose (DDEV provider). Merges with the
  # sessionPath in home-common.nix.
  home.sessionPath = [
    "$HOME/.orbstack/bin"
  ];

  programs.zsh.shellAliases = {
    soffice = "/Applications/LibreOffice.app/Contents/MacOS/soffice";
  };

  programs.ssh.settings = {
    "firstchurch" = {
      HostName = "192.185.243.28";
      User = "seattle1";
      ControlMaster = "auto";
      ControlPath = "~/.ssh/cm-%r@%h:%p";
      ControlPersist = "10m";
      # Use a plain key file instead of the 1Password SSH agent.
      IdentityFile = "~/src/church/church.pem";
      IdentitiesOnly = true;
      IdentityAgent = "none";
    };
  };
}
