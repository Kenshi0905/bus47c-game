"""Short, filtered heel/toe impacts; six variants per surface, no tonal beep."""
import numpy as np,wave,pathlib
root=pathlib.Path('game/assets/audio');rate=22050;rng=np.random.default_rng(4702)
for surface in ['gravel','bus']:
 for i in range(6):
  t=np.arange(int(rate*.32))/rate;n=rng.normal(size=len(t));low=np.convolve(n,np.ones(28)/28,'same')
  heel=np.exp(-t*42)*(1-np.exp(-t*220));toe=np.exp(-np.maximum(t-.075,0)*38)*(t>.075)
  signal=low*(heel+toe*.42)*(.7 if surface=='bus' else .52)
  if surface=='gravel':signal+=np.convolve(n,np.ones(4)/4,'same')*(heel+toe)*.045
  else:signal+=np.convolve(n,np.ones(90)/90,'same')*np.exp(-t*19)*.19
  signal*=np.minimum(t/.004,1)*np.minimum((.32-t)/.025,1)
  assert np.max(np.abs(signal))<.9
  with wave.open(str(root/f'step_{surface}_{i}.wav'),'wb') as f:
   f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((signal*32767).astype('<i2').tobytes())
print('12 soft heel/toe footstep variants generated')
