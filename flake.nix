{
  description = ''
    Uses flake-parts to set up the flake outputs:

    `wrappers`, `wrapperModules` and `packages.*.*`
  '';
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    wrappers = {
      url = "github:zenoli/nix-wrapper-modules/direnv-wrapper-module";
      # url = "git+file:///home/zenoli/repos/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
  };
  outputs =
    {
      self,
      nixpkgs,
      wrappers,
      flake-parts,
      import-tree,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, withSystem, ... }:
      {
        systems = nixpkgs.lib.platforms.all;
        imports = [
          wrappers.flakeModules.wrappers
          (import-tree ./parts)
        ];
      }
    );
}
