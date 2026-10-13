{
  config,
  wlib,
  lib,
  pkgs,
  ...
}@top:
{
  options.interfaces = {
    integratable = lib.mkOption {
      type = lib.types.deferredModule;
      readOnly = true;
      internal = true;
      default = (
        { config, name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "${name} integration";
            package = lib.mkPackageOption pkgs name { };
            install = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether to install ${name} into $PATH.
              '';
            };
            init = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.either lib.types.str (lib.types.functionTo lib.types.str) # exe: string
              );
              description = ''
                Initialization command for ${name}.
                Can be either a string or as a function `exe -> str` where
                `exe` is the executable extracted from package.
                Defaults to sourcing the output of `exe initArgs` (generated
                at build time) if `initArgs` is set.
              '';
              default =
                if config.initArgs != null then
                  exe: "source ${top.config.utils.initScript exe config.initArgs}"
                else
                  null;
              defaultText = lib.literalExpression ''
                if initArgs != null then exe: "source ''${utils.initScript exe initArgs}" else null
              '';
            };
            initArgs = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              example = "init zsh";
              description = ''
                Arguments passed to the executable of ${name} to print its zsh
                init script, e.g. `init zsh` or `--zsh`.
              '';
            };
          };
        }
      );
    };
    sortable = lib.mkOption {
      type = lib.types.deferredModule;
      readOnly = true;
      internal = true;
      default = {
        options = {
          before = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
          after = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      };
    };
  };
}
