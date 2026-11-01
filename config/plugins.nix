{
  config,
  pkgs,
  lib,
  ...
}:
{
  plugins = with pkgs; [
    {
      package = zsh-vi-mode;
      # Replaced by the built-in vi mode (viMode.enable)
      enable = false;
      # Upstream zvm_define_widget forks two subshells per widget (~45ms before
      # the first prompt). Same logic, but using fork-free zsh parameters.
      init = ''
        function zvm_define_widget() {
          local widget=$1
          local func=$2 || $1
          local rawfunc=''${widgets[$widget]#user:}

          # Check if existing the same name
          # (`zle -l -L` only prints a 4th word for user widgets whose
          # function name differs from the widget name)
          if [[ ''${widgets[$widget]} == user:* && $rawfunc != $widget ]]; then
            local wrapper="zvm_''${widget}-wrapper"

            # To avoid double calling, we need to check if the raw function
            # has been called already in the custom widget function
            local rawcode=''${functions[$func]}
            local called=false
            [[ "$rawcode" == *"\$rawfunc"* ]] && { called=true }

            eval "$wrapper() { zvm_widget_wrapper $rawfunc $func $called \"\$@\" }"
            func=$wrapper
          fi

          zle -N $widget $func
        }
      '';
    }
    {
      package = oh-my-zsh;
      file = "plugins/git/git.plugin.zsh";
    }
    {
      package = zsh-fzf-tab;
      name = "fzf-tab";
    }
    {
      package = fzf-git-sh;
      file = "fzf-git.sh";
      init = ''
        alias gc='git checkout $(_fzf_git_branches)'
      '';
    }
    zsh-syntax-highlighting
  ];
}
