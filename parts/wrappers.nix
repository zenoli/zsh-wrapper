{ self, withSystem, ... }:
{
  flake.wrappers = {
    starship =
      { pkgs, wlib, ... }:
      {
        imports = [ wlib.wrapperModules.starship ];
        preset = "tokyo-night";
        settings.add_newline = false;
      };
    direnv =
      { pkgs, wlib, ... }:
      {
        imports = [ wlib.wrapperModules.direnv ];
        nix-direnv.enable = true;
        silent = true;
      };
    zsh = {
      imports = [
        (self + /wrapper)
        (self + /config)
      ];
    };
  };
}
