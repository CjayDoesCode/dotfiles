#!/usr/bin/env bash

declare -A options=(
  ["Lock"]="system-lock-screen"
  ["Sleep"]="system-suspend"
  ["Hibernate"]="system-hibernate"
  ["Reboot"]="system-reboot"
  ["Shutdown"]="system-shutdown"
)

print_options() {
  for key in "${!options[@]}"; do
    printf "%s\\0icon\\x1f%s\n" "${key}" "${options["${key}"]}"
  done
}

case "$(print_options | rofi -dmenu -i)" in
Lock) loginctl lock-session ;;
Sleep) systemctl suspend ;;
Hibernate) systemctl hibernate ;;
Reboot) systemctl reboot ;;
Shutdown) systemctl poweroff ;;
esac
