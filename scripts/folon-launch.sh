#!/usr/bin/env bash
# Steam launch wrapper for Fallout: London (Steam Fallout 4 under Proton).
#
# In Steam -> Fallout 4 -> Properties -> Launch Options, enter:
#     /home/YOURNAME/fallout-london-arch-linux/scripts/folon-launch.sh %command%
#
# What it does:
#  1) load winhttp as NATIVE  -> the xSE preloader kicks in -> Buffout loads early
#  2) replace the Fallout4Launcher.exe / Fallout4.exe that Steam starts with
#     f4se_loader.exe  -> the F4SE core loads -> all plugins come with it
export WINEDLLOVERRIDES="winhttp=n,b"
args=()
for a in "$@"; do
  case "$a" in
    */Fallout4Launcher.exe) a="${a%/Fallout4Launcher.exe}/f4se_loader.exe" ;;
    */Fallout4.exe)         a="${a%/Fallout4.exe}/f4se_loader.exe" ;;
  esac
  args+=("$a")
done
exec "${args[@]}"
