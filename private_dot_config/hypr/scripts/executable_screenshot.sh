#!/usr/bin/env bash

output="${HOME}/Pictures/Screenshot_$(date +%Y%m%d_%H%M%S).png"

if grim -g "$(slurp)" "${output}"; then
  wl-copy <"${output}"
fi
