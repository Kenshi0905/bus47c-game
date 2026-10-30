extends Node3D
var game
var after
var bodies: Node3D
var coffee_blackout := false
var coffee_lights: Array[Node3D]=[]
var coffee_bulbs: Array[Dictionary]=[]
var inspected: Array[String]=[]
var resident_spots: Array[String]=[]
const STAFF=["MARA   DINER OWNER","DEV   MART OWNER","NORA   COFFEE OWNER","ED   TAKEAWAY OWNER"]
const COLORS=["9b7752","66866a","bb9e72","934539"]

func setup(g,a) -> void:
	game=g
	after=a
	name="LoomesvilleAfterHours"
	build_gate()
	bodies=Node3D.new()
	add_child(bodies)
	bodies.name="BusArrivalBodies"
	for i in range(16):
		var side := -1 if i%2==0 else 1
		var at := Vector3(120+side*(2.1+float(i%3)*.55),.18,-735-float(i/2)*3.5)
		corpse(at,i,float(i)*1.7)
	# An off-aisle mound leaves the street and shop doors physically accessible.
	# Four crossed layers. Body origins are at their hips rather than their feet.
	for layer in range(4):
		for row in range(3 if layer<2 else 2):
			var at := Vector3(128.4+(row-1)*.49,.19+layer*.24,-752+sin(row*2+layer)*.2)
			corpse(at,20+layer*3+row,(PI/2 if layer%2 else 0)+sin(row*3+layer)*.16,true)
	pool(bodies,Vector3(128.4,.07,-752),Vector2(1.7,1.55))
	for id in after.district.shops:
		var shop: Node3D=after.district.shops[id]
		for i in range(5):
			pool(shop,Vector3(-4.7+float(i)*2.1,.074,-.7+sin(i*7)*2.8),Vector2(.55+float(i%2)*.35,.8))
		for i in range(9):
			var streak: MeshInstance3D=game.block(shop,Vector3(-3.5+i*.8,.6+sin(i)*.2,-2.585),Vector3(.045,.4+float(i%3)*.1,.012),"70201a")
			streak.material_override=preload("res://scripts/blood_palette.gd").material()
			streak.rotation.z=sin(i)*.12
		var staff_index: int=["diner","mart","coffee_shop","pizza"].find(id)
		var card: Node3D=after.district.poster(shop,Vector3(4.8,2.0,-5.38),Vector2(1.25,1.1),STAFF[staff_index].replace("   ","\n"),"b8ac89","403d30")
		var portrait: Node3D=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
		card.add_child(portrait)
		portrait.position=Vector3(0,-.43,.05)
		portrait.rotation.y=PI
		portrait.scale=Vector3(.21,.21,.035)
		for part in portrait.find_children("*","MeshInstance3D",true,false):
			if part.get_aabb().get_center().y<1.3:part.hide()
		if id=="coffee_shop":
			for lamp in shop.find_children("*","Light3D",true,false):coffee_lights.append(lamp)
			for mesh in shop.find_children("*","MeshInstance3D",true,false):
				var material: Material=mesh.material_override
				if material is StandardMaterial3D and material.emission_enabled:coffee_bulbs.append({"mesh":mesh,"material":material})
	reset()

func reset() -> void:
	inspected.clear()
	coffee_blackout=false
	for lamp in coffee_lights:lamp.show()
	for item in coffee_bulbs:item.mesh.material_override=item.material
	if is_instance_valid(bodies):bodies.hide()

func update() -> void:
	bodies.visible=after.town_entered and after.branch=="bus"
	if not after.town_entered or coffee_blackout:return
	var shop: Node3D=after.district.shops.coffee_shop
	var at: Vector3=shop.to_local(game.player.global_position)
	if absf(at.x)<5.7 and at.z< -3.55 and at.z> -5.3:
		blackout()
		after.save_at(after.checkpoint)

func blackout() -> void:
	coffee_blackout=true
	for lamp in coffee_lights:lamp.hide()
	for item in coffee_bulbs:
		var dark: StandardMaterial3D=item.material.duplicate()
		dark.emission_enabled=false
		dark.albedo_color=Color("242b26")
		item.mesh.material_override=dark
	game.play_sound("knock")

func build_gate() -> void:
	var gate := Node3D.new()
	add_child(gate)
	gate.name="WelcomeToLoomesville"
	gate.position=Vector3(120,0,-730)
	for x in [-6.5,6.5]:
		game.block(gate,Vector3(x,2.5,0),Vector3(.42,5,.42),"5d5c4a",true)
		game.block(gate,Vector3(x,.5,0),Vector3(.85,1,.85),"4b5148",true)
	game.block(gate,Vector3(0,4.65,0),Vector3(13.4,1.15,.22),"35453b")
	after.district.lettering(gate,"WELCOME TO LOOMESVILLE",Vector3(0,4.65,.13),.014,"c3b38a")
	game.light(gate,Vector3(0,4.9,1.0),Color("d1b580"),1.4,9)

func pool(parent: Node3D, at: Vector3, size: Vector2) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a := TAU*float(i)/16
		var b := TAU*float(i+1)/16
		for vertex in [Vector3.ZERO,Vector3(cos(b)*size.x*(1+.12*sin(b*7)),0,sin(b)*size.y),Vector3(cos(a)*size.x*(1+.12*sin(a*7)),0,sin(a)*size.y)]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(vertex)
	var node := MeshInstance3D.new()
	node.mesh=tool.commit()
	var material: StandardMaterial3D=preload("res://scripts/blood_palette.gd").material()
	material.roughness=.28
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=material
	parent.add_child(node)
	node.position=at

func corpse(at: Vector3, index: int, yaw: float, piled: bool=false) -> void:
	var root := Node3D.new()
	bodies.add_child(root)
	root.position=at
	root.rotation.y=yaw
	root.name="Resident"+str(index)
	var model: Node3D=load("res://assets/characters/"+["01_grinning_clerk","03_long_neck_worker","04_crooked_passenger"][index%3]+".gltf").instantiate()
	root.add_child(model)
	model.rotation.x=-PI/2
	if piled:
		model.position.z=.9
		model.rotation.z=sin(index*4)*.12
		var limbs: Array[Node3D]=game.passengers.rig_limbs(model)
		for i in range(limbs.size()):
			limbs[i].rotation.x=sin(index*2+i)*(.22 if i%2==0 else .55)
			limbs[i].rotation.z=sin(index+i)*.3
	for part in model.find_children("*","MeshInstance3D",true,false):
		var key := String(part.name).to_lower()
		if "shirt" in key or "torso" in key or "sleeve" in key:part.material_override=game.mat(COLORS[index%4])
		part.visibility_range_end=65
	var id := "resident_"+str(resident_spots.size())
	resident_spots.append(id)
	after.hotspot(id,root,Vector3(0,.22,-1),"Inspect",2.7)
	# Clothing and personal effects hint at their lives without naming the dead.
	if index%4==0:game.block(root,Vector3(.32,.09,-.8),Vector3(.16,.03,.23),"b19c72")
	elif index%4==1:game.block(root,Vector3(.32,.1,-1.1),Vector3(.08,.04,.12),"a4a298")
	if not piled:pool(bodies,Vector3(at.x,.067,at.z-1),Vector2(.55,1.05))

func inspect(id: String) -> void:
	if id not in resident_spots:return
	var index: int=resident_spots.find(id)
	var clues := ["Flour on the cuffs. The apron is still warm.","A ring of keys. One has a tiny green tag.","Coffee on the sleeve. I know that smell.","Grease on the collar. A receipt in the pocket."]
	game.say(clues[index%4] if not inspected.is_empty() else "Oh God... Oh my God. This is horrible.",5,true)
	if id not in inspected:inspected.append(id)
