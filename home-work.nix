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

  programs.awscli = let
    # 1. Define common SSO variables in one place
    # Note: I've removed the trailing '#' from the URL to avoid the hashing bug
    sso_defaults = {
      sso_start_url = "https://mdclarity.awsapps.com/start";
      sso_region = "us-west-2";
      region = "us-east-2";
      sso_role_name = "AWSAdministratorAccess";
    };

    # 2. A helper function to generate the profile set
    # This automatically adds the credential_process for DuckDB compatibility
    mkProfile = name: accountId: role: (sso_defaults // {
      sso_account_id = accountId;
      sso_role_name = role;
      credential_process = "aws configure export-credentials --profile ${name}";
    });
  in {
    enable = true;
    settings = {
      # 3. Define your profiles using the helper
      "profile default"    = mkProfile "default" "367268567544" "AWSAdministratorAccess";
      "profile dev-admin"  = mkProfile "dev-admin" "367268567544" "AWSAdministratorAccess";
      "profile dev"  = mkProfile "dev" "367268567544" "dev-team-access";
      "profile llm-tool-access"  = mkProfile "llm-tool-access" "367268567544" "llm-tool-access";
      "profile prod-admin" = mkProfile "prod-admin" "096002140659" "AWSAdministratorAccess";
      "profile devops"     = mkProfile "devops" "789261558096" "AWSAdministratorAccess";
      "profile logs"      = mkProfile "logs" "616967731364" "AWSAdministratorAccess";
      "profile audit"      = mkProfile "audit" "718557712346" "AWSAdministratorAccess";
      "profile management"    = mkProfile "management" "637217033209" "AWSAdministratorAccess";
      "profile omni"    = mkProfile "omni" "277207922039" "AWSAdministratorAccess";

      # Special case for Bedrock (different role)
      "profile bedrock"    = mkProfile "bedrock" "367268567544" "llm-tool-access";

      # The sso-session block (optional if using the flattened style above, but safe to keep)
      "sso-session dev" = {
        sso_region = sso_defaults.sso_region;
        sso_start_url = sso_defaults.sso_start_url;
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
    # WSL Windows aliases
    code = "\"/mnt/c/Users/CaryLee/AppData/Local/Programs/Microsoft VS Code/bin/code\"";
    explorer = "/mnt/c/Windows/explorer.exe";
    clip = "/mnt/c/Windows/System32/clip.exe";
    cmd = "/mnt/c/Windows/System32/cmd.exe";
    powershell = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
  };

  programs.zsh.initContent = ''
    export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
    export WINHOME='/mnt/c/Users/CaryLee'
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
    d2
    unixodbcDrivers.msodbcsql17
    taws-bin
    stu
    azure-cli
  ];

  home.file = {
    ".config/odbcinst/odbcinst.ini".text = ''
      [ODBC Driver 17 for SQL Server]
      Description=Microsoft ODBC Driver 17 for SQL Server
      Driver=${pkgs.unixodbcDrivers.msodbcsql17}/lib/libmsodbcsql-17.7.so.1.1

      [ODBC Driver 18 for SQL Server]
      Description=Microsoft ODBC Driver 18 for SQL Server
      Driver=${pkgs.unixodbcDrivers.msodbcsql17}/lib/libmsodbcsql-18.1.so.1.1
    '';
  };

  home.file.".duckdbrc".text = ''
    -- Load extensions automatically
    INSTALL httpfs;
    INSTALL aws;
    SET autoload_known_extensions = true;

    -- Configure the secret using the environment's credential chain
    CREATE OR REPLACE SECRET s3 (
        TYPE S3,
        PROVIDER CREDENTIAL_CHAIN
    );
  '';

  home.sessionVariables = {
    LD_LIBRARY_PATH = "${pkgs.unixodbc}/lib";
    ODBCSYSINI = "${config.home.homeDirectory}/.config/odbcinst";
  };
}
