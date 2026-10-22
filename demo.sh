#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
PS1_FAKE=$'\033[38;5;208m@void\033[0m $ '

# type a command char-by-char, then run it
run() {
  printf '%s' "$PS1_FAKE"
  local c="$1"
  for ((i=0; i<${#c}; i++)); do printf '%s' "${c:$i:1}"; sleep 0.03; done
  printf '\n'; sleep 0.4
  eval "$c"
}
note() { printf '\033[2m%s\033[0m\n' "$1"; sleep 0.8; }

clear
sleep 0.6
run "overlord-help"
sleep 3.5
clear

note "# System agent: it proposes a command, YOU approve before it runs"
run "echo n | overlord-sys 'how much disk space is free'"
sleep 2.5
clear

note "# 384 of Overlord's real voice lines, searchable"
run "overlord-find --search 'copy that'"
sleep 2.5

note "# Security specialists: rev, malware, ctf, web, pwn, crypto, android"
run "ovx --list"
sleep 3
