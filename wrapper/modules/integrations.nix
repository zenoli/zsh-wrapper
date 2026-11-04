{
  config,
  wlib,
  lib,
  pkgs,
  ...
}@top:
let
  enabledIntegrations = lib.filter (i: i.enable) (
    wlib.dag.sortAndUnwrap { dag = config.integrations; }
  );
  runtimeIntegrations = lib.filter (i: i.install) enabledIntegrations;
  initializableIntegrations = lib.filter (i: i.init != null) enabledIntegrations;

  wrapperIntegrationWith =
    wrapperModule:
    lib.types.submoduleWith {
      modules = [
        (
          { config, ... }:
          {
            options.settings = lib.mkOption {
              type = wlib.types.subWrapperModule wrapperModule;
            };
            config.settings.pkgs = lib.mkDefault pkgs;
            config.package = lib.mkDefault config.settings.wrapper;
          }
        )
        config.interfaces.integratable
        config.interfaces.sortable
      ];
    };
  mkWrapperIntegrationOption =
    wrapperModule:
    lib.mkOption {
      type = wrapperIntegrationWith wrapperModule;
    };

  getInitCommand =
    integration:
    if lib.isFunction integration.init then
      (integration.init (lib.getExe integration.package))
    else
      integration.init;
  integrationConfig = lib.concatMapStringsSep "\n" (integration: ''
    ## ${lib.getName integration.package} integration
    ${getInitCommand integration}
  '') initializableIntegrations;
in
{
  options = {
    integrations = lib.mkOption {
      default = { };
      type = lib.types.submodule (
        { config, ... }:
        {
          freeformType = with lib.types; attrsOf (submodule top.config.interfaces.integratable);
          options = {
            direnv = mkWrapperIntegrationOption wlib.wrapperModules.direnv;
          };
        }
      );
    };
    utils.initScript = lib.mkOption {
      type = lib.types.functionTo (lib.types.functionTo lib.types.package);
      internal = true;
      readOnly = true;
      description = ''
        `exe: args: drv` - Runs `exe args` at build time and stores its output.
        Sourcing the result instead of `eval "$(exe args)"` saves a fork at
        every shell startup.
      '';
      default =
        exe: args: pkgs.runCommand "${baseNameOf exe}-init.zsh" { } "HOME=$TMPDIR ${exe} ${args} > $out";
    };
    utils.hasIntegration = lib.mkOption {
      type = lib.types.functionTo lib.types.bool;
      internal = true;
      readOnly = true;
      default =
        name:
        lib.elem name (
          lib.pipe enabledIntegrations [
            (lib.map (p: lib.getName p.package))
          ]
        );
    };
  };
  config = {
    integrations = {
      # Preset init commands
      fzf.initArgs = lib.mkDefault "--zsh";
      direnv.initArgs = lib.mkDefault "hook zsh";
      devenv.initArgs = lib.mkDefault "hook zsh";

      # see https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
      kitty.init = ''
        if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
          export KITTY_SHELL_INTEGRATION="enabled"
          autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
          kitty-integration
          unfunction kitty-integration
        fi
      '';

      # see https://yazi-rs.github.io/docs/quick-start
      yazi.init = exe: ''
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          ${exe} "$@" --cwd-file="$tmp"
          IFS= read -r -d ''' cwd < "$tmp"
          [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
          rm -f -- "$tmp"
        }
      '';

    };
    snippets.integrations = integrationConfig;
    runtimePkgs = lib.map (i: {
      data = i.package;
      prefix = true;
    }) runtimeIntegrations;
  };
}
