extends Node3D
## Editable low-poly district. All three shop doors open into real interiors.
const AGED=preload("res://assets/ui/aged_surface.gdshader")
var game
var after
var shops: Dictionary={}
var materials: Dictionary={}
const DOCUMENTS={
	"shop_pizza":["LAST ORDER","MORROW'S PIZZA\n\nCollection for House 17.\nOne customer. Six place settings.\n\nThe order was paid at 02:36.\n\nPlease stop calling. We can hear the phone ringing inside your house."],
	"shop_diner":["NIGHT SHIFT","NIGHT OWL DINER\n\nLeave the booth by the window empty.\n\nIf the last bus stops outside, turn off the coffee machine. Do not count the passengers.\n\nSomeone has crossed out every date on the rota."],
	"shop_mart":["DELIVERY RECORD","47 MART\n\nMilk. Bread. Batteries.\n\nThe driver left the same boxes again. Everything inside expires yesterday.\n\nThere is a bus ticket tucked beneath the receipt. The destination has been rubbed away."]
}

func setup(g, a, home: Node3D) -> void:
	game=g
	after=a
	name="LoomesvilleDistrict"
	street()
	shop("pizza",Vector3(101,0,-742),PI/2,"MORROW'S PIZZA","8e3028")
	shop("diner",Vector3(139,0,-742),-PI/2,"NIGHT OWL DINER","7d4c32")
	shop("mart",Vector3(139,0,-714),-PI/2,"47 MART","41645a")
	for item in [[Vector3(97,0,-702),0],[Vector3(83,0,-702),0],[Vector3(155,0,-702),0],[Vector3(101,0,-766),PI/2],[Vector3(139,0,-766),-PI/2],[Vector3(151,0,-788),0],[Vector3(88,0,-789),0]]:
		terrace(item[0],item[1])
	home_details(home)

func aged(mesh: MeshInstance3D, color: String, kind: int) -> MeshInstance3D:
	var key := color+str(kind)
	if not materials.has(key):
		var material := ShaderMaterial.new()
		material.shader=AGED
		material.set_shader_parameter("base",Color(color))
		material.set_shader_parameter("kind",kind)
		materials[key]=material
	mesh.material_override=materials[key]
	return mesh

func box(parent: Node3D, at: Vector3, size: Vector3, color: String, solid: bool=false, kind: int=0) -> MeshInstance3D:
	return aged(game.block(parent,at,size,color,solid),color,kind)

func lettering(parent: Node3D, copy: String, at: Vector3, size: float, color: String="d1c7a0") -> Label3D:
	var label: Label3D=game.text3(parent,copy,at,48,Color(color))
	label.font=game.MENU_FONT
	label.pixel_size=size
	label.outline_size=0
	return label

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius
	shape.height=height
	shape.radial_segments=10
	node.mesh=shape
	node.material_override=game.mat(color)
	parent.add_child(node)
	node.position=at
	return node

func street() -> void:
	box(self,Vector3(120,.018,-715),Vector3(85,.036,8),"343735",false,4)
	for z in [-709.7,-720.3]:box(self,Vector3(120,.025,z),Vector3(85,.05,2.5),"6a685b",true,3)
	for z in range(-784,-704,5):
		if z< -721 or z> -709:box(self,Vector3(120,.041,z),Vector3(.13,.01,2.4),"a7a08a")
	for x in [115.65,124.35]:
		for dx in [-.13,.13]:box(self,Vector3(x+dx,.043,-751),Vector3(.07,.01,61),"9f7b38")
	for z in [-735,-754,-774]:
		for x in [112.5,127.5]:
			box(self,Vector3(x,2.5,z),Vector3(.12,5,.12),"343e39",true)
			box(self,Vector3(x,5,z),Vector3(1.2,.1,.1),"404741")
			game.block(self,Vector3(x,4.9,z),Vector3(.65,.05,.28),"b9a275",false,true)
			game.light(self,Vector3(x,4.6,z),Color("cfb780"),1.2,13)
	for z in [-704,-727,-752,-791]:
		box(self,Vector3(130,3.6,z),Vector3(.19,7.2,.19),"62503d",true,2)
		box(self,Vector3(130,6.7,z),Vector3(3,.14,.12),"514c40")
		if z> -791:
			for x in [129,130,131]:
				var wire: MeshInstance3D=game.block(self,Vector3(x,6.6,z-12.2),Vector3(.025,.025,24.4),"171d1b")
				wire.rotation.x=.006
	car(Vector3(126.5,0,-730),.05,"542923")
	car(Vector3(112.9,0,-753),PI,"405454")
	# The golden path joins the pavement between the western buildings.
	box(self,Vector3(165,1,-751),Vector3(.2,2,104),"303d31",true,2)
	box(self,Vector3(77,1,-780),Vector3(.2,2,54),"303d31",true,2)
	box(self,Vector3(121,1,-807),Vector3(88,2,.2),"303d31",true,2)

func car(at: Vector3, yaw: float, color: String) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position=at
	root.rotation.y=yaw
	box(root,Vector3(0,.65,0),Vector3(1.7,.65,4),color,true)
	box(root,Vector3(0,1.17,.15),Vector3(1.5,.6,1.9),"182b2b",true)
	box(root,Vector3(0,1.51,.15),Vector3(1.58,.08,2),color)
	for x in [-.82,.82]:
		for z in [-1.25,1.25]:
			var wheel := cylinder(root,Vector3(x,.4,z),.37,.18,"171c1a")
			wheel.rotation.z=PI/2
	for x in [-.58,.58]:game.block(root,Vector3(x,.7,-2.02),Vector3(.35,.22,.035),"9f9b7d")

func shop(id: String, at: Vector3, yaw: float, title: String, color: String) -> void:
	var root := Node3D.new()
	add_child(root)
	root.name=title.replace(" ","")
	root.position=at
	root.rotation.y=yaw
	shops[id]=root
	box(root,Vector3(0,.025,0),Vector3(12,.05,11),"aba28b",true,3)
	box(root,Vector3(0,3.25,0),Vector3(12,.2,11),"888a78",true,6)
	box(root,Vector3(0,1.6,-5.5),Vector3(12,3.2,.18),color,true,1)
	for x in [-6,6]:box(root,Vector3(x,1.6,0),Vector3(.18,3.2,11),color,true,1)
	# Wide centre entrance. Glass wings and an open hinged door frame it.
	for x in [-3.55,3.55]:
		box(root,Vector3(x,.4,5.5),Vector3(4.9,.8,.18),color,true,1)
		game.glass(root,Vector3(x,1.8,5.5),Vector3(4.8,2,.045))
		for dx in [-2.4,0,2.4]:box(root,Vector3(x+dx,1.85,5.53),Vector3(.08,2.3,.08),"a3a38e",true)
	box(root,Vector3(0,3.12,5.5),Vector3(12,.2,.2),"a3a38e")
	box(root,Vector3(0,3.7,5.55),Vector3(12.4,1,.3),color)
	lettering(root,title,Vector3(0,3.7,5.72),.019)
	for y in [3.26,4.12]:game.block(root,Vector3(0,y,5.75),Vector3(12.2,.055,.05),"d2b378",false,true)
	game.light(root,Vector3(0,3.6,6),Color("d6b58a"),1.4,9)
	var door := Node3D.new()
	root.add_child(door)
	door.position=Vector3(-1.05,0,5.5)
	door.rotation.y=-PI*.47
	for x in [0,2.0]:box(door,Vector3(x,1.45,0),Vector3(.07,2.9,.07),"9c9a85")
	for y in [.07,2.87]:box(door,Vector3(1,y,0),Vector3(2,.07,.07),"9c9a85")
	game.glass(door,Vector3(1,1.45,0),Vector3(1.9,2.75,.035))
	box(door,Vector3(1.8,1.35,.08),Vector3(.035,.42,.035),"b5baa8")
	for x in [-3.4,3.4]:
		game.block(root,Vector3(x,3.08,0),Vector3(2,.045,.28),"c1c9b6",false,true)
		game.light(root,Vector3(x,2.8,0),Color("c0c5a1"),1.4,8)
	# A low counter leaves the centre and side aisles unobstructed.
	box(root,Vector3(0,.52,-3),Vector3(8,1.04,.8),"6e5c48",true,2)
	box(root,Vector3(0,1.08,-3),Vector3(8.2,.12,1),"b1a98e",true)
	box(root,Vector3(2.8,1.32,-3),Vector3(.45,.37,.45),"313e38")
	game.block(root,Vector3(2.8,1.5,-2.76),Vector3(.3,.16,.02),"75a580",false,true)
	box(root,Vector3(0,1.155,-2.8),Vector3(.4,.015,.55),"c9bd98")
	after.hotspot("shop_"+id,root,Vector3(0,1.17,-2.8),"Read the counter note",2.5)
	if id=="pizza":pizza_room(root)
	elif id=="diner":diner_room(root)
	else:mart_room(root)
	# Interior hum is spatial, quiet outside the building.
	var hum := AudioStreamPlayer3D.new()
	root.add_child(hum)
	hum.position=Vector3(0,2,-2)
	hum.stream=load("res://assets/audio/engine.wav")
	hum.volume_db=-32
	hum.max_distance=11
	hum.unit_size=3
	hum.play()

func table(parent: Node3D, at: Vector3, booth: bool=false) -> void:
	box(parent,at+Vector3(0,.78,0),Vector3(1.5,.1,1.1),"a29576",true,2)
	box(parent,at+Vector3(0,.4,0),Vector3(.14,.8,.14),"4d5149",true)
	for side in [-1,1]:
		box(parent,at+Vector3(side*1.05,.43,0),Vector3(.55,.2,1.2 if booth else .55),"723d35",true)
		box(parent,at+Vector3(side*1.28,.8,0),Vector3(.13,.8,1.2 if booth else .55),"65372e",true)
		cylinder(parent,at+Vector3(side*.45,.9,0),.1,.16,"bcb49b")
	box(parent,at+Vector3(0,.9,.3),Vector3(.2,.2,.18),"898a75")

func pizza_room(root: Node3D) -> void:
	for z in [1.2,3.6]:table(root,Vector3(3.7,0,z))
	box(root,Vector3(-3.8,1.1,-4.8),Vector3(2.8,2.2,1.15),"777a6b",true)
	for y in [.7,1.5]:
		box(root,Vector3(-3.8,y,-4.19),Vector3(2.4,.55,.06),"17211e")
		box(root,Vector3(-3.8,y-.12,-4.14),Vector3(1.8,.055,.08),"a5a797")
	for x in [-2,0,1.5]:
		cylinder(root,Vector3(x,1.2,-3),.46,.055,"b48b44")
		for j in range(6):cylinder(root,Vector3(x+sin(j)*.28,1.234,-3+cos(j)*.28),.075,.01,"7c3426")
	for i in range(5):box(root,Vector3(-5,1.18+i*.08,-2.9),Vector3(.8,.07,.8),"9c8a65")
	box(root,Vector3(1.6,2.3,-5.38),Vector3(5.6,1.2,.06),"28342d")
	lettering(root,"HOT PIZZA     LATE COLLECTION\nMARGHERITA    PEPPERONI    HOUSE SPECIAL",Vector3(1.6,2.3,-5.33),.0035)

func diner_room(root: Node3D) -> void:
	for z in [.4,3.2]:
		for x in [-3.7,3.7]:table(root,Vector3(x,0,z),true)
	for x in [-2.5,0,2.5]:
		cylinder(root,Vector3(x,.35,-1.7),.1,.7,"7c8170")
		cylinder(root,Vector3(x,.76,-1.7),.3,.14,"763c32")
	box(root,Vector3(-2,1.5,-4.7),Vector3(1.4,.9,.6),"70786a")
	for x in [-2.4,-1.6]:cylinder(root,Vector3(x,1.95,-4.7),.18,.35,"222e2a")
	lettering(root,"COFFEE ALL NIGHT\nTHE USUAL IS ALREADY ON",Vector3(1.7,2.3,-5.38),.005)
	box(root,Vector3(-5.2,.8,3.8),Vector3(.7,1.6,.65),"745638",true)
	game.block(root,Vector3(-5.2,1.2,4.15),Vector3(.5,.5,.04),"b58b52",false,true)

func mart_room(root: Node3D) -> void:
	for x in [-3,3]:
		for y in [.35,.9,1.45]:
			box(root,Vector3(x,y,1.6),Vector3(1.4,.09,4.4),"929583",true)
			for z in [-.1,.55,1.2,1.85,2.5,3.15]:
				for dx in [-.4,0,.4]:
					cylinder(root,Vector3(x+dx,y+.19,z),.1,.3,["777641","6d4538","4b6d60"][int(absf(z*7))%3])
	for x in [-3.5,-1.2,1.2,3.5]:
		box(root,Vector3(x,1.3,-5.04),Vector3(2.1,2.6,.55),"1d302c",true)
		for y in [.5,1.1,1.7,2.3]:
			box(root,Vector3(x,y,-4.7),Vector3(2,.04,.5),"b1bca6")
			for dx in [-.65,-.2,.25,.7]:cylinder(root,Vector3(x+dx,y+.17,-4.67),.12,.3,"6c856b")
		for dx in [-.98,.98]:game.block(root,Vector3(x+dx,1.4,-4.68),Vector3(.035,2.35,.03),"bed6c8",false,true)
		game.glass(root,Vector3(x,1.4,-4.55),Vector3(1.95,2.35,.025))
		box(root,Vector3(x+.8,1.3,-4.5),Vector3(.04,.55,.05),"b6bcad")
	lettering(root,"COLD DRINKS     FRESH DAILY",Vector3(0,2.9,-5.1),.009)

func terrace(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position=at
	root.rotation.y=yaw
	box(root,Vector3(0,3,0),Vector3(11,6,9),"634d3e",true,1)
	for side in [-1,1]:
		var roof := box(root,Vector3(0,6.45,side*2.35),Vector3(11.6,.16,5),"343d36",false,2)
		roof.rotation.x=side*.28
	box(root,Vector3(3,6.8,-1),Vector3(.8,1.8,.7),"6c5443",false,1)
	for x in [-3.6,0,3.6]:
		for y in [1.8,4.5]:
			box(root,Vector3(x,y,4.56),Vector3(1.6,1.9,.12),"a49a7f")
			game.block(root,Vector3(x,y,4.64),Vector3(1.35,1.65,.03),"9a8755" if x+y>3 else "1a2d2b",false,x+y>3)
			box(root,Vector3(x,y,4.68),Vector3(.05,1.65,.03),"756e5d")
			box(root,Vector3(x,y,4.68),Vector3(1.35,.06,.03),"756e5d")
	box(root,Vector3(0,1.25,4.75),Vector3(1.25,2.5,.18),"484e40")
	for y in [.75,1.7]:box(root,Vector3(0,y,4.86),Vector3(.9,.65,.04),"676b55")
	for x in [-5.5,5.5]:box(root,Vector3(x,3,4.65),Vector3(.08,6,.08),"303d36")

func home_details(home: Node3D) -> void:
	home.name="House17"
	for child in home.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3=child.mesh.size
			if size.y>3:aged(child,"79745b",5)
			elif size.x>10 and size.y<.1:aged(child,"b2a58b",3)
	for side in [-1,1]:
		box(home,Vector3(side*5.29,1.6,0),Vector3(.035,3.2,10.4),"626751",false,2)
		for x in [-3.05,3.05]:box(home,Vector3(x,1.6,side*5.29),Vector3(4.3,3.2,.035),"626751",false,2)
		box(home,Vector3(0,2.96,side*5.29),Vector3(1.8,.65,.035),"626751",false,2)
	# A narrow entrance hall opens onto both side rooms. Clear back route for dragging.
	for x in [-1.7,1.7]:
		for segment in [[-3.8,2.2],[.2,2.0],[4.85,.5]]:
			box(home,Vector3(x,1.55,segment[0]),Vector3(.13,3.1,segment[1]),"827963",true,5)
			box(home,Vector3(x,0.48,segment[0]),Vector3(.16,.85,segment[1]),"595240",false,2)
		for z in [-2.65,-.85,1.25,4.55]:box(home,Vector3(x,1.3,z),Vector3(.2,2.6,.1),"aa9a77")
		for z in [-1.75,2.9]:box(home,Vector3(x,2.62,z),Vector3(.2,.12,1.8 if z<0 else 3.2),"aa9a77")
	box(home,Vector3(0,.065,.3),Vector3(2.5,.018,8.8),"61503c",false,2)
	for x in [-1.15,1.15]:box(home,Vector3(x,.077,.3),Vector3(.05,.009,8.5),"a89873")
	for z in [-3.5,.3,3.8]:
		cylinder(home,Vector3(0,2.95,z),.25,.12,"514d3b")
		game.block(home,Vector3(0,2.83,z),Vector3(.25,.16,.25),"d2b77e",false,true)
		game.light(home,Vector3(0,2.65,z),Color("d0b77e"),.65,4.8)
	# Pictures, coat pegs, bench and a dead houseplant.
	for x in [-1,1]:
		var frame := Node3D.new()
		home.add_child(frame)
		frame.position=Vector3(x*1.6,1.8,0)
		frame.rotation.y=-x*PI/2
		box(frame,Vector3.ZERO,Vector3(1.3,.85,.06),"4a3e2f")
		box(frame,Vector3(0,0,.04),Vector3(1.1,.65,.02),"76735b")
		for i in range(7):box(frame,Vector3(-.45+i*.15,-.1,.06),Vector3(.04,.2+sin(i)*.12,.01),"333f36")
	box(home,Vector3(-4.5,.5,.1),Vector3(.6,.12,2.2),"514839",true,2)
	box(home,Vector3(-4.8,.9,.1),Vector3(.1,.85,2.2),"514839")
	cylinder(home,Vector3(4.65,.24,-.2),.3,.48,"745a42")
	for i in range(7):
		var leaf := box(home,Vector3(4.65+sin(i)*.22,.8+float(i%3)*.13,-.2+cos(i)*.22),Vector3(.09,.8,.12),"424c33")
		leaf.rotation.z=sin(i)*.6
	for x in [-5.12,5.12]:
		box(home,Vector3(x,.42,0),Vector3(.06,.78,10.2),"5c5440",false,2)
		box(home,Vector3(x,2.95,0),Vector3(.14,.17,10.2),"a59a7b")
	# Covered porch and side garden. No step collision at the doorway.
	box(home,Vector3(0,.025,6.1),Vector3(5,.05,2),"7b7561",true,2)
	box(home,Vector3(0,2.9,6.1),Vector3(5.5,.16,2.5),"455045")
	for x in [-2.4,2.4]:box(home,Vector3(x,1.45,7),Vector3(.13,2.9,.13),"8d8870",true)
	for x in [-6.8,6.8]:
		for z in range(-8,7):box(home,Vector3(x,.55,z),Vector3(.08,1.1,.1),"67694f",true,2)

func attack_waypoint(from: Vector3, target: Vector3) -> Vector3:
	var local_from: Vector3=from-after.HOUSE
	var local_target: Vector3=target-after.HOUSE
	if absf(local_from.x)<1.45 and absf(local_target.x)>1.5 or absf(local_from.x)>1.5 and absf(local_target.x)<1.45:
		var portal := 3.0 if local_target.z>0 else -1.75
		if absf(local_from.z-portal)>.25:return Vector3(from.x,target.y,after.HOUSE.z+portal)
	return target
