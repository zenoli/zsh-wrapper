bindkey -v
# Leave insert mode without the default 0.4s delay
KEYTIMEOUT=1

() {
  autoload -Uz select-bracketed select-quoted surround edit-command-line add-zle-hook-widget
  zle -N select-bracketed
  zle -N select-quoted
  zle -N delete-surround surround
  zle -N change-surround surround
  zle -N edit-command-line

  # add-surround briefly enters insert mode. The keymap-select hooks
  # this triggers (e.g. starship's reset-prompt) redraw the prompt
  # mid-widget, which garbles multi-line prompts, so mute them.
  function _vi_mode_add_surround() {
    local hook=${widgets[zle-keymap-select]}
    [[ $hook == user:* ]] && zle -D zle-keymap-select
    {
      surround "$@"
    } always {
      [[ $hook == user:* ]] && zle -N zle-keymap-select ${hook#user:}
    }
  }
  zle -N add-surround _vi_mode_add_surround

  # Like edit-command-line, but puts the cursor at the end of the
  # edited line and restores the cursor shape the editor leaves behind.
  function _vi_mode_edit_command_line() {
    zle edit-command-line -w
    CURSOR=$#BUFFER
    _vi_mode_cursor
  }
  zle -N _vi_mode_edit_command_line

  # Text objects: ci", da(, yi{, ...
  local km c
  for km in viopp visual; do
    for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
      bindkey -M $km -- $c select-bracketed
    done
    for c in {a,i}${(s..)^:-\'\"\`\|,./:\;=+@}; do
      bindkey -M $km -- $c select-quoted
    done

  done

  # Surround: cs"', ds(, ysiw"
  bindkey -M vicmd cs change-surround
  bindkey -M vicmd ds delete-surround
  bindkey -M vicmd ys add-surround
  bindkey -M visual S add-surround

  # Edit the command line in $EDITOR
  bindkey -M viins '^F' _vi_mode_edit_command_line
  bindkey -M vicmd '^F' _vi_mode_edit_command_line

  # Allow deleting past the point where insert mode was entered
  bindkey -M viins '^?' backward-delete-char
  bindkey -M viins '^H' backward-delete-char
  bindkey -M viins '^W' backward-kill-word
  bindkey -M viins '^U' backward-kill-line

  # Cursor shape: block in normal mode, beam in insert mode
  function _vi_mode_cursor() {
    if [[ $KEYMAP == vicmd ]]; then
      print -n '\e[2 q'
    else
      print -n '\e[6 q'
    fi
  }
  add-zle-hook-widget keymap-select _vi_mode_cursor
  add-zle-hook-widget line-init _vi_mode_cursor
}
