param(
    [string]$OutputDirectory = '',
    [string]$ZipPath = '',
    [switch]$SkipImport
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$godot=Join-Path $projectRoot 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$template=Join-Path $projectRoot 'work/export-templates/4.7.2.stable/windows_release_x86_64.exe'
if(-not(Test-Path -LiteralPath $godot)){throw 'Run tools/setup.ps1 first.'}
if(-not(Test-Path -LiteralPath $template)){throw 'Run python tools/fetch_windows_template.py first.'}
if([string]::IsNullOrWhiteSpace($OutputDirectory)){$OutputDirectory=Join-Path $projectRoot 'work/beta-windows'}
$buildDirectory=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $buildDirectory,(Join-Path $projectRoot 'work/appdata') | Out-Null
$env:APPDATA=(Resolve-Path -LiteralPath (Join-Path $projectRoot 'work/appdata')).Path
function Invoke-GodotCheck([string[]]$Arguments){
    $lines=& $godot @Arguments 2>&1
    $code=$LASTEXITCODE
    $lines | Write-Output
    if($code -ne 0 -or ($lines -match 'SCRIPT ERROR:|ERROR:|Assertion failed')){throw 'Godot export check failed.'}
}
if(-not $SkipImport){Invoke-GodotCheck @('--headless','--editor','--path','game','--import','--quit')}
$executable=Join-Path $buildDirectory 'Bus47C.exe'
Invoke-GodotCheck @('--headless','--path','game','--export-release','Windows Beta',$executable)
$notices=Join-Path $buildDirectory 'Licenses'
Invoke-GodotCheck @('--headless','--script',(Join-Path $PSScriptRoot 'export_notices.gd'),'--',$notices)
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/BETA_README.txt') -Destination (Join-Path $buildDirectory 'READ_ME.txt') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/audio-sources.md') -Destination (Join-Path $buildDirectory 'AUDIO_SOURCES.txt') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'game/assets/ui/fonts/OFL.txt') -Destination (Join-Path $notices 'BEBAS_NEUE_OFL.txt') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'game/assets/ui/fonts/ShareTechMono-OFL.txt') -Destination (Join-Path $notices 'SHARE_TECH_MONO_OFL.txt') -Force
$revision=(& git rev-parse HEAD).Trim()
$sourceState=if((& git status --porcelain -- game tools docs/BETA_README.txt docs/audio-sources.md)){ 'Working tree includes beta changes' }else{ 'Clean checkout' }
@("Bus 47C 0.13.0-beta.1", "Source base: $revision", "Source state: $sourceState", "Built UTC: $([DateTime]::UtcNow.ToString('o'))",'Godot: 4.7.2.stable','Platform: Windows x86_64','Graphics: Compatibility OpenGL 3.3') | Set-Content -LiteralPath (Join-Path $buildDirectory 'BUILD_INFO.txt') -Encoding utf8
$files=@('Bus47C.exe','Bus47C.pck','READ_ME.txt','AUDIO_SOURCES.txt','BUILD_INFO.txt')
foreach($file in $files){if(-not(Test-Path -LiteralPath (Join-Path $buildDirectory $file))){throw "Missing build file: $file"}}
Write-Output "Windows beta exported to $buildDirectory"
if(-not [string]::IsNullOrWhiteSpace($ZipPath)){
    # Windows PowerShell 5 loads the archive enum from a separate assembly.
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archivePath=[IO.Path]::GetFullPath($ZipPath)
    New-Item -ItemType Directory -Force -Path (Split-Path $archivePath -Parent) | Out-Null
    $pendingPath=$archivePath+'.pending'
    $archive=[IO.Compression.ZipFile]::Open($pendingPath,[IO.Compression.ZipArchiveMode]::Create)
    try{
        foreach($file in ($files+@('Licenses/GODOT_LICENSE.txt','Licenses/GODOT_THIRD_PARTY.txt','Licenses/BEBAS_NEUE_OFL.txt','Licenses/SHARE_TECH_MONO_OFL.txt'))){
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $buildDirectory $file),('Bus47C-Beta-0.13.0-Windows/'+$file),[IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }finally{$archive.Dispose()}
    Move-Item -LiteralPath $pendingPath -Destination $archivePath -Force
    Get-FileHash -LiteralPath $archivePath -Algorithm SHA256 | Format-List
    Write-Output "Ready: $archivePath"
}
