extends Node3D
## Editable low-poly district. Four distinct shops with real, walkable interiors.
const AGED=preload("res://assets/ui/aged_surface.gdshader")
var game
var after
var shops: Dictionary={}
var materials: Dictionary={}
var forestry_marker: Node3D
const DOCUMENTS={
	"shop_pizza":["LAST ORDER","MORROW'S PIZZA\n\nCollection for House 17.\nOne customer. Six place settings.\n\nThe order was paid at 02:36.\n\nPlease stop calling. We can hear the phone ringing inside your house."],
	"shop_diner":["NIGHT SHIFT","NIGHT OWL DINER\n\nLeave the booth by the window empty.\n\nIf the last bus stops outside, turn off the coffee machine. Do not count the passengers.\n\nSomeone has crossed out every date on the rota."],
	"shop_mart":["DELIVERY RECORD","47 MART\n\nMilk. Bread. Batteries.\n\nThe driver left the same boxes again. Everything inside expires yesterday.\n\nThere is a bus ticket tucked beneath the receipt. The destination has been rubbed away."],
	"shop_coffee_shop":["BEFORE OPENING","STILL HOUR COFFEE\n\nOne cup left beside the machine.\nCold before we opened.\n\nPlease leave the side light on for the firewatcher.\n\nThe handwriting ends here. There is a wet ring over the date."]
}

func setup(g, a, home: Node3D) -> void:
	game=g
	after=a
	name="LoomesvilleDistrict"
	street()
	shop("pizza",Vector3(101,0,-742),PI/2,"MORROW'S TAKEAWAY","314f43")
	shop("diner",Vector3(139,0,-742),-PI/2,"NIGHT OWL DINER","8e7150")
	shop("mart",Vector3(139,0,-714),-PI/2,"47 MART","4b6557")
	shop("coffee_shop",Vector3(113,0,-699),PI,"STILL HOUR COFFEE","797363")
	for item in [[Vector3(97,0,-702),0],[Vector3(83,0,-702),0],[Vector3(155,0,-702),0],[Vector3(101,0,-766),PI/2],[Vector3(139,0,-766),-PI/2],[Vector3(151,0,-788),0],[Vector3(88,0,-789),0]]:
		terrace(item[0],item[1])
	home_details(home)
	build_forestry_marker()

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
	# Forestry Way has a real opening through the southern fence.
	box(self,Vector3(91,1,-807),Vector3(28,2,.2),"303d31",true,2)
	box(self,Vector3(138,1,-807),Vector3(54,2,.2),"303d31",true,2)

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
	box(root,Vector3(0,.025,0),Vector3(12,.05,11),"827766" if id=="coffee_shop" else "aba28b",true,9 if id=="coffee_shop" else (8 if id=="mart" else 3))
	box(root,Vector3(0,3.25,0),Vector3(12,.2,11),"888a78",true,6)
	var inside_color: String={"pizza":"94784c","diner":"b0a17d","mart":"727b69","coffee_shop":"a29b80"}[id]
	var wall_kind: int=10 if id=="pizza" else 0
	box(root,Vector3(0,1.6,-5.5),Vector3(12,3.2,.18),inside_color,true,wall_kind)
	for x in [-6,6]:box(root,Vector3(x,1.6,0),Vector3(.18,3.2,11),inside_color,true,wall_kind)
	# Wide centre entrance. Glass wings and an open hinged door frame it.
	for x in [-3.55,3.55]:
		box(root,Vector3(x,.4,5.5),Vector3(4.9,.8,.18),color,true,1)
		game.glass(root,Vector3(x,1.8,5.5),Vector3(4.8,2,.045))
		for dx in [-2.4,0,2.4]:box(root,Vector3(x+dx,1.85,5.53),Vector3(.08,2.3,.08),"a3a38e",true)
	box(root,Vector3(0,3.12,5.5),Vector3(12,.2,.2),"a3a38e")
	box(root,Vector3(0,3.7,5.55),Vector3(12.4,1,.3),color)
	if id=="coffee_shop":lettering(root,title,Vector3(0,3.7,5.72),.016)
	elif id=="mart":mart_logo(root)
	elif id=="pizza":takeaway_logo(root)
	for y in [3.26,4.12]:game.block(root,Vector3(0,y,5.75),Vector3(12.2,.055,.05),"c58d55" if id=="diner" else "d2b378",false,id!="coffee_shop")
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
		if id=="coffee_shop" or id=="diner":
			pendant(root,Vector3(x,2.78,.5),"cfa66a")
		else:
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
	elif id=="mart":mart_room(root)
	else:coffee_room(root)
	shop_front(root,id)
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

func pendant(parent: Node3D, at: Vector3, color: String) -> void:
	box(parent,at+Vector3(0,.22,0),Vector3(.035,.44,.035),"353d32")
	cylinder(parent,at,.25,.11,"4c4a38")
	game.block(parent,at-Vector3(0,.08,0),Vector3(.2,.16,.2),color,false,true)
	game.light(parent,at-Vector3(0,.18,0),Color(color),1.65,7.8)

func poster(parent: Node3D, at: Vector3, size: Vector2, copy: String, color: String="c7bda0", ink: String="343c31", angle: float=0.0) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position=at
	root.rotation.z=angle
	box(root,Vector3.ZERO,Vector3(size.x,size.y,.018),color,false,7)
	var longest := 1
	for line in copy.split("\n"):longest=maxi(longest,line.length())
	lettering(root,copy,Vector3(0,0,.021),minf(size.y/(maxi(1,copy.count("\n")+1)*65.0),size.x/(longest*31.0)),ink)
	return root

func neon_open(root: Node3D, at: Vector3, warm: bool=false) -> void:
	box(root,at,Vector3(1.0,.55,.06),"243c36")
	for x in [-.48,.48]:game.block(root,at+Vector3(x,0,.045),Vector3(.025,.47,.025),"c36c4a" if warm else "d45a79",false,true)
	for y in [-.24,.24]:game.block(root,at+Vector3(0,y,.045),Vector3(.97,.025,.025),"c36c4a" if warm else "d45a79",false,true)
	lettering(root,"OPEN",at+Vector3(0,0,.065),.007,"f0b46f" if warm else "c78fb3")
	game.light(root,at+Vector3(0,0,.3),Color("cc8b51" if warm else "b4658c"),.5,3)

func shop_front(root: Node3D, id: String) -> void:
	# Paint wear, downpipes and small pasted notices distinguish the shopfronts.
	for x in [-5.85,5.85]:box(root,Vector3(x,1.5,5.65),Vector3(.09,3,.09),"565c4f")
	for i in range(11):
		box(root,Vector3(-5.6+float(i)*1.05,.28+float(i%3)*.11,5.605),Vector3(.13+float(i%2)*.09,.08,.015),"5d6353")
	if id=="diner":
		box(root,Vector3(0,2.98,5.65),Vector3(12,.13,.08),"873d2e")
		# Split the low stripes across the open entrance.
		for x in [-3.55,3.55]:
			for y in [.16,.55]:box(root,Vector3(x,y,5.66),Vector3(4.8,.13,.08),"873d2e")
		var roof_sign := Node3D.new()
		root.add_child(roof_sign)
		roof_sign.position=Vector3(0,4.75,4.9)
		for x in [-2.8,2.8]:box(roof_sign,Vector3(x,-.4,0),Vector3(.09,.8,.09),"3e473b")
		box(roof_sign,Vector3.ZERO,Vector3(10.6,1.1,.15),"2e3c32")
		lettering(roof_sign,"NIGHT OWL DINER",Vector3(-1.05,0,.09),.017,"d58e40")
		var eat_panel := poster(roof_sign,Vector3(4.2,0,.09),Vector2(1.8,.95),"EAT\nHERE","c7b184","232b22")
		for child in eat_panel.get_children():
			if child is Label3D:child.pixel_size=.0095
		box(roof_sign,Vector3(5.35,0,0),Vector3(.65,.65,.13),"baa474").rotation.z=PI/4
		game.light(roof_sign,Vector3(-1,0,.8),Color("c8904e"),1.0,5)
		game.light(roof_sign,Vector3(2.4,0,.75),Color("cdb685"),1.4,3.5)
		neon_open(root,Vector3(-4.8,2.0,5.65),true)
		vending_machine(root,Vector3(-3.8,0,6.35))
		table(root,Vector3(3.5,0,7.0))
		poster(root,Vector3(4.9,1.8,5.57),Vector2(.75,.95),"HOT FOOD\nALL NIGHT","aa966e","493b2e",.04)
	elif id=="pizza":
		box(root,Vector3(0,3.1,6.05),Vector3(12.6,.12,1.3),"303e33")
		lettering(root,"PIZZA   HOT MEALS   COLLECTION",Vector3(0,3.34,5.74),.007,"c2b693")
		neon_open(root,Vector3(-3.5,2.1,5.59))
		for x in [2.8,3.6,4.4]:
			box(root,Vector3(x,.45,4.6),Vector3(.65,.13,.65),"744b3d",true)
			box(root,Vector3(x,.87,4.86),Vector3(.65,.8,.09),"744b3d",true)
		for i in range(4):poster(root,Vector3(2.8+float(i%2)*.95,1.5+float(i/2)*.78,5.57),Vector2(.7,.58),["HOT\nPIZZA","MEAL\nDEAL","TAKE\nAWAY","OPEN\nLATE"][i],"b7b49a","435044",float(i-2)*.04)
		poster(root,Vector3(-1.45,1.4,5.61),Vector2(.5,.4),"KEEP\nCLEAR","bcc1b2","36483d")
	elif id=="mart":
		box(root,Vector3(0,3.02,6.03),Vector3(12.5,.14,1.2),"4c5a4b")
		for i in range(10):
			box(root,Vector3(-5.5+i*1.2,3.08,6.6),Vector3(.06,.11,.06),"8a9575")
		poster(root,Vector3(-3.6,1.6,5.58),Vector2(1.35,1.6),"47 MART\nEVERYDAY\nLOW PRICES","b4ba98","4b5a40",-.025)
		poster(root,Vector3(4.1,1.7,5.58),Vector2(1.2,1.5),"BREAD\nMILK\nBATTERIES","c6bda0","6b4632",.03)
		for x in [-5.1,-4.5]:
			box(root,Vector3(x,.25,6.3),Vector3(.5,.5,.6),"756b4f",true)
			for y in [.15,.35]:box(root,Vector3(x,y,6.61),Vector3(.4,.05,.02),"504b37")
		neon_open(root,Vector3(2.0,2.5,5.59),true)
	else:
		# The coffee stand is quieter and more cluttered, with a street serving ledge.
		box(root,Vector3(-3.5,1.03,5.96),Vector3(4.8,.1,.9),"66624d",true,2)
		for x in [-4.7,-2.5]:
			cylinder(root,Vector3(x,.5,6.8),.07,1.0,"4d4c3e")
			cylinder(root,Vector3(x,1.02,6.8),.3,.08,"89816a")
		for i in range(7):
			var sticker_color: String=["b7ad84","778976","ad9b74"][i%3]
			poster(root,Vector3(-5.3+float(i)*.58,1.4+sin(i)*.2,5.58),Vector2(.42,.35),["47C","FRESH","COFFEE","LOCAL","02:36","TAKE\nAWAY","HELLO"][i],sticker_color,"3d4538",sin(i)*.08)
		poster(root,Vector3(3.5,2.1,5.58),Vector2(1.15,1.5),"COFFEE\nTEA\nSOMETHING\nWARM","b9ab84","414737",-.03)
		pendant(root,Vector3(-4.5,2.85,5.9),"d4b172")
		plant(root,Vector3(3.4,.06,6.15),.8)
		box(root,Vector3(5.1,2.0,5.68),Vector3(.85,.6,.25),"5e675b")
		for y in [1.82,1.95,2.08,2.21]:box(root,Vector3(5.1,y,5.83),Vector3(.73,.035,.025),"2c392f")
		for y in [.7,1.1,1.5]:box(root,Vector3(-5.8,y,5.78),Vector3(.27,.3,.13),"4b554b")

func vending_machine(root: Node3D, at: Vector3) -> void:
	box(root,at+Vector3(0,1.05,0),Vector3(1.05,2.1,.7),"6e342e",true)
	box(root,at+Vector3(-.15,1.35,.37),Vector3(.53,1.15,.04),"b6a47b")
	lettering(root,"COLA",at+Vector3(-.15,1.55,.405),.007,"62362a")
	box(root,at+Vector3(.33,1.2,.39),Vector3(.22,.75,.04),"253b32")
	for y in [.95,1.12,1.29,1.46]:game.block(root,at+Vector3(.33,y,.42),Vector3(.13,.07,.02),"aaa27b",false,true)
	box(root,at+Vector3(0,.35,.37),Vector3(.68,.22,.05),"172b23")

func plant(root: Node3D, at: Vector3, height: float=1.0) -> void:
	cylinder(root,at+Vector3(0,.22,0),.26,.44,"7b6045")
	cylinder(root,at+Vector3(0,.448,0),.225,.012,"3d392b")
	for i in range(7):
		var leaf := box(root,at+Vector3(sin(i)*.16,.48+height*.3+float(i%3)*.08,cos(i)*.16),Vector3(.08,height*.7,.1),"46513a")
		leaf.rotation.z=sin(i)*.45

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
	# Red vinyl booths along the windows, a lunch counter opposite, clear centre aisle.
	for z in [.1,3.15]:
		for side in [-1,1]:
			box(root,Vector3(4.1,.48,z+side*.95),Vector3(2.8,.25,.65),"853c2e",true,11)
			box(root,Vector3(4.1,.96,z+side*1.22),Vector3(2.8,1.15,.17),"793629",true,11)
			box(root,Vector3(4.1,1.12,z+side*1.105),Vector3(.8,.66,.025),"b09a6c",false,11)
			for x in [2.75,5.45]:box(root,Vector3(x,.9,z+side*1.1),Vector3(.025,1.0,.09),"9c9b85")
		box(root,Vector3(4.1,.85,z),Vector3(2.6,.11,1.12),"bcb18a",true)
		box(root,Vector3(4.1,.79,z),Vector3(2.66,.035,1.17),"919a8e")
		cylinder(root,Vector3(4.1,.4,z),.09,.8,"737f76")
		box(root,Vector3(5,.98,z),Vector3(.21,.23,.18),"958b73")
		for x in [3.4,4.6]:cylinder(root,Vector3(x,.99,z),.09,.16,"ccc2a3")
	box(root,Vector3(-4.6,.55,1.3),Vector3(2.5,1.1,6.4),"493a2d",true,2)
	box(root,Vector3(-4.6,1.12,1.3),Vector3(2.6,.13,6.5),"b4a37a",true)
	box(root,Vector3(-3.27,.98,1.3),Vector3(.04,.1,6.5),"a7ada1")
	for z in [-.8,.65,2.1,3.55]:
		cylinder(root,Vector3(-2.65,.4,z),.07,.8,"a0a99a")
		cylinder(root,Vector3(-2.65,.12,z),.33,.06,"6c756c")
		cylinder(root,Vector3(-2.65,.85,z),.31,.16,"8e4030")
		box(root,Vector3(-2.25,1.15,z),Vector3(.12,.6,.5),"803529",true,11)
		cylinder(root,Vector3(-4.0,1.25,z),.1,.16,"bcb49b")
	for z in [.0,3.0]:
		box(root,Vector3(5.87,2.1,z),Vector3(.08,1.8,2.8),"172321")
		for row in range(14):
			var blind := box(root,Vector3(5.80,1.32+row*.12,z),Vector3(.08,.067,2.74),"7f795b")
			blind.rotation.z=.23
		for dz in [-.95,.95]:box(root,Vector3(5.74,2.1,z+dz),Vector3(.015,1.7,.02),"c2b18b")
		pendant(root,Vector3(4.0,2.85,z),"d4b273")
	for z in [-1.4,1.4,4.1]:
		box(root,Vector3(0,3.08,z),Vector3(.7,.10,1.65),"7f8070")
		game.block(root,Vector3(0,3.02,z),Vector3(.56,.025,1.5),"c4bc91",false,true)
		game.light(root,Vector3(0,2.8,z),Color("dfc38f"),1.2,5)
	box(root,Vector3(-2,1.5,-4.7),Vector3(1.4,.9,.6),"70786a")
	for x in [-2.4,-1.6]:cylinder(root,Vector3(x,1.95,-4.7),.18,.35,"222e2a")
	lettering(root,"COFFEE ALL NIGHT\nTHE USUAL IS ALREADY ON",Vector3(1.7,2.3,-5.38),.005)
	box(root,Vector3(-5.2,.8,3.8),Vector3(.7,1.6,.65),"745638",true)
	game.block(root,Vector3(-5.2,1.2,4.15),Vector3(.5,.5,.04),"b58b52",false,true)
	for x in [-5.88]:
		box(root,Vector3(x,.65,0),Vector3(.06,1.2,10.7),"6b4636",false,10)
		box(root,Vector3(x,1.28,0),Vector3(.1,.08,10.7),"a18d64")
		for z in [-1.5,1.0,3.2]:
			var frame := poster(root,Vector3(x,2.0,z),Vector2(.8,1.1),"NIGHT OWL\nHOT FOOD\nGOOD COFFEE","b6a273","6c4932",.02)
			frame.rotation.y=PI/2 if x<0 else -PI/2
	for x in [-4.5,3.8]:
		box(root,Vector3(x,1.24,-3),Vector3(.23,.3,.2),"b8a47a")
		box(root,Vector3(x,1.4,-3),Vector3(.27,.02,.24),"655b47")

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
	# The abandoned sale banner hangs above head height, on unequal chains.
	var banner := Node3D.new()
	root.add_child(banner)
	banner.name="FadedSaleBanner"
	banner.position=Vector3(-1.6,2.55,2.0)
	banner.rotation.z=-.11
	box(banner,Vector3.ZERO,Vector3(3.6,.9,.04),"c7b99b",false,7)
	for x in [-1.6,1.6]:
		box(banner,Vector3(x,.63,0),Vector3(.018,.4,.018),"4b5947")
	lettering(banner,"MIDNIGHT SALE\nDOOR BUSTERS",Vector3(-.6,0,.034),.0067,"354a3c")
	var emblem := box(banner,Vector3(1.13,0,.03),Vector3(1.0,.65,.012),"985444")
	emblem.rotation.z=.13
	lettering(banner,"47\nMART",Vector3(1.13,0,.05),.006,"c2b59a")
	for i in range(9):box(banner,Vector3(-1.6+i*.37,.37+sin(i)*.05,.035),Vector3(.14,.07,.01),"a49b80")
	for x in [-5.7,5.7]:
		for z in [1,3]:box(root,Vector3(x,.28,z),Vector3(.5,.56,.7),"8d7c59",true,7)
	for x in [-3,3]:
		for z in [-.1,1.2,2.5]:
			box(root,Vector3(x,1.72,z),Vector3(1.0,.025,.2),"b0ac8b")
			for dx in [-.4,0,.4]:
				# Necked bottles break up the old repeated cylinder silhouettes.
				cylinder(root,Vector3(x+dx,1.85,z+.2),.075,.2,"687b4d")
				cylinder(root,Vector3(x+dx,1.99,z+.2),.035,.08,"8f9772")

func coffee_room(root: Node3D) -> void:
	# Small furniture clusters leave the straight entrance-to-note route clear.
	for z in [.5,3.1]:table(root,Vector3(3.8,0,z))
	box(root,Vector3(-4.8,1.05,.8),Vector3(1.8,.13,5.5),"7a654b",true,2)
	for z in [-1.2,.8,2.8]:
		cylinder(root,Vector3(-3.8,.47,z),.07,.94,"4c4f40")
		cylinder(root,Vector3(-3.8,.97,z),.28,.1,"967957")
	box(root,Vector3(-2.2,1.46,-3),Vector3(1.6,.65,.7),"747d6b",true)
	box(root,Vector3(-2.2,1.47,-2.61),Vector3(1.38,.4,.06),"24392d")
	for x in [-2.6,-1.8]:
		cylinder(root,Vector3(x,1.73,-2.55),.05,.07,"aaad95").rotation.x=PI/2
		box(root,Vector3(x,1.3,-2.57),Vector3(.035,.2,.035),"adb29e")
		cylinder(root,Vector3(x,1.22,-2.49),.08,.13,"c6baa0")
	box(root,Vector3(.8,1.32,-3),Vector3(2.1,.35,.7),"685840")
	for x in [.1,.7,1.3]:
		cylinder(root,Vector3(x,1.54,-3),.15,.08,"b4945d")
	for i in range(5):
		cylinder(root,Vector3(-3.2,1.19+i*.055,-3.0),.11,.09,"b5aa8e")
	for y in [1.65,2.25]:
		box(root,Vector3(-4.6,y,-5.1),Vector3(2.2,.09,.65),"6c5a42")
		for x in [-5.3,-4.6,-3.9]:
			box(root,Vector3(x,y+.25,-5.05),Vector3(.43,.45,.3),"9d8e6e",false,7)
			poster(root,Vector3(x,y+.25,-4.885),Vector2(.28,.24),"BEANS","6f6f52","c4bb99")
	poster(root,Vector3(.8,2.25,-5.36),Vector2(4.7,1.35),"STILL HOUR\nCOFFEE   TEA   PASTRIES\nTAKE A MOMENT","404d37","c3b38c")
	for z in [-.6,1.1,2.8]:
		var frame := poster(root,Vector3(-5.88,2.1,z),Vector2(.95,.7),"LOCAL ROAST\nSINCE 1974","b5a47e","46503b",sin(z)*.035)
		frame.rotation.y=PI/2
	plant(root,Vector3(5.25,.06,-4.7),1.1)
	pendant(root,Vector3(-2.2,2.82,-3.8),"cdaa71")

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
	# Lift the pot fully above the floor; keep wall skins separated by clear depth.
	plant(home,Vector3(4.65,.065,-.2),.9)
	for x in [-5.08,5.08]:
		box(home,Vector3(x,.42,0),Vector3(.06,.78,10.2),"5c5440",false,2)
		box(home,Vector3(x,2.95,0),Vector3(.14,.17,10.2),"a59a7b")
	# Covered porch and side garden. No step collision at the doorway.
	box(home,Vector3(0,.025,6.1),Vector3(5,.05,2),"7b7561",true,2)
	box(home,Vector3(0,2.9,6.1),Vector3(5.5,.16,2.5),"455045")
	for x in [-2.4,2.4]:box(home,Vector3(x,1.45,7),Vector3(.13,2.9,.13),"8d8870",true)
	for x in [-6.8,6.8]:
		for z in range(-8,7):box(home,Vector3(x,.55,z),Vector3(.08,1.1,.1),"67694f",true,2)

func build_forestry_marker() -> void:
	forestry_marker=Node3D.new()
	forestry_marker.name="ForestryWayMarker"
	add_child(forestry_marker)
	forestry_marker.position=after.HOUSE+Vector3(-7.5,0,14.5)
	forestry_marker.rotation.y=PI*.75
	box(forestry_marker,Vector3(0,.85,0),Vector3(.08,1.7,.08),"625e46")
	box(forestry_marker,Vector3(0,1.55,0),Vector3(1.4,.42,.08),"384b3b")
	lettering(forestry_marker,"FORESTRY WAY",Vector3(0,1.55,.05),.0036,"c7bc8d")
	var diamond: MeshInstance3D=game.block(forestry_marker,Vector3(0,1.97,0),Vector3(.14,.14,.07),"bcaa6f",false,true)
	diamond.rotation.z=PI/4
	game.light(forestry_marker,Vector3(0,1.6,.3),Color("b9aa79"),.45,3)
	forestry_marker.hide()

func attack_waypoint(from: Vector3, target: Vector3) -> Vector3:
	var local_from: Vector3=from-after.HOUSE
	var local_target: Vector3=target-after.HOUSE
	if absf(local_from.x)<1.45 and absf(local_target.x)>1.5 or absf(local_from.x)>1.5 and absf(local_target.x)<1.45:
		var portal := 3.0 if local_target.z>0 else -1.75
		if absf(local_from.z-portal)>.25:return Vector3(from.x,target.y,after.HOUSE.z+portal)
	return target

func mart_logo(root: Node3D) -> void:
	# Original convenience-store identity with bright horizontal colour bands.
	for band in [[3.46,"318064"],[3.68,"d7b04c"],[3.9,"bc4933"]]:
		game.block(root,Vector3(0,band[0],5.735),Vector3(12.15,.2,.025),band[1],false,true)
	box(root,Vector3(0,3.71,5.78),Vector3(3.4,1.15,.08),"dfd8bb")
	var digits: Label3D=lettering(root,"47",Vector3(-.69,3.72,5.837),.02,"b62e27")
	digits.font=ThemeDB.fallback_font
	digits.rotation.z=-.07
	var nameplate: Label3D=lettering(root,"MART",Vector3(.65,3.7,5.84),.009,"21624b")
	nameplate.font=ThemeDB.fallback_font

func takeaway_logo(root: Node3D) -> void:
	box(root,Vector3(0,3.7,5.73),Vector3(12.2,.92,.06),"9b3329")
	# A custom twin-loop M, built from editable segments rather than a pasted logo.
	for side in [-1,1]:
		for i in range(12):
			var a := PI*float(i)/12
			var b := PI*float(i+1)/12
			var pa := Vector3(-3.7+side*.34+cos(a)*.34,3.31+sin(a)*.68,5.79)
			var pb := Vector3(-3.7+side*.34+cos(b)*.34,3.31+sin(b)*.68,5.79)
			var bar: MeshInstance3D=game.block(root,(pa+pb)*.5,Vector3(.105,pa.distance_to(pb)+.04,.035),"e6b34b",false,true)
			bar.rotation.z=-atan2(pb.x-pa.x,pb.y-pa.y)
	var brand: Label3D=lettering(root,"Morrow's",Vector3(.25,3.85,5.79),.017,"ead5a0")
	brand.font=ThemeDB.fallback_font
	lettering(root,"TAKEAWAY",Vector3(.25,3.4,5.79),.007,"ead5a0")
