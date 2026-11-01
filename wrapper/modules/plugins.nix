{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
let
  types = (import ../types) { inherit pkgs lib; };
  enabledPlugins = lib.filter (p: p.enable) config.plugins;
  pluginConfig = lib.concatMapStringsSep "\n" (
    plugin:
    builtins.concatStringsSep "\n" (
      [
        ''
          ## ${plugin.name}
          source "${plugin.src}/${plugin.file}"
        ''
      ]
      ++ (lib.optional (plugin.init != null) plugin.init)
    )
  ) (wlib.dag.sortAndUnwrap { dag = enabledPlugins; });
in
{
  options = {
    plugins = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (
        wlib.types.spec [
          types.plugin
          config.interfaces.sortable
        ]
      );
      # type = lib.types.listOf types.plugin;
      description = "List of zsh plugins.";
    };
    utils.hasPlugin = lib.mkOption {
      type = lib.types.functionTo lib.types.bool;
      internal = true;
      readOnly = true;
      default =
        name:
        lib.elem name (
          lib.pipe config.plugins [
            (lib.filter (p: p.enable))
            (lib.map (p: lib.getName p.package))
          ]
        );
    };
  };
  config.snippets.plugins = pluginConfig;
}
