$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Force tools/godot,work/appdata | Out-Null
$url='https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
Invoke-WebRequest $url -OutFile tools/godot.zip
Expand-Archive tools/godot.zip tools/godot -Force
New-Item -ItemType File -Force tools/godot/_sc_ | Out-Null
$env:APPDATA=(Resolve-Path work/appdata).Path
& ./tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --editor --path game --import --quit
Write-Output 'Ready. Double-click Start Game.cmd.'
