@echo off
cd /d "%~dp0"
if not exist work\appdata mkdir work\appdata
set "APPDATA=%~dp0work\appdata"
start "Bus 47C" "tools\godot\Godot_v4.7.2-stable_win64.exe" --path game
