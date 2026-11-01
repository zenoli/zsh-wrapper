{
  config,
  lib,
  ...
}:
let
  cfg = config.viMode;
in
{
  options = {
    viMode = {
      enable = lib.mkEnableOption "zsh's built-in vi mode with text objects, surround and cursor shapes";
      init = lib.mkOption {
        type = lib.types.str;
        default = builtins.readFile ./vi-mode.zsh;
      };
    };
  };
  # Plugins and integrations add their own bindings to the active keymap,
  # so `bindkey -v` has to run before them.
  config.snippets.viMode = lib.mkIf cfg.enable {
    after = [ "completion" ];
    before = [ "plugins" ];
    data = cfg.init;
  };
}
