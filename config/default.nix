{
  pkgs,
  config,
  wlib,
  lib,
  ...
}:
{
  imports = [ ./plugins.nix ];
  prompt = "starship";
  viMode.enable = true;
  prompts = {
    powerlevel10k = {
      "p10k.zsh" = ./src/.p10k.zsh;
    };
    starship = {
      preset = "pastel-powerline";
    };
  };
  integrations = {
    direnv = {
      enable = lib.mkDefault true;
      settings = {
        silent = true;
        nix-direnv.enable = true;
        extraConfig = {
          load_dotenv = true;
        };
      };
    };
    devenv.enable = false;
    fzf = {
      enable = lib.mkDefault true;
    };
    kitty = {
      enable = true;
      install = false;
    };
  };
  zshSrc.directory = lib.mkDefault ./src;
}
