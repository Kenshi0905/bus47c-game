import math,random,wave,struct
from pathlib import Path
sr=22050
rng=random.Random(4706)
lengths={'stall':2.1,'rustle':1.4,'mirror':2.5,'dig':2.0,'knock':2.6,'cry':3.2,'pursuit':2.2,'pour':1.7,'birds':5.5,'ambush':.85,'stomach':3.1,'watcher_veil':2.6}
for name,duration in lengths.items():
 samples=[];low=0
 for i in range(int(sr*duration)):
  t=i/sr;n=rng.uniform(-1,1);low=low*.92+n*.08
  if name=='stall':s=(math.sin(2*math.pi*(65*t-11*t*t))*.45+low)*math.exp(-t*1.7)*(1 if int(t*12)%3 else .25)
  elif name=='rustle':s=(n-low)*.18*math.sin(math.pi*t/duration)**2*(.55+.45*math.sin(t*19))
  elif name=='mirror':s=sum(math.sin(2*math.pi*f*t)*math.exp(-t*(1+j*.5)) for j,f in enumerate([185,277.3,391.7]))*.1
  elif name=='dig':s=n*.14*sum(math.exp(-max(0,t-b)*14) if t>=b else 0 for b in [.1,.7,1.3])
  elif name=='knock':s=sum((math.sin(2*math.pi*82*(t-b))*.4+low*.4)*math.exp(-(t-b)*24) if t>=b else 0 for b in [.1,.38,1.5])
  elif name=='cry':s=(math.sin(2*math.pi*(178*t+18*math.sin(t*1.6)))+.3*math.sin(2*math.pi*560*t))*.075*math.sin(math.pi*t/duration)**2
  elif name=='pursuit':s=sum((low*.9+math.sin(2*math.pi*70*(t-b))*.18)*math.exp(-(t-b)*18) if t>=b else 0 for b in [.1,.72,1.37,2.0])
  elif name=='pour':s=(n-low)*.09*math.sin(math.pi*t/duration)**2+math.sin(t*(3400+650*t))*.025
  elif name=='ambush':s=(low*.7+math.sin(2*math.pi*(190*t+95*t*t))*.18+math.sin(2*math.pi*317*t)*.12)*min(1,t*90)*math.exp(-t*4)
  elif name=='stomach':
   envelope=math.sin(math.pi*t/duration)**2*(.55+.45*math.sin(t*9+math.sin(t*4)))
   s=(math.sin(2*math.pi*(49*t+1.4*math.sin(t*7)))*.19+low*.48+math.sin(t*560)*.035)*envelope
  elif name=='watcher_veil':
   envelope=min(1,t*12)*math.exp(-t*1.7)
   s=(low*.6+(n-low)*.09+math.sin(2*math.pi*(210*t-20*t*t))*.055)*envelope
  else:
   s=0
   for b in [.1,.7,1.5,2.4,3.6,4.5]:
    dt=t-b
    if 0<=dt<.32:s+=math.sin(2*math.pi*(1800*dt+1800*dt*dt))*.09*math.sin(math.pi*dt/.32)**2
  samples.append(max(-.5,min(.5,s)))
 with wave.open(str(Path('game/assets/audio')/(name+'.wav')),'wb') as out:
  out.setparams((1,2,sr,0,'NONE','not compressed'))
  out.writeframes(b''.join(struct.pack('<h',int(s*32767)) for s in samples))
