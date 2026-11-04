{
  pkgs,
  config,
  wlib,
  lib,
  ...
}:
{
  imports = [
    ./plugins.nix
    ./oh-my-posh.nix
  ];
  prompt = "oh-my-posh";
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
    kitty = {
      enable = true;
      install = false;
    };
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
    fzf.enable = lib.mkDefault true;
    yazi.enable = true;
  };
  zshSrc.directory = lib.mkDefault ./src;
}
