"""Cut user-supplied footstep references into movement-triggered one-shots.
Input WAVs are local work files; attribution is recorded in docs/audio-sources.md.
"""
import wave,json,pathlib
import numpy as np
rate=22050;root=pathlib.Path('game/assets/audio');report={}
def read(path):
 with wave.open(path) as f:return np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
def write(path,x):
 with wave.open(str(path),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((np.clip(x,-.9,.9)*32767).astype('<i2').tobytes())
for source,surface in [('slow','bus'),('reference','gravel')]:
 x=read('work/footstep-'+source+'.wav');hop=220
 env=np.sqrt(np.mean(x[:len(x)//hop*hop].reshape(-1,hop)**2,axis=1));chosen=[]
 for index in np.argsort(env)[::-1]:
  if env[index]<env.max()*.15:break
  if index<5 or index>len(env)-20:continue
  if all(abs(index-other)>40 for other in chosen):chosen.append(int(index))
  if len(chosen)>=6:break
 chosen.sort();assert len(chosen)>=3
 for i in range(6):
  center=chosen[i%len(chosen)]*hop;start=max(0,center-int(.055*rate));end=min(len(x),center+int(.28*rate));clip=x[start:end].copy()
  clip-=np.convolve(clip,np.ones(440)/440,'same')
  if surface=='bus':clip=np.convolve(clip,np.ones(5)/5,'same')
  clip*=.34/max(np.max(np.abs(clip)),.001)
  fade=min(160,len(clip)//4);clip[:fade]*=np.linspace(0,1,fade);clip[-fade:]*=np.linspace(1,0,fade)
  write(root/f'step_{surface}_{i}.wav',clip)
 report[source]={'centers_seconds':[round(c*hop/rate,3) for c in chosen],'source_duration':len(x)/rate}
# Original impact bed for the deer collision, with a short brake release.
t=np.arange(int(rate*1.2))/rate;rng=np.random.default_rng(47);n=rng.normal(size=len(t));low=np.convolve(n,np.ones(140)/140,'same')
impact=low*np.exp(-t*8)*1.5+n*.035*np.exp(-np.maximum(t-.2,0)*4)*(t>.2)
impact[:110]*=np.linspace(0,1,110);impact[-400:]*=np.linspace(1,0,400);write(root/'impact.wav',impact)
pathlib.Path('work/footstep-edit-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
