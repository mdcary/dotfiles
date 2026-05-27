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

macOS is **personal-only** -- there is no `@work` / `@home` selector. `darwinConfigurations."cary"` is hardcoded to import `home-common.nix` + `home-personal.nix` (see `flake.nix`), so the same command applies regardless of context.

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

## Adding a neovim plugin

Neovim is bootstrapped from `dotfiles/nvim/init.lua`, which clones [hotpot.nvim](https://github.com/rktjmp/hotpot.nvim) (Fennel compiler) and [lazy.nvim](https://github.com/folke/lazy.nvim), then hands off to `dotfiles/nvim/fnl/config.fnl`. All plugin specs live in that one Fennel file.

1. **Add a lazy.nvim spec** to the `plugins` table in `dotfiles/nvim/fnl/config.fnl`. Fennel translates lazy's Lua spec straight across -- the plugin name (lazy's positional `[1]`) becomes `1`, and keyword keys are written `:opts`, `:dependencies`, `:keys`, `:config`, etc. For example:

   ```fennel
   {1 :folke/todo-comments.nvim
    :dependencies [:nvim-lua/plenary.nvim]
    :opts {}}
   ```

2. **Add any external binaries** the plugin needs (formatters, LSP servers, build tools) to `programs.neovim.extraPackages` in `home-common.nix`. Mason can install LSPs too, but pinning them here keeps them reproducible.

3. **Apply the config** -- `home-manager switch ...` (or `darwin-rebuild switch ...`). The `home.activation.hotpotSync` hook in `home-common.nix` recompiles the Fennel against the new store path so changes pick up immediately.

4. **Install the plugin** -- open `nvim` and run `:Lazy sync` (or just relaunch; lazy auto-installs missing plugins on startup). The lockfile at `~/.local/state/nvim/lazy-lock.json` pins versions; commit-bump plugins with `:Lazy update`.

To remove a plugin, delete its spec and run `:Lazy clean`.

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
