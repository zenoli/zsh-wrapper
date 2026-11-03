{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prompts;
in
{
  options = {
    prompts = {
      starship = cfg.install wlib.wrapperModules.starship;
    };
  };
  config = {
    integrations.starship = {
      enable = config.prompts.starship.enable;
      package = config.prompts.starship.wrapper;
      initArgs = lib.mkDefault "init zsh";
    };
  };
}
