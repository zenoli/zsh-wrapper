# Ctrl-e toggles an expanded oh-my-posh prompt: nothing truncated, collapsed or hidden.
# The theme (config/oh-my-posh.nix) truncates segments to a percentage of $OMP_COLUMNS
# and collapses/hides them via min_width/max_width based on --terminal-width. When
# expanded, both are set as if the terminal was huge. $OMP_EXPAND shows extra details.
if (( $+functions[_omp_get_prompt] )); then
  # omp passes --terminal-width=$COLUMNS before any extra args and the last flag wins
  functions[_omp_get_prompt_unexpanded]=$functions[_omp_get_prompt]
  function _omp_get_prompt() {
    # Exported for the templates during rendering only
    local -x OMP_EXPAND=$OMP_EXPAND
    # Templates can't read the terminal width, so pass it via the environment
    local -x OMP_COLUMNS=${OMP_EXPAND:+9999}
    OMP_COLUMNS=${OMP_COLUMNS:-$COLUMNS}
    _omp_get_prompt_unexpanded "$@" ${OMP_EXPAND:+--terminal-width=9999}
  }

  function _omp_toggle_expand() {
    if [[ -n $OMP_EXPAND ]]; then
      unset OMP_EXPAND
    else
      OMP_EXPAND=1
    fi
    zle omp_repaint_prompt
  }
  zle -N _omp_toggle_expand
  bindkey -M viins '^E' _omp_toggle_expand
  bindkey -M vicmd '^E' _omp_toggle_expand
fi
