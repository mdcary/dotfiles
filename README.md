# Home Manager Configuration

Nix Home Manager config with separate profiles for work and personal machines.

## Structure

```
flake.nix          # Flake entry point — defines both configurations
home-common.nix    # Shared config (neovim, tmux, zsh, git base, fzf, starship, etc.)
home-work.nix      # Work: git identity, awscli, ODBC, WSL aliases, MdClarity repos
home-personal.nix  # Personal: git identity (expand as needed)
home.nix           # Legacy single-file config (can be removed)
dotfiles/          # Dotfiles managed by Home Manager (e.g. nvim config)
pkgs/              # Custom package definitions (e.g. linear-cli)
```

## Prerequisites

- [Nix](https://nixos.org/download/) with flakes enabled
- [Home Manager](https://nix-community.github.io/home-manager/) (standalone install)

If flakes aren't enabled, add to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Usage

### Switch to a configuration

```bash
# On your work machine (WSL)
home-manager switch --flake .#cary@work

# On your personal machine
home-manager switch --flake .#cary@home
```

### Preview what will be built (without applying)

```bash
nix build .#homeConfigurations.cary@work.activationPackage --dry-run
nix build .#homeConfigurations.cary@home.activationPackage --dry-run
```

### Update flake inputs (nixpkgs, home-manager, etc.)

```bash
nix flake update
```

### Update a single input

```bash
nix flake update claude-code
```

## Adding configuration

- **Shared across machines** — edit `home-common.nix`
- **Work-only** (WSL, MdClarity tools, AWS) — edit `home-work.nix`
- **Personal-only** — edit `home-personal.nix`

Home Manager's module system merges attributes from all imported modules, so you can set `programs.zsh.shellAliases` in both common and work modules and they'll combine.

## Custom packages

Packages not in nixpkgs are defined in `flake.nix` (e.g. `duckdb-1-5-bin`, `taws-bin`) or in `pkgs/` (e.g. `linear-cli`) and passed to modules via `extraSpecialArgs`.
