# dotfiles

Declarative system and dotfile configuration using [Nix](https://nixos.org/), [Home Manager](https://github.com/nix-community/home-manager), and [nix-darwin](https://github.com/LnL7/nix-darwin).

A single `home.nix` is shared across platforms, with conditional logic for platform-specific packages, paths, and settings. The `flake.nix` defines two entry points:

- **`homeConfigurations."cary-linux"`** — standalone Home Manager for WSL2
- **`darwinConfigurations."cary"`** — nix-darwin system config with Home Manager embedded, also managing Homebrew casks

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
- All Nix packages and dotfiles from `home.nix`
- Homebrew casks (1Password, VS Code, Discord, etc.) — unmanaged casks are removed on activation via `zap`
- System-level settings (shell, Nix daemon delegation)

### Windows / WSL2

From inside your WSL2 distribution:

```sh
home-manager switch --flake ~/.config/home-manager#cary-linux
```

This manages:
- All Nix packages and dotfiles from `home.nix`
- Linux-only extras: podman, podman-compose, wslu
- Container policy config for rootless podman

## What's included

### Shell & terminal
- **zsh** with syntax highlighting, completions, and autocd
- **tmux** with catppuccin theme, vim-style copy mode, sesh session management, and auto-restore via continuum
- **starship** prompt
- **fzf**, **zoxide**, **eza**, **atuin** (shell history)
- **neovim** as default editor (config synced from `dotfiles/nvim/`)

### Dev tools
- git (with delta, lazygit, gh, conditional work/personal email)
- jujutsu
- Node.js, bun, uv (Python)
- direnv + nix-direnv
- AWS CLI (with SSO profiles)
- Claude Code

### CLI utilities
ripgrep, bat, fd, jq, curl, wget, ffmpeg, duckdb, pandoc, exiftool, imagemagick, rclone, mosh, nmap, pwgen, and more.

## Updating

```sh
# Update flake inputs (nixpkgs, home-manager, nix-darwin, etc.)
nix flake update

# Then re-apply
darwin-rebuild switch --flake ~/.config/home-manager#cary        # macOS
home-manager switch --flake ~/.config/home-manager#cary-linux    # WSL2
```
