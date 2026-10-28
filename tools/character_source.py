import os,json,math,struct,base64,zipfile,shutil
import numpy as np
from PIL import Image,ImageDraw,ImageFont
OUT=os.path.abspath('outputs'); DEST=os.path.join(OUT,'Bus47C_passengers_v2');os.makedirs(DEST,exist_ok=True)
C={'shirt':(137,158,163),'crease':(101,120,124),'pants':(35,37,40),'shoe':(25,23,23),'skin':(164,139,113),'skinlight':(181,157,130),'socket':(90,78,69),'eye':(187,184,158),'pupil':(39,39,33),'hair':(66,57,46),'lip':(112,80,68),'bag':(39,35,30),'metal':(132,127,108),'tie':(162,24,23),'collar':(175,183,174)}
parts=[]
def mesh(n,v,f,c):parts.append((n,np.array(v,float),f,c))
def rings(n,rs,c,N=8):
 v=[]
 for y,x,z,rx,rz in rs:
  for i in range(N):
   a=2*math.pi*i/N;v.append([x+rx*math.cos(a),y,z+rz*math.sin(a)])
 f=[list(range(N-1,-1,-1))]
 for j in range(len(rs)-1):
  for i in range(N):f.append([j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i])
 f.append(list(range((len(rs)-1)*N,len(rs)*N)))
 # rings use x/z orientation; reverse to outward
 mesh(n,v,[list(reversed(a)) for a in f],c)
def box(n,p,s,c):
 x,y,z=p;a,b,d=np.array(s)/2
 mesh(n,[[x-a,y-b,z-d],[x+a,y-b,z-d],[x+a,y+b,z-d],[x-a,y+b,z-d],[x-a,y-b,z+d],[x+a,y-b,z+d],[x+a,y+b,z+d],[x-a,y+b,z+d]],[[0,3,2,1],[4,5,6,7],[0,1,5,4],[3,7,6,2],[0,4,7,3],[1,2,6,5]],c)
def make(kind):
 global parts
 parts=[];tall=kind==2;stretch=1.12 if tall else 1
 for sign in [-1,1]:
  x=sign*.105
  rings(('L' if sign<0 else 'R')+'_trouser',[(.09,x,0,.055,.065),(.23,x,.012,.057,.065),(.5,x,.018,.065,.071),(.76,x,0,.079,.085),(.96,x,0,.09,.095)],'pants')
  rings('leather_shoe',[(.025,x,-.065,.065,.135),(.07,x,-.07,.07,.14),(.12,x,-.025,.056,.085)],'shoe')
 rings('pelvis',[(.86,0,0,.18,.105),(1.01,0,0,.178,.1)],'pants')
 rings('shirt_torso',[(.99,0,0,.17,.1),(1.08,0,.008,.178,.116),(1.26,0,.008,.205,.12),(1.43,0,.008,.223,.105),(1.48,0,.008,.17,.09)],'pants' if tall else 'shirt',12)
 for sign in [-1,1]:
  rings(('left' if sign<0 else 'right')+'_sleeve',[(.83,sign*.265,-.015,.043,.043),(1.01,sign*.267,.01,.048,.05),(1.18,sign*.255,.015,.065,.067),(1.4,sign*.205,.01,.078,.08)],'pants' if tall else 'shirt')
  rings('cuff',[(.82,sign*.265,-.015,.044,.047),(.87,sign*.265,-.012,.045,.048)],'collar')
  rings('hand',[(.68,sign*.27,-.02,.035,.024),(.72,sign*.273,-.035,.044,.032),(.81,sign*.268,-.02,.042,.032),(.84,sign*.265,-.015,.029,.028)],'skin')
  rings('thumb',[(.74,sign*.231,-.055,.017,.018),(.79,sign*.229,-.046,.019,.02)],'skin',6)
 rings('neck',[(1.43,0,.012,.065,.062),(1.57,0,.005,.063,.065)],'skin')
 rings('head',[(1.52,0,-.024,.051,.052),(1.55,0,-.01,.073,.071),(1.63,0,0,.089,.083),(1.72,0,.008,.087,.079),(1.79,0,.012,.071,.067),(1.81,0,.012,.04,.04)],'skinlight',12)
 for sign in [-1,1]:rings('ear',[(1.61,sign*.09,.005,.012,.02),(1.68,sign*.092,.005,.016,.024),(1.7,sign*.086,.005,.01,.017)],'skin',6)
 # Folded triangular collar and front placket.
 for sign in [-1,1]:mesh('collar_leaf',[[sign*.015,1.49,-.065],[sign*.085,1.475,-.075],[sign*.09,1.395,-.108],[sign*.025,1.43,-.12]],[[0,1,2],[0,2,3]],'collar')
 if tall:
  mesh('red_tie',[[0,1.44,-.125],[-.026,1.4,-.126],[-.027,1.15,-.13],[0,1.105,-.13],[.027,1.15,-.13],[.026,1.4,-.126]],[[0,1,5],[1,2,5],[2,4,5],[2,3,4]],'tie')
 else:
  box('shirt_placket',(0,1.23,-.114),(.018,.36,.008),'crease')
  for y in [1.11,1.22,1.33]:box('button',(0,y,-.122),(.008,.008,.005),'metal')
  # Receding horseshoe hair leaves the forehead bare.
  rings('hair_back',[(1.68,0,.055,.087,.035),(1.76,0,.045,.079,.045),(1.795,0,.025,.06,.048)],'hair',10)
  for sign in [-1,1]:box('temple_hair',(sign*.081,1.713,.004),(.014,.065,.065),'hair')
  for sign in [-1,1]:
   x=sign*.035; ey=1.684+(0.003*sign if kind==1 else 0)
   box('eye_socket',(x,ey,-.074),(.046,.026,.011),'socket')
   box('eye',(x,ey,-.081),(.032,.012 if kind==0 else .018,.006),'eye')
   box('pupil',(x+(.004 if kind==1 else 0),ey,-.085),(.009,.011,.003),'pupil')
   box('brow',(x,ey+.024,-.074),(.043,.008,.008),'hair')
  mesh('nose',[[-.013,1.681,-.078],[.013,1.681,-.078],[.018,1.63,-.084],[0,1.626,-.113],[-.018,1.63,-.084]],[[0,1,3],[1,2,3],[0,3,4]],'skin')
  box('mouth',(0,1.588,-.077),(.047 if kind==0 else .071,.006,.006),'lip')
  # Briefcase plus open handle, all separately editable.
  box('briefcase',(-.29,.42,-.018),(.32,.37,.095),'bag')
  for x in [-.35,-.23]:box('handle_upright',(x,.66,-.018),(.016,.12,.018),'bag')
  box('handle_top',(-.29,.716,-.018),(.135,.018,.018),'bag')
  for x in [-.38,-.2]:box('case_clasp',(x,.601,-.069),(.025,.025,.008),'metal')
 if tall:
  parts=[(n,v*np.array([.88,stretch,.9]),f,c) for n,v,f,c in parts]
 if kind==1:
  parts=[(n,v+np.array([.015 if n in ['head','ear','hair_back','temple_hair','eye','eye_socket','pupil','brow','nose','mouth'] else 0,0,0]),f,c) for n,v,f,c in parts]
 return parts
def export(name,ps):
 binary=bytearray();views=[];access=[];meshes=[];nodes=[];mats=list(C);obj=['mtllib palette.mtl'];off=1;triangles=[]
 def data(a):
  a=np.asarray(a,dtype='<f4');views.append({'buffer':0,'byteOffset':len(binary),'byteLength':a.nbytes});binary.extend(a.tobytes());access.append({'bufferView':len(views)-1,'componentType':5126,'count':len(a),'type':'VEC3','min':a.min(0).tolist(),'max':a.max(0).tolist()});return len(access)-1
 for k,(n,v,fs,c) in enumerate(ps):
  pos=[];norm=[];obj+=['o '+n+'_'+str(k),'usemtl '+c]+['v '+' '.join(map(str,p)) for p in v]
  for face in fs:
   obj.append('f '+' '.join(str(off+i) for i in face))
   for j in range(1,len(face)-1):
    q=v[[face[0],face[j],face[j+1]]];normal=np.cross(q[1]-q[0],q[2]-q[0]);normal/=max(np.linalg.norm(normal),1e-9);pos.extend(q);norm.extend([normal]*3);triangles.append((q,c,normal))
  off+=len(v);a=data(pos);b=data(norm);meshes.append({'name':n,'primitives':[{'attributes':{'POSITION':a,'NORMAL':b},'material':mats.index(c)}]});nodes.append({'name':n+'_'+str(k),'mesh':k})
 materials=[{'name':c,'doubleSided':True,'pbrMetallicRoughness':{'baseColorFactor':[x/255 for x in C[c]]+[1],'metallicFactor':0,'roughnessFactor':.88}} for c in mats]
 g={'asset':{'version':'2.0'},'scene':0,'scenes':[{'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':meshes,'materials':materials,'buffers':[{'byteLength':len(binary),'uri':'data:application/octet-stream;base64,'+base64.b64encode(binary).decode()}],'bufferViews':views,'accessors':access}
 json.dump(g,open(os.path.join(DEST,name+'.gltf'),'w'));open(os.path.join(DEST,name+'.obj'),'w').write('\n'.join(obj));return triangles
def render(tris,w,h,angle=0,head=False):
 im=Image.new('RGB',(w,h),(30,37,39));d=ImageDraw.Draw(im);a=math.radians(angle);right=np.array([math.cos(a),0,math.sin(a)]);up=np.array([-.08*math.sin(a),.997,.08*math.cos(a)]);dep=np.cross(up,right)
 scale=h/(.48 if head else 2.25);cy=(max(float(q[:,1].max()) for q,c,n in tris)-.15) if head else .95
 light=np.array([-.4,.6,-.7]);light/=np.linalg.norm(light)
 for q,c,n in sorted(tris,key=lambda t:float(t[0].mean(0)@dep)):
  pts=[(w/2+(p@right)*scale,h/2-(p@up-cy)*scale) for p in q];shade=.48+.52*max(0,float(n@light));rgb=tuple(int(x*shade) for x in C[c]);d.polygon(pts,fill=rgb)
 return im
# Appended to the reusable mesh construction/export functions.
DEST=os.path.join(OUT,'Bus47C_passengers_v3');os.makedirs(DEST,exist_ok=True)
C.update({'bone':(191,188,154),'void':(26,28,28),'mourning':(57,60,58),'ochre':(121,106,70),'rust':(112,68,57),'soot':(67,69,63),'olive':(83,100,79),'bruise':(101,105,94),'greyhair':(112,111,98)})
HEAD={'head','ear','hair_back','temple_hair','eye','eye_socket','pupil','brow','nose','mouth'}
def remove(names):
 global parts
 parts=[p for p in parts if p[0] not in names]
def transform(names,fn):
 global parts
 parts=[(n,fn(v.copy()),f,c) if n in names else (n,v,f,c) for n,v,f,c in parts]
def recolor(names,color):
 global parts
 parts=[(n,v,f,color if n in names else c) for n,v,f,c in parts]
def face_patch(name,x,y,rx,ry,color,z=-.089):
 v=[[x+rx*math.cos(a),y+ry*math.sin(a),z] for a in np.linspace(0,2*math.pi,8,endpoint=False)]
 mesh(name,v,[list(range(8))],color)
def eyes(hollow=False):
 remove({'eye','eye_socket','pupil','brow'})
 for sign in [-1,1]:
  x=sign*.036;y=1.68+(.005 if sign<0 else -.003)
  face_patch('deep_eye_socket',x,y,.029,.023,'void')
  if not hollow:
   face_patch('fixed_eye',x,y,.018,.014,'bone',-.091)
   face_patch('pinpoint_pupil',x+.003,y,.004,.007,'void',-.093)
def variant(i):
 global parts
 make(2 if i==5 else 0)
 if i==0:
  eyes();remove({'mouth'});face_patch('impossible_grin',0,1.591,.069,.021,'void',-.088)
  for j in range(9):box('grin_tooth',(-.052+j*.013,1.597,-.091),(.009,.012,.004),'bone')
  recolor({'skinlight'},'skinlight')
 elif i==1:
  remove({'briefcase','handle_upright','handle_top','case_clasp','hair_back','temple_hair','mouth','shirt_placket','button'})
  recolor({'shirt_torso','left_sleeve','right_sleeve','cuff','collar_leaf'},'mourning');recolor({'head','neck','hand','ear'},'bone')
  rings('long_skirt',[(.13,0,0,.245,.15),(.43,0,0,.215,.14),(.8,0,0,.185,.12),(1.02,0,0,.17,.11)],'mourning',12)
  rings('hair_crown',[(1.735,0,.03,.094,.075),(1.79,0,.02,.08,.075),(1.825,0,.02,.045,.04)],'greyhair',12)
  for s in [-1,1]:rings('hanging_hair',[(1.37,s*.105,.025,.028,.05),(1.63,s*.098,.025,.026,.065),(1.77,s*.077,.025,.03,.057)],'greyhair')
  eyes(True);face_patch('sealed_mouth',0,1.587,.032,.004,'bruise',-.082)
 elif i==2:
  remove({'briefcase','handle_upright','handle_top','case_clasp'});recolor({'shirt_torso','left_sleeve','right_sleeve'},'ochre')
  eyes();transform(HEAD|{'deep_eye_socket','fixed_eye','pinpoint_pupil'},lambda v:v+np.array([0,.14,0]))
  transform({'neck'},lambda v:np.column_stack((v[:,0]*.8,1.43+(v[:,1]-1.43)*2.1,v[:,2])))
  rings('work_cap',[(1.92,0,.014,.092,.084),(1.97,0,.014,.085,.077),(1.99,0,.014,.04,.04)],'olive',12)
  box('cap_brim',(0,1.928,-.08),(.2,.012,.1),'olive')
  transform({'left_sleeve','right_sleeve','hand','thumb','cuff'},lambda v:np.column_stack((v[:,0],1.4+(v[:,1]-1.4)*1.16,v[:,2])))
 elif i==3:
  remove({'briefcase','handle_upright','handle_top','case_clasp'});recolor({'shirt_torso','left_sleeve','right_sleeve'},'rust');eyes(True)
  remove({'mouth'});face_patch('open_mouth',0,1.588,.021,.032,'void',-.09)
  ang=math.radians(24);r=np.array([[math.cos(ang),-math.sin(ang),0],[math.sin(ang),math.cos(ang),0],[0,0,1]])
  transform(HEAD|{'deep_eye_socket','open_mouth'},lambda v:(v-np.array([0,1.49,0]))@r.T+np.array([0,1.49,0]))
  transform({'shirt_torso','left_sleeve','right_sleeve'},lambda v:np.column_stack((v[:,0],v[:,1]+.07*v[:,0],v[:,2])))
 elif i==4:
  recolor({'shirt_torso','left_sleeve','right_sleeve'},'soot');recolor({'head','neck','hand','ear'},'bruise');eyes();remove({'mouth'})
  face_patch('downturned_mouth',0,1.588,.034,.006,'void',-.083)
  for j in range(5):box('soot_mark',(-.12+j*.06,1.23+(j%2)*.08,-.122),(.028,.16,.006),'void')
  for sign in [-1,1]:box('tear_streak',(sign*.036,1.643,-.085),(.008,.052,.005),'void')
  transform({'head','ear','hair_back','temple_hair','nose','deep_eye_socket','fixed_eye','pinpoint_pupil','downturned_mouth','tear_streak'},lambda v:np.column_stack((v[:,0]*.9,v[:,1],v[:,2]-.024)))
 else:
  transform({'head','ear'},lambda v:np.column_stack((v[:,0]*.8,1.72+(v[:,1]-1.72)*1.16,v[:,2])))
  transform({'left_sleeve','right_sleeve','hand','thumb','cuff'},lambda v:np.column_stack((v[:,0],1.57+(v[:,1]-1.57)*1.25,v[:,2])))
  recolor({'head','neck','hand','ear'},'bone')
 return parts
font=lambda s:ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',s)
names=['01_grinning_clerk','02_hollow_widow','03_long_neck_worker','04_crooked_passenger','05_ash_commuter','06_faceless_watcher']
sheet=Image.new('RGB',(1800,2240),(18,25,28));d=ImageDraw.Draw(sheet);d.text((35,20),'BUS 47C / THE LATE PASSENGERS',font=font(34),fill='#e3ddce');d.text((37,68),'Six editable models - actual geometry previews',font=font(21),fill='#a3b0af')
manifest=[]
for i,name in enumerate(names):
 ps=variant(i);tris=export(name,ps);x=30+(i%3)*590;y=110+(i//3)*1055
 im=render(tris,560,700,12);sheet.paste(im,(x,y));sheet.paste(render(tris,560,255,0,True),(x,y+710));d.text((x+10,y+975),name[3:].replace('_',' ').upper(),font=font(24),fill='#e3ddce');d.text((x+10,y+1010),str(len(tris))+' triangles | '+str(len(ps))+' editable parts',font=font(18),fill='#a3b0af');im.save(os.path.join(DEST,name+'_preview.png'));manifest.append({'model':name,'triangles':len(tris),'parts':len(ps)})
sheet.save(os.path.join(OUT,'Bus47C_passengers_v3_preview.png'))
open(os.path.join(DEST,'palette.mtl'),'w').write('\n'.join('newmtl '+c+'\nKd '+' '.join(str(v/255) for v in C[c]) for c in C))
json.dump(manifest,open(os.path.join(DEST,'manifest.json'),'w'),indent=2)
open(os.path.join(DEST,'EDITING.txt'),'w').write('BUS 47C PASSENGERS V3\nSix original low-poly static characters with separate named mesh parts.\nBlender: File > Import > glTF 2.0, choose a .gltf, then save as .blend. Materials and all features are editable. OBJ + palette.mtl is a fallback. Units: metres. Y up, facing -Z.\nNo skeletons, animation, collisions or UV textures yet. Parts overlap at joints; suitable for visual prototypes and further modelling. Face patches are deliberate separate geometry and can be moved or removed. Materials are double-sided to support these patches.\nSuggested progression: introduce the ash commuter subtly, then the worker, crooked passenger, widow and grinning clerk. Keep the red-tie watcher outside the bus. Avoid showing every distortion immediately.\nSource builder included; requires Python, NumPy and Pillow. Creates previews and model exports under outputs.\n')
shutil.copy(__file__,os.path.join(DEST,'build_passengers_v3.py'))
with zipfile.ZipFile(os.path.join(OUT,'Bus47C_passengers_v3.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for f in os.listdir(DEST):z.write(os.path.join(DEST,f),'Bus47C_passengers_v3/'+f)
print(json.dumps(manifest))

