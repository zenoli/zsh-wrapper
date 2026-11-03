{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prompts.powerlevel10k;

  presetRoot = cfg.package.src + "/config";
  presets = lib.pipe presetRoot [
    lib.readDir
    (lib.filterAttrs (_: type: type == "regular"))
    lib.attrNames
    (map (lib.removePrefix "p10k-"))
    (map (lib.removeSuffix ".zsh"))
  ];

  # presets [ "classic" "lean" "lean-8colors" "pure" "rainbow" "robbyrussell" ];
in
{
  options = {
    prompts = {
      powerlevel10k = {
        enable = lib.mkEnableOption "powerlevel10k prompt";
        package = lib.mkPackageOption pkgs "zsh-powerlevel10k" { };
        preset = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum presets);
          default = null;
        };
        "p10k.zsh" = lib.mkOption {
          type = lib.types.path;
          default =
            if cfg.preset != null then
              cfg.package.src + "/config/p10k-${cfg.preset}.zsh"
            else
              throw ''
                Either set `preset` to a non-null value or explicitly set `p10k.zsh` 
                to a path pointing to a valid `.p10k.zsh` file.
                You can use the configuration wizard to generate an initial `.p10k.zsh` 
                file by running:

                `nix run github:zenoli/zsh-flake#p10k-configure`
              '';
        };
      };
    };
  };
  config = {
    plugins = lib.mkIf cfg.enable [
      {
        package = cfg.package;
        file = "powerlevel10k.zsh-theme";
        init = ''
          [[ ! -f ${cfg."p10k.zsh"} ]] || source ${cfg."p10k.zsh"}
        '';
      }
    ];
    snippets = lib.mkIf cfg.enable {
      p10kInstantPrompt =
        let
          instantPrompt = ''
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi
          '';
        in
        if config.utils.hasIntegration "direnv" then
          let
            direnvExe = lib.getExe config.integrations.direnv.package;
          in
          # See: https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#how-do-i-initialize-direnv-when-using-instant-prompt
          ''
            emulate zsh -c "$(${direnvExe} export zsh)"
            ${instantPrompt}
            emulate zsh -c "source ${config.utils.initScript direnvExe config.integrations.direnv.initArgs}"
          ''
        else
          instantPrompt;
    };
    # powerlevel10k initializes direnv itself
    integrations.direnv.init = lib.mkIf cfg.enable (lib.mkForce null);
  };
}
