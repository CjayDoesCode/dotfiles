#!/usr/bin/env bash

timestamp="$(date +%Y%m%d_%H%M%S)"
output="${HOME}/Pictures/Screenshot_${timestamp}.png"
region=''

if region="$(slurp -b '#282828e6' -w 0)"; then
  grim -g "${region}" "${output}" && wl-copy <"${output}"
fi
