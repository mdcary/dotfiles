{ config, pkgs, taws-bin, ... }:

let
  linear-cli = pkgs.callPackage ./pkgs/linear-cli.nix { };
in
{
  home.sessionPath = [
    "$HOME/.dotnet/tools/"
  ];

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Cary Lee";
        email = "clee@mdclarity.com";
      };
    };
  };

  programs.git.settings = {
    user = {
      name = "Cary Lee";
      email = "clee@mdclarity.com";
    };

    core.sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe -i $HOME/.ssh/id_work.pub";
  };

  programs.git.includes = [
    {
      condition = "gitdir/i:~/src/personal/";
      contents = {
        user = {
          name = "Cary Lee";
          email = "carylee@gmail.com";
        };
        core.sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe -i $HOME/.ssh/id_personal.pub";
      };
    }
  ];

  programs.awscli = {
    enable = true;

    settings = {
      "profile default" = {
        sso_session = "dev";
        sso_account_id = "367268567544";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
        default = true;
      };

      "profile dev-admin" = {
        sso_session = "dev";
        sso_account_id = "367268567544";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };

      "profile prod-admin" = {
        sso_session = "dev";
        sso_account_id = "096002140659";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };

      "profile bedrock" = {
        sso_session = "dev";
        sso_account_id = "367268567544";
        sso_role_name = "llm-tool-access";
        region = "us-east-2";
      };

      "profile billing" = {
        sso_session = "dev";
        sso_account_id = "637217033209";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };

      "profile devops" = {
        sso_session = "dev";
        sso_account_id = "789261558096";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };

      "profile tools" = {
        sso_session = "dev";
        sso_account_id = "616967731364";
        sso_role_name = "AWSAdministratorAccess";
        region = "us-east-2";
      };

      "sso-session dev" = {
        sso_start_url = "https://mdclarity.awsapps.com/start/#";
        sso_region = "us-west-2";
        sso_registration_scopes = "sso:account:access";
      };
    };
  };

  programs.mr = {
    enable = true;

    settings = {
      "src/mdc/Infrastructure" = {
        checkout = "git clone git@github.com:MdClarity/Infrastructure.git Infrastructure";
      };

      "src/mdc/MdClarity" = {
        checkout = "git clone git@github.com:MdClarity/MdClarity.git MdClarity";
      };

      "src/mdc/payer-monitor" = {
        checkout = "git clone git@github.com:MdClarity/contract-manager.git payer-monitor";
      };

      "src/mdc/server-scripts" = {
        checkout = "git clone git@github.com:MdClarity/server-scripts.git";
      };

      "src/mdc/external-system-interfaces" = {
        checkout = "git clone git@github.com:MdClarity/external-system-interfaces.git";
      };
    };
  };

  programs.zsh.shellAliases = {
    docker = "podman";
    # WSL Windows aliases
    code = "\"/mnt/c/Users/CaryLee/AppData/Local/Programs/Microsoft VS Code/bin/code\"";
    explorer = "/mnt/c/Windows/explorer.exe";
    clip = "/mnt/c/Windows/System32/clip.exe";
    cmd = "/mnt/c/Windows/System32/cmd.exe";
    powershell = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
  };

  programs.zsh.initContent = ''
    mktree() {
      local repo=$1
      local branch_id=$2

      if [[ -z "$repo" || -z "$branch_id" ]]; then
        echo "Usage: mktree <repo> <branch-identifier>"
        return 1
      fi

      local src_dir="$HOME/src/mdc/$repo"
      local branch_name="cary/$branch_id"
      local tree_dir="$HOME/trees/$repo/$branch_id"

      if [[ ! -d "$src_dir" ]]; then
        echo "Error: Base repository '$src_dir' does not exist."
        return 1
      fi

      cd "$src_dir" || return 1

      mkdir -p "$HOME/trees/$repo"

      echo "Setting up worktree for '$branch_name'..."
      if ! git worktree add "$tree_dir" "$branch_name" 2>/dev/null; then
        echo "Branch not found locally/remotely. Creating new branch..."
        git worktree add -b "$branch_name" "$tree_dir"
      fi

      cd "$tree_dir" || return 1
      echo "Success! You are now in: $PWD"
    }
  '';

  home.packages = with pkgs; [
    linear-cli
    unixODBCDrivers.msodbcsql17
    podman
    podman-compose
    taws-bin
    stu
    wslu
  ];

  home.file = {
    ".config/odbcinst/odbcinst.ini".text = ''
      [ODBC Driver 17 for SQL Server]
      Description=Microsoft ODBC Driver 17 for SQL Server
      Driver=${pkgs.unixODBCDrivers.msodbcsql17}/lib/libmsodbcsql-17.7.so.1.1

      [ODBC Driver 18 for SQL Server]
      Description=Microsoft ODBC Driver 18 for SQL Server
      Driver=${pkgs.unixODBCDrivers.msodbcsql17}/lib/libmsodbcsql-18.1.so.1.1
    '';
  };

  home.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.unixODBC}/lib";
    ODBCSYSINI = "${config.home.homeDirectory}/.config/odbcinst";
  };
}
