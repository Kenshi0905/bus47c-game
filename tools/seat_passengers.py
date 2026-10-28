"""Create editable seated variants from the original static glTF mesh parts."""
import json,base64,struct,pathlib,math
root=pathlib.Path('game/assets/characters')
for source in ['01_grinning_clerk','03_long_neck_worker','04_crooked_passenger']:
 d=json.loads((root/(source+'.gltf')).read_text()); raw=bytearray(base64.b64decode(d['buffers'][0]['uri'].split(',')[1]))
 for mesh in d['meshes']:
  name=mesh['name'];p=mesh['primitives'][0];a=d['accessors'][p['attributes']['POSITION']];view=d['bufferViews'][a['bufferView']];off=view.get('byteOffset',0)+a.get('byteOffset',0)
  points=[]
  for i in range(a['count']):
   x,y,z=struct.unpack_from('<fff',raw,off+i*12)
   if 'trouser' in name:
    if y>.5:z-=max(0,.95-y);y=.45+(y-.95)*.035
    else:y-=.05;z-=.45
   elif name=='leather_shoe':y-=.04;z-=.45
   elif name in ['left_sleeve','right_sleeve','hand','thumb','cuff']:
    if y<1.18:z-=(1.18-y)*.9;y=.68-(1.18-y)*.3
    else:y-=.5
   elif name in ['briefcase','handle_upright','handle_top','case_clasp']:y-=.22;x-=.08;z+=.08
   else:y-=.5
   points.append((x,y,z));struct.pack_into('<fff',raw,off+i*12,x,y,z)
  a['min']=[min(v[j] for v in points) for j in range(3)];a['max']=[max(v[j] for v in points) for j in range(3)]
  normal=d['accessors'][p['attributes']['NORMAL']];nv=d['bufferViews'][normal['bufferView']];no=nv.get('byteOffset',0)
  for i in range(0,len(points),3):
   a0,b,c=points[i:i+3];u=[b[j]-a0[j] for j in range(3)];v=[c[j]-a0[j] for j in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];l=math.sqrt(sum(t*t for t in n));n=[t/max(l,1e-8) for t in n]
   for j in range(3):struct.pack_into('<fff',raw,no+(i+j)*12,*n)
 d['buffers'][0]['uri']='data:application/octet-stream;base64,'+base64.b64encode(raw).decode()
 (root/(source+'_seated.gltf')).write_text(json.dumps(d))
 print(source,'seated')
