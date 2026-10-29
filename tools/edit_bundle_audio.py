"""Edit the user-authorized Horror Bundle reference into short gameplay cues.

Source audio stays in ignored work/audio09. No reference video is included.
"""
from pathlib import Path
import json, subprocess, wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
FFMPEG=ROOT/'work/audio08/deps/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
SOURCE=ROOT/'work/audio09/reference.webm'
RATE=44100
OUT=ROOT/'game/assets/audio'
reports=[]

def decode(start,duration):
    command=[str(FFMPEG),'-v','error','-ss',str(start),'-i',str(SOURCE),'-t',str(duration),'-vn','-ac','2','-ar',str(RATE),'-f','f32le','pipe:1']
    return np.frombuffer(subprocess.check_output(command),dtype='<f4').reshape(-1,2).copy()

def write(name,signal,start,duration,peak,fadein,fadeout,loop=False):
    signal-=signal.mean(axis=0)
    # Preserve source dynamics. Only lower excessive peaks.
    signal*=min(1,peak/max(float(np.max(np.abs(signal))),1e-8))
    if loop:
        count=round(RATE*.35)
        # Equal-power crossfade to the beginning, then trim the duplicate lead-in.
        t=np.linspace(0,1,count)[:,None]
        signal[-count:]=signal[-count:]*np.cos(t*np.pi/2)+signal[:count]*np.sin(t*np.pi/2)
        signal=signal[count:]
    else:
        n=min(len(signal),int(fadein*RATE)); signal[:n]*=np.linspace(0,1,n)[:,None]
        n=min(len(signal),int(fadeout*RATE)); signal[-n:]*=np.linspace(1,0,n)[:,None]
    signal*=min(1,peak/max(float(np.max(np.abs(signal))),1e-8))
    with wave.open(str(OUT/(name+'.wav')),'wb') as output:
        output.setnchannels(2);output.setsampwidth(2);output.setframerate(RATE)
        output.writeframes((np.clip(signal,-1,1)*32767).astype('<i2').tobytes())
    reports.append({'asset':name+'.wav','source_start_seconds':start,'source_duration_seconds':duration,'edited_seconds':len(signal)/RATE,'peak_dbfs':round(float(20*np.log10(max(np.max(np.abs(signal)),1e-9))),2),'loop':loop})

write('pack_path_mood',decode(12,24.35),12,24.35,.32,0,0,True)
write('pack_forestry_reveal',decode(405,15),405,15,.45,.8,2.0)
# Find a clean impact onset within the labelled Impacts and Hits section.
hits=decode(1800,24)
envelope=np.max(np.abs(hits),axis=1)
peak_index=int(np.argmax(envelope))
start=max(0,peak_index-int(.045*RATE))
attack=hits[start:start+int(2.5*RATE)]
write('pack_backstab',attack,1800+start/RATE,len(attack)/RATE,.68,.004,.45)
death_window=decode(1840,40)
death_peak=int(np.argmax(np.max(np.abs(death_window),axis=1)))
death_start=max(0,min(death_peak-int(.025*RATE),len(death_window)-int(3.6*RATE)))
death=death_window[death_start:death_start+int(3.6*RATE)]
write('pack_death',death,1840+death_start/RATE,3.6,.55,.01,.7)
(ROOT/'work/audio09/edits.json').write_text(json.dumps(reports,indent=2),encoding='utf8')
print(json.dumps(reports,indent=2))
