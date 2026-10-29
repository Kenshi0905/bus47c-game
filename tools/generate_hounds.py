"""Generate the original deterministic hell-hound cue used in Beta 0.11."""
from pathlib import Path
import math, random, wave, struct
root=Path(__file__).resolve().parents[1]
rng=random.Random(4711)
rate=22050
data=[]
last=0
for n in range(rate*9):
    t=n/rate
    last=last*.72+rng.uniform(-1,1)*.28
    env=min(1,t*3)*min(1,(9-t)*2)*(.35+.65*abs(math.sin(t*2.7)))
    growl=math.sin(2*math.pi*(58*t+3*math.sin(t*1.3)))
    growl+=.4*math.sin(2*math.pi*119*t)*(.6+.4*math.sin(t*37))
    sample=math.tanh((growl*.28+last*.8)*env)
    data.append(struct.pack('<h',int(sample*21000)))
with wave.open(str(root/'game/assets/audio/hell_hounds.wav'),'wb') as out:
    out.setparams((1,2,rate,0,'NONE','not compressed'))
    out.writeframes(b''.join(data))
