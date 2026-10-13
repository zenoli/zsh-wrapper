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
  direnvConfig = config.integrations.direnv;
  inherit (config.utils) initScript;
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
      fzf.init = lib.mkDefault (
        exe:
        let
          initCmd = "source ${initScript exe "--zsh"}";
        in
        if (config.utils.hasPlugin "zsh-vi-mode") then
          "zvm_after_init_commands+=('${initCmd}')"
        else
          initCmd
      );
      starship.initArgs = lib.mkDefault "init zsh";
      # Only set init if powerlevel10k is disabled and direnv is enabled
      # powerlevel10k has its own special way of initializing direnv
      direnv.initArgs = lib.mkIf (!config.prompts.powerlevel10k.enable) (lib.mkDefault "hook zsh");
      devenv.initArgs = lib.mkDefault "hook zsh";
      kitty.init = ''
        if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
          export KITTY_SHELL_INTEGRATION="enabled"
          autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
          kitty-integration
          unfunction kitty-integration
        fi
      '';

    };
    snippets.integrations = integrationConfig;
    runtimePkgs = lib.map (i: {
      data = i.package;
      prefix = true;
    }) runtimeIntegrations;
    # We need to re-define this in the context of zsh, as otherwise
    # the direnv hook will not pick up the config wrapped inside
    # the direnv-wrapper.
    env.DIRENV_CONFIG = lib.mkIf direnvConfig.enable direnvConfig.settings.passthru.DIRENV_CONFIG;
  };
}
