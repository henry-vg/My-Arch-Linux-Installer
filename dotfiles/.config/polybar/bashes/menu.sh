#!/usr/bin/env bash

set -euo pipefail

ROFI_GROUPS_THEME="~/.config/rofi/menu-groups.rasi"
ROFI_APPS_THEME="~/.config/rofi/menu-apps.rasi"

show_groups() {
  printf '%s\n' "teste1" "teste2" "teste3" | rofi -dmenu -i -p "menu" -theme "$ROFI_GROUPS_THEME"
}

show_apps() {
  local group="$1"

  case "$group" in
    teste1)
      printf '%s\n' \
        "firefox|Firefox|firefox"
      ;;
    teste2)
      printf '%s\n' \
        "firefox|Firefox|firefox"
      ;;
    teste3)
      printf '%s\n' \
        "firefox|Firefox|firefox"
      ;;
    *)
      exit 0
      ;;
  esac
}

run_app_menu() {
  local group="$1"

  local selected
  selected="$(
    show_apps "$group" |
      while IFS='|' read -r icon text cmd; do
        printf '%s\0icon\x1f%s\n' "$text|$cmd" "$icon"
      done |
      rofi -dmenu -i -p "$group" -format s -theme "$ROFI_APPS_THEME"
  )"

  [ -n "${selected:-}" ] || exit 0

  local app_name cmd
  app_name="${selected%%|*}"
  cmd="${selected#*|}"

  nohup bash -lc "$cmd" >/dev/null 2>&1 &
}

main() {
  local group
  group="$(show_groups)"

  [ -n "${group:-}" ] || exit 0

  run_app_menu "$group"
}

main "$@"