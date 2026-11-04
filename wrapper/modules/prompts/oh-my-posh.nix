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
      oh-my-posh = cfg.install wlib.wrapperModules.oh-my-posh;
    };
  };
  config = {
    integrations.oh-my-posh = {
      enable = config.prompts.oh-my-posh.enable;
      package = config.prompts.oh-my-posh.wrapper;
      init = lib.mkDefault (exe: ''
        eval "$(${exe} init zsh)"
        # omp only renders in precmd. Re-render on terminal resize so that width
        # dependent segments (min_width/max_width) update while at the prompt.
        TRAPWINCH() { zle && zle omp_repaint_prompt }
      '');
    };
  };
}
