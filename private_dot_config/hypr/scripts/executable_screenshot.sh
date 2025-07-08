#!/usr/bin/env bash

timestamp="$(date +%Y%m%d_%H%M%S)"
output="${HOME}/Pictures/Screenshot_${timestamp}.png"

if region="$(slurp)" && grim -g "${region}" "${output}"; then
  wl-copy <"${output}"
fi
