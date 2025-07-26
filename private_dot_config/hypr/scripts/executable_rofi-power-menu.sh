#!/usr/bin/env bash

declare -A option_icons=(
  ["Lock"]="system-lock-screen"
  ["Sleep"]="system-suspend"
  ["Hibernate"]="system-hibernate"
  ["Reboot"]="system-reboot"
  ["Shutdown"]="system-shutdown"
)

print_options() {
  for option in "${!option_icons[@]}"; do
    printf "%s\\0icon\\x1f%s\n" "${option}" "${option_icons[${option}]}"
  done
}

if option="$(print_options | rofi -dmenu -i)"; then
  sleep 0.25
  case "${option}" in
  Lock) loginctl lock-session ;;
  Sleep) systemctl suspend ;;
  Hibernate) systemctl hibernate ;;
  Reboot) systemctl reboot ;;
  Shutdown) systemctl poweroff ;;
  esac
fi
