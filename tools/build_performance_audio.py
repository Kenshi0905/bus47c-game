"""Offline processing for the placeholder spoken performance and choking cue.

Voice masters are produced with tools/record_placeholder_voice.ps1. Replace them
with actor recordings before the final release without changing gameplay hooks.
"""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'game/assets/audio'
def save(name, data, rate):
    data = np.clip(data, -0.95, .95)
    with wave.open(str(OUT / name), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate)
        f.writeframes((data * 32767).astype('<i2').tobytes())

def voice(name, level):
    with wave.open(str(ROOT / 'work/voice-masters' / name), 'rb') as f:
        rate=f.getframerate(); channels=f.getnchannels()
        data=np.frombuffer(f.readframes(f.getnframes()),'<i2').astype(float)/32768
        data=data.reshape(-1,channels).mean(axis=1)
    # Close, restrained speech, softened consonants and no room echo.
    filtered=np.convolve(data,np.ones(5)/5,mode='same')
    peak=max(.01,np.max(np.abs(filtered)))
    save(name,filtered/peak*level,rate)

if __name__ == '__main__':
    voice('firewatcher_intro.wav',.46)
    voice('hunger_mumble.wav',.28)
    rate=22050; t=np.arange(rate*6)/rate
    rng=np.random.default_rng(47013)
    breath=np.convolve(rng.normal(0,1,len(t)),np.ones(9)/9,mode='same')
    envelope=sum(np.exp(-((t-c)/w)**2) for c,w in [(.15,.14),(.7,.2),(1.3,.19),(2.1,.27),(3.2,.35),(4.5,.45)])
    throat=np.sin(2*np.pi*(74*t+2*np.sin(t*10)))*(.5+.5*np.sin(t*29))
    save('choke.wav',(breath*.44+throat*.13)*envelope*(1-t/6),rate)
