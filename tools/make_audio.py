"""Original synthesized prototype sound effects. No external recordings."""
import numpy as np,wave,os
rng=np.random.default_rng(47); rate=22050
root='game/assets/audio';os.makedirs(root,exist_ok=True)
def save(name,a):
 a=np.clip(a,-.85,.85)
 with wave.open(root+'/'+name+'.wav','wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((a*32767).astype('<i2').tobytes())
def time(n):return np.arange(int(rate*n))/rate
t=time(8); noise=rng.normal(0,1,len(t)); smooth=np.convolve(noise,np.ones(100)/100,'same')
save('forest',smooth*.23+np.sin(2*np.pi*2800*t)*(.5+.5*np.sin(2*np.pi*.75*t))**14*.012)
save('engine',.12*np.sin(2*np.pi*48*t)+.045*np.sin(2*np.pi*96*t)+smooth*.15)
save('drone',.06*np.sin(2*np.pi*73*t)+.04*np.sin(2*np.pi*74*t)+.025*np.sin(2*np.pi*109.5*t))
t=time(1.4);save('door',rng.normal(0,.1,len(t))*np.exp(-t*3)+.16*np.sin(2*np.pi*(100*t-25*t*t))*np.exp(-t*5)+.13*np.exp(-((t-1.1)/.035)**2)*rng.normal(0,1,len(t)))
t=time(.25);save('step',rng.normal(0,.08,len(t))*np.exp(-t*22)+.08*np.sin(2*np.pi*95*t)*np.exp(-t*25))
t=time(2.5);save('chime',(.12*np.sin(2*np.pi*550*t)+.06*np.sin(2*np.pi*825*t))*np.exp(-t*2))
print('Generated six original audio clips')
