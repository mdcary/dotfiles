# dotfiles

Declarative system and dotfile configuration using [Nix](https://nixos.org/), [Home Manager](https://github.com/nix-community/home-manager), and [nix-darwin](https://github.com/LnL7/nix-darwin).

Configuration is split into modular files that are composed per-machine:

- **`home-common.nix`** -- shared config (neovim, tmux, zsh, git base, SSH hosts, packages)
- **`home-work.nix`** -- work-specific (WSL aliases, awscli, ODBC, MdClarity repos, git work identity)
- **`home-personal.nix`** -- personal (git personal identity)

The `flake.nix` defines three entry points:

- **`homeConfigurations."cary@work"`** -- standalone Home Manager for WSL2 (work)
- **`homeConfigurations."cary@home"`** -- standalone Home Manager for Linux (personal)
- **`darwinConfigurations."cary"`** -- nix-darwin system config with Home Manager embedded, also managing Homebrew casks

## Prerequisites

Install Nix via [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (handles flakes and the daemon automatically):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Setup

Clone this repo to `~/.config/home-manager`:

```sh
git clone https://github.com/mdcary/dotfiles.git ~/.config/home-manager
```

### macOS

Install nix-darwin (first time only):

```sh
nix run nix-darwin -- switch --flake ~/.config/home-manager#cary
```

After the first run, apply changes with:

```sh
darwin-rebuild switch --flake ~/.config/home-manager#cary
```

This manages:
- All Nix packages and dotfiles from `home-common.nix` + `home-personal.nix`
- Homebrew casks (1Password, VS Code, Discord, etc.) -- unmanaged casks are removed on activation via `zap`
- System-level settings (shell, Nix daemon delegation)

### Windows / WSL2

From inside your WSL2 distribution:

```sh
home-manager switch --flake ~/.config/home-manager#cary@work
```

This manages:
- All shared config from `home-common.nix`
- Work-specific: awscli SSO profiles, MdClarity repos, ODBC drivers, WSL aliases
- Linux-only extras: podman, podman-compose, wslu

### Linux (Personal)

```sh
home-manager switch --flake ~/.config/home-manager#cary@home
```

## Adding configuration

- **Shared across all machines** -- edit `home-common.nix`
- **Work-only** (WSL, MdClarity tools, AWS) -- edit `home-work.nix`
- **Personal-only** -- edit `home-personal.nix`
- **macOS system/Homebrew** -- edit the `darwinConfigurations` block in `flake.nix`

Home Manager's module system merges attributes from all imported modules, so you can set `programs.zsh.shellAliases` in both common and work modules and they'll combine.

## Custom packages

Packages not in nixpkgs are defined in `flake.nix` (e.g. `mkDuckDb`, `mkTaws`) or in `pkgs/` (e.g. `linear-cli`) and passed to modules via `extraSpecialArgs`.

## Updating

```sh
# Update all flake inputs (nixpkgs, home-manager, nix-darwin, etc.)
nix flake update

# Update a single input
nix flake update claude-code

# Then re-apply
darwin-rebuild switch --flake ~/.config/home-manager#cary        # macOS
home-manager switch --flake ~/.config/home-manager#cary@work     # WSL2
home-manager switch --flake ~/.config/home-manager#cary@home     # Linux personal
```
