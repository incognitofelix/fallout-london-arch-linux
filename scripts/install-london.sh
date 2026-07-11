#!/usr/bin/env bash
# Copies the GOG Fallout London payload (downloaded via Heroic) into your
# (already downgraded) Steam Fallout 4 install and the Proton prefix.
#
# Usage:
#   ./install-london.sh "<LONDON-FOLDER>" "<FALLOUT4-FOLDER>"
# Example:
#   ./install-london.sh "$HOME/Games/Heroic/Fallout London" \
#       "$HOME/.local/share/Steam/steamapps/common/Fallout 4"
set -euo pipefail
LON="${1:?London folder missing}"
FO4="${2:?Fallout 4 folder missing}"
PFX="$HOME/.local/share/Steam/steamapps/compatdata/377160/pfx/drive_c/users/steamuser"

[ -f "$LON/f4se_loader.exe" ] || { echo "ERROR: $LON does not look like the London folder (no f4se_loader.exe)"; exit 1; }
[ -f "$FO4/Fallout4.exe" ]    || { echo "ERROR: $FO4 does not look like Fallout 4 (no Fallout4.exe)"; exit 1; }

echo ">> Merging London Data into Fallout4/Data (hardlink, else copy)..."
cp -rlf "$LON/Data/." "$FO4/Data/" 2>/dev/null || cp -rf "$LON/Data/." "$FO4/Data/"

echo ">> Copying F4SE + preloader + control map into the game root..."
cp -f "$LON"/f4se_*.* "$LON/WinHTTP.dll" "$LON/xSE PluginPreloader.xml" "$LON/CustomControlMap.txt" "$FO4/"

echo ">> Setting the preloader load method to OnProcessAttach (required under Wine/Proton)..."
sed -i 's/<LoadMethod Name="ImportAddressHook">/<LoadMethod Name="OnProcessAttach">/' "$FO4/xSE PluginPreloader.xml"

echo ">> Placing the console control map at the F4SE location (so rebinds take effect)..."
mkdir -p "$FO4/Data/F4SE"
cp -f "$LON/CustomControlMap.txt" "$FO4/Data/F4SE/CustomControlMap.txt"

echo ">> Copying config files into the Proton prefix (AppID 377160)..."
mkdir -p "$PFX/Documents/My Games/Fallout4" "$PFX/AppData/Local/Fallout4"
cp -f "$LON/__Config/"*.ini "$PFX/Documents/My Games/Fallout4/" 2>/dev/null || true
cp -f "$LON/__AppData/"*    "$PFX/AppData/Local/Fallout4/"       2>/dev/null || true

echo "DONE. (You should have launched Fallout 4 once beforehand so the prefix exists.)"
