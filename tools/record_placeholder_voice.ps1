$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$destination=Join-Path $root 'work/voice-masters'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Add-Type -AssemblyName System.Speech
$voice=New-Object System.Speech.Synthesis.SpeechSynthesizer
$voice.Rate=-1
$voice.SetOutputToWaveFile((Join-Path $destination 'firewatcher_intro.wav'))
$voice.Speak('Twelve hours alone in that firewatch tower. Loomesville Forest can find another firewatcher tomorrow. I need to get home.')
$voice.SetOutputToWaveFile((Join-Path $destination 'hunger_mumble.wav'))
$voice.Rate=-2
$voice.Speak('Twelve hour shifts. Missed another meal.')
$voice.Dispose()
python (Join-Path $PSScriptRoot 'build_performance_audio.py')
