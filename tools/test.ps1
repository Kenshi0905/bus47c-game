$ErrorActionPreference='Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$godot='./tools/godot/Godot_v4.7.2-stable_win64_console.exe'
if(-not(Test-Path $godot)){throw 'Run tools/setup.ps1 first'}
New-Item -ItemType Directory -Force work/appdata | Out-Null
$env:APPDATA=(Resolve-Path work/appdata).Path
function Run-Check([string[]]$GodotArgs){
 $output=& $godot @GodotArgs 2>&1
 $code=$LASTEXITCODE
 $output | Write-Output
 if($code -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:|Assertion failed')){throw 'Godot check failed'}
}
Run-Check @('--headless','--editor','--path','game','--import','--quit')
Run-Check @('--headless','--path','game','--script','res://tests/test_story.gd')
Run-Check @('--headless','--path','game','--','--smoke')
