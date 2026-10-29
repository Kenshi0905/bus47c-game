extends Node3D
## Playable continuation: forage, pursuit, route choice, house and two endings.
const Route = preload("res://scripts/route.gd")
const Story = preload("res://scripts/story.gd")
const HOUSE := Vector3(120,0,-775)
const SAFE_PHASES := ["forest","fork","town","burial","closet","dawn","loop"]
const District=preload("res://scripts/town_district.gd")
var district: Node3D
var repairs: Node3D
var town_entered := false
var mirror_revealed := false
var game
var active := false
var phase := ""
var branch := ""
var checkpoint := "forest"
var hunger := 100.0
var hunger_cues_played := 0
var state_time := 0.0
var look_back_time := 0.0
var pursuit_grace := 0.0
var fruit_taken: Array[int]=[]
var knife := false
var shovel := false
var dragging := false
var coffee := false
var mirror_count := 0
var mirror_wait := 0.0
var burial_remaining := 180.0
var sound_clock := 0.0
var closet_beat := 0
var next_scene := ""
var props: Node3D
var town: Node3D
var opponent: Node3D
var pursuer: Node3D
var mirror_face: Node3D
var eyes: Array[Node3D]=[]
var mouth: Node3D
var mouth_parts: Array[Node3D]=[]
var nose: Node3D
var grave: MeshInstance3D
var wardrobe_doors: Array[Node3D]=[]
var fruit_nodes: Array[Node3D]=[]
var spots: Dictionary={}
var status: Label
var held_blade: Node3D
var double_model: Node3D
var intruder_model: Node3D
var trail_audio: AudioStreamPlayer3D
var ground_knife: Node3D
var attack_ready_time := 0.0
var look_back_armed := false
var look_back_origin := Vector3.ZERO
var scare_limbs: Array[Node3D]=[]

func point(x: float, z: float) -> Vector3:
	return Route.point(x,0,z)

func setup(owner_game) -> void:
	game=owner_game
	name="ForestAndLoomesville"
	props=Node3D.new()
	add_child(props)
	town=Node3D.new()
	add_child(town)
	build_forest()
	build_town()
	pursuer=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	add_child(pursuer)
	game.add_tie_glow(pursuer)
	game.light(pursuer,Vector3(0,1.8,-1),Color("b7aaa0"),.9,3)
	scare_limbs=game.passengers.rig_limbs(pursuer)
	trail_audio=AudioStreamPlayer3D.new()
	pursuer.add_child(trail_audio)
	trail_audio.stream=preload("res://assets/audio/pursuit.wav")
	trail_audio.volume_db=-7
	trail_audio.max_distance=24
	trail_audio.unit_size=5
	status=game.label("",16,Color("b8b496"))
	game.hud.add_child(status)
	status.position=Vector2(850,643)
	status.size=Vector2(396,35)
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	held_blade=Node3D.new()
	game.player.camera.add_child(held_blade)
	game.block(held_blade,Vector3(.34,-.32,-.65),Vector3(.035,.09,.3),"9eaca4")
	game.block(held_blade,Vector3(.34,-.32,-.43),Vector3(.055,.1,.17),"584738")
	reset()

func hotspot(id: String, parent: Node3D, local: Vector3, title: String, radius: float=2.4) -> void:
	spots[id]={"parent":parent,"local":local,"title":title,"radius":radius}

func slab(parent: Node3D, a: Vector3, b: Vector3, width: float, color: String) -> void:
	var path: MeshInstance3D=game.block(parent,(a+b)*.5+Vector3(0,.025,0),Vector3(width,.035,a.distance_to(b)),color)
	path.rotation.y=atan2(b.x-a.x,b.z-a.z)

func lantern(parent: Node3D, at: Vector3, warm: bool=true) -> void:
	game.block(parent,at+Vector3(0,.5,0),Vector3(.075,1,.075),"585844")
	game.block(parent,at+Vector3(0,1.06,0),Vector3(.09,.17,.09),"a48b4b" if warm else "78918a",false,true)
	for height in [.94,1.18]:game.block(parent,at+Vector3(0,height,0),Vector3(.2,.04,.2),"3b4438")
	for x in [-.08,.08]:game.block(parent,at+Vector3(x,1.06,0),Vector3(.025,.2,.14),"3b4438")
	game.light(parent,at+Vector3(0,1.1,0),Color("b7a46f" if warm else "87a9a2"),.65,5)

func build_forest() -> void:
	var fork := Route.FOREST_FORK
	slab(props,point(4,-683),fork,2.2,"383f32")
	var signpost: Node3D=game.signs.add_board(props,fork+Vector3(2.6,0,2.6),"DON'T GO IN\nTHE WOODS",3.0,1.35,-PI/4,33)
	var direction: Label3D=game.text3(signpost,"←  LOOMESVILLE FOOTPATH",Vector3(0,1,.09),30,Color("c5b795"))
	direction.pixel_size=.0035
	game.block(signpost,Vector3(0,1,0),Vector3(2.4,.28,.1),"46392d")
	lantern(props,signpost.position+Vector3(1,0,.5))
	hotspot("shortcut",signpost,Vector3(0,1.5,0),"Take the walking path",3.5)
	hotspot("take_bus",game.bus,Vector3(.3,1.65,-3),"Continue to Loomesville by bus",2.7)
	for i in range(Route.WALK_PATH.size()-1):
		var a: Vector3=Route.WALK_PATH[i]
		var b: Vector3=Route.WALK_PATH[i+1]
		slab(props,a,b,2.4,"4e4936")
		var side: Vector3=(b-a).normalized().cross(Vector3.UP)*1.8
		for t in [.2,.65]:lantern(props,a.lerp(b,t)+side)
	for i in range(3):
		var root := Node3D.new()
		props.add_child(root)
		root.position=Route.FRUIT_SITES[i]
		game.block(root,Vector3(0,.45,0),Vector3(.1,.9,.1),"4b4b38")
		var bush := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius=.65
		shape.height=1.0
		shape.radial_segments=7
		shape.rings=3
		bush.mesh=shape
		bush.material_override=game.mat("3e5336")
		root.add_child(bush)
		bush.position.y=.75
		var berries := Node3D.new()
		root.add_child(berries)
		for j in range(4):
			var fruit := MeshInstance3D.new()
			var round_fruit := SphereMesh.new()
			round_fruit.radius=.105
			round_fruit.height=.21
			round_fruit.radial_segments=8
			round_fruit.rings=3
			fruit.mesh=round_fruit
			fruit.material_override=game.mat("b08049",true)
			berries.add_child(fruit)
			fruit.position=Vector3((j%2)*.5-.25,.8+(j/2)*.2,.55)
		game.light(berries,Vector3(0,1,.3),Color("bb985f"),.65,2.8)
		fruit_nodes.append(berries)
		hotspot("fruit"+str(i),root,Vector3(0,1,.4),"Eat fruit",2.6)
	var ticket: MeshInstance3D=game.block(props,Vector3(5.35,.77,-.45),Vector3(.3,.018,.18),"d7bf7c")
	hotspot("ticket",ticket,Vector3(0,.1,0),"Read the ticket")

	repairs=preload("res://scripts/machine_parts.gd").new()
	props.add_child(repairs)
	repairs.setup(game,self)

func build_town() -> void:
	game.block(town,Vector3(120,.015,-754),Vector3(9,.03,76),"303432")
	for x in [114.5,125.5]:
		game.block(town,Vector3(x,.025,-754),Vector3(2,.05,76),"565b51",true)
		for z in [-735,-754,-774]:lantern(town,Vector3(x,0,z))
	for z in range(-742,-770,-2):
		for side in [-1,1]:
			var footprint: MeshInstance3D=game.block(town,Vector3(120+side*.2,.045,z+side*.35),Vector3(.22,.017,.42),"97523c")
			footprint.rotation.y=side*.12
			var trace: StandardMaterial3D=game.mat("97523c").duplicate()
			trace.emission_enabled=true
			trace.emission=Color("452219")
			trace.emission_energy_multiplier=.22
			footprint.material_override=trace
	var home := Node3D.new()
	town.add_child(home)
	home.position=HOUSE
	game.block(home,Vector3(0,.025,0),Vector3(10.4,.05,10.4),"514b3e",true)
	game.block(home,Vector3(0,3.2,0),Vector3(10.6,.2,10.6),"343d34",true)
	for side in [-1,1]:
		var roof: MeshInstance3D=game.block(home,Vector3(0,3.72,side*2.65),Vector3(11.2,.18,5.6),"26362f")
		roof.rotation.x=side*.19
	for x in [-5.2,5.2]:game.block(home,Vector3(x,1.65,0),Vector3(.15,3.3,10.4),"53594c",true)
	for z in [-5.2,5.2]:
		for x in [-3.05,3.05]:game.block(home,Vector3(x,1.65,z),Vector3(4.3,3.3,.15),"53594c",true)
		game.block(home,Vector3(0,2.95,z),Vector3(1.8,.7,.15),"53594c",true)
	game.text3(home,"17",Vector3(1.7,2,5.31),40)
	for x in [-3.05,3.05]:
		game.block(home,Vector3(x,1.8,5.3),Vector3(1.55,1.6,.06),"767562")
		game.block(home,Vector3(x,1.8,5.34),Vector3(1.38,1.42,.03),"142523")
		game.block(home,Vector3(x,1.8,5.37),Vector3(.045,1.42,.04),"7a7c69")
		game.block(home,Vector3(x,1.8,5.37),Vector3(1.38,.045,.04),"7a7c69")
	for x in [-.94,.94]:game.block(home,Vector3(x,1.32,5.32),Vector3(.12,2.64,.15),"777564")
	game.block(home,Vector3(0,2.64,5.32),Vector3(2,.12,.15),"777564")
	game.light(home,Vector3(0,2.9,5.7),Color("ad9d70"),.45,5)
	game.light(home,Vector3(0,2.8,1),Color("c9ac7b"),.65,8)
	game.block(home,Vector3(-2.6,.9,2),Vector3(2.5,.15,1),"665940",true)
	for x in [-3.6,-1.6]:game.block(home,Vector3(x,.45,2),Vector3(.12,.9,.7),"4d493b",true)
	# The knife is reachable at the doorway, before the attacker starts moving.
	game.block(home,Vector3(-2.35,.82,3.9),Vector3(2.2,.12,.65),"665940",true)
	for x in [-3.3,-1.4]:game.block(home,Vector3(x,.4,3.9),Vector3(.1,.8,.5),"4d493b",true)
	ground_knife=Node3D.new()
	home.add_child(ground_knife)
	ground_knife.position=Vector3(-1.6,.915,3.9)
	ground_knife.rotation.y=-.4
	game.block(ground_knife,Vector3(0,0,-.12),Vector3(.1,.035,.42),"c6cfc3")
	game.block(ground_knife,Vector3(0,0,.17),Vector3(.075,.055,.18),"382e26")
	game.block(ground_knife,Vector3(0,0,.065),Vector3(.16,.06,.035),"8d998c")
	game.light(home,Vector3(-1.6,1.9,4),Color("c7b383"),.6,3.2)
	hotspot("knife",home,Vector3(-1.6,.98,3.9),"Pick up the knife",3.2)
	game.block(home,Vector3(0,.55,-1.5),Vector3(.8,.15,.8),"60533f",true)
	game.block(home,Vector3(0,1.03,-1.85),Vector3(.8,1,.12),"60533f",true)
	opponent=Node3D.new()
	town.add_child(opponent)
	double_model=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	intruder_model=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	opponent.add_child(double_model)
	opponent.add_child(intruder_model)
	game.add_tie_glow(intruder_model)
	game.block(opponent,Vector3(.31,.83,-.16),Vector3(.045,.3,.06),"a2ada2")
	hotspot("defend",opponent,Vector3(0,1.2,0),"Defend yourself",2.5)
	hotspot("body",opponent,Vector3(0,.3,0),"Drag the body",2.6)
	# Stylised mirror reflection, with individually editable facial features.
	game.block(home,Vector3(-3.4,1.7,-5.05),Vector3(2.1,2.5,.1),"756e50")
	game.block(home,Vector3(-3.4,1.7,-4.98),Vector3(1.9,2.3,.06),"263c3c")
	mirror_face=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	home.add_child(mirror_face)
	mirror_face.position=Vector3(-3.4,.25,-4.85)
	mirror_face.scale=Vector3(.9,.9,.18)
	mirror_face.rotation.y=PI
	for mesh in mirror_face.get_children():
		if not mesh is MeshInstance3D:continue
		var part := String(mesh.name)
		if mesh.get_aabb().get_center().y<1.1:mesh.hide()
		if "eye" in part or "pupil" in part:eyes.append(mesh)
		if "grin" in part:mouth_parts.append(mesh)
		if part.begins_with("nose"):nose=mesh
	mouth=mouth_parts[0]
	hotspot("mirror",home,Vector3(-3.4,1.7,-4.8),"Look into the mirror",2.6)
	game.block(home,Vector3(3.5,1.35,-3.7),Vector3(1.8,2.7,.1),"403d32",true)
	for x in [2.6,4.4]:game.block(home,Vector3(x,1.35,-3.1),Vector3(.1,2.7,1.3),"403d32",true)
	for x in [3.02,3.98]:
		var door: MeshInstance3D=game.block(home,Vector3(x,1.35,-2.48),Vector3(.89,2.7,.07),"544d39")
		wardrobe_doors.append(door)
	hotspot("closet",home,Vector3(3.5,1.4,-2.4),"Hide in the closet",2.3)
	game.block(home,Vector3(3.4,.95,3),Vector3(2.5,.15,1.1),"625a46",true)
	for x in [2.4,4.4]:
		for z in [2.6,3.4]:game.block(home,Vector3(x,.45,z),Vector3(.12,.9,.12),"4a4739",true)
	game.block(home,Vector3(3.9,1.1,3),Vector3(.5,.018,.65),"c4b998")
	var mug := MeshInstance3D.new()
	var cup := CylinderMesh.new()
	cup.top_radius=.095
	cup.bottom_radius=.075
	cup.height=.23
	cup.radial_segments=12
	mug.mesh=cup
	mug.material_override=game.mat("a7ada0")
	home.add_child(mug)
	mug.position=Vector3(2.9,1.15,3)
	var handle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius=.047
	ring.outer_radius=.069
	ring.rings=12
	ring.ring_segments=6
	handle.mesh=ring
	handle.material_override=game.mat("a7ada0")
	home.add_child(handle)
	handle.position=Vector3(2.79,1.15,3)
	handle.rotation.x=PI/2
	hotspot("coffee",home,Vector3(2.9,1.2,3),"Make coffee")
	hotspot("newspaper",home,Vector3(3.9,1.15,3),"Read the newspaper")
	game.block(home,Vector3(3.4,2.25,5.08),Vector3(.8,.3,.05),"18231e")
	var clock: Label3D=game.text3(home,"02:36",Vector3(3.4,2.25,5.04),30)
	clock.pixel_size=.003
	clock.rotation.y=PI
	game.block(home,Vector3(1.5,.85,-5.7),Vector3(.07,1.6,.07),"867148")
	game.block(home,Vector3(1.5,.18,-5.7),Vector3(.32,.4,.06),"758176")
	hotspot("shovel",home,Vector3(1.5,.95,-5.7),"Take the shovel",2.5)
	grave=game.block(home,Vector3(2.2,.04,-9),Vector3(1.5,.06,2.5),"202820")
	hotspot("grave",home,Vector3(2.2,.15,-9),"Bury the body",3)
	lantern(home,Vector3(3.8,0,-8))
	slab(home,Vector3(0,0,-5),Vector3(2.2,0,-9),1.8,"4d4b37")
	var escape := HOUSE+Vector3(-9,0,15)
	lantern(town,escape)
	hotspot("escape",town,escape+Vector3(0,1,0),"Follow the trail into the woods",3)
	district=District.new()
	town.add_child(district)
	district.setup(game,self,home)

func daylight(enabled: bool) -> void:
	game.world_environment.ambient_light_energy=.6 if enabled else .13
	game.world_environment.background_color=Color("7b9292" if enabled else "09121c")
	game.world_environment.fog_density=.012 if enabled else .026
	game.world_environment.fog_light_color=Color("7c918c" if enabled else "111d21")
	game.moon_light.light_energy=.8 if enabled else .14

func reset() -> void:
	active=false
	town_entered=false
	mirror_revealed=false
	mirror_face.hide()
	repairs.reset()
	phase=""
	branch=""
	checkpoint="forest"
	hunger=100
	hunger_cues_played=0
	state_time=0
	fruit_taken.clear()
	knife=false
	ground_knife.show()
	attack_ready_time=0
	shovel=false
	dragging=false
	coffee=false
	mirror_count=0
	mirror_wait=0
	burial_remaining=180
	status.text=""
	grave.material_override=game.mat("202820")
	for fruit in fruit_nodes:fruit.show()
	for eye in eyes:eye.show()
	for part in mouth_parts:part.show()
	nose.show()
	for door in wardrobe_doors:door.show()
	held_blade.hide()
	opponent.position=HOUSE+Vector3(0,.12,-1)
	opponent.rotation=Vector3.ZERO
	opponent.hide()
	pursuer.hide()
	town.hide()
	for limb in scare_limbs:limb.rotation=Vector3.ZERO
	props.hide()
	game.player.movement_scale=1
	game.transition_shade.hide()
	daylight(false)
	trail_audio.stop()

func checkpoint_data() -> Dictionary:
	if not active:return {}
	return {"phase":checkpoint,"branch":branch,"parts":repairs.taken,"repaired":repairs.repaired}

func save_at(value: String) -> void:
	checkpoint=value
	game.save_checkpoint()

func restore(data: Dictionary) -> void:
	var saved: String=str(data.get("phase","forest"))
	var saved_branch: String=str(data.get("branch",""))
	if saved not in SAFE_PHASES:saved="forest"
	if saved_branch not in ["walk","bus"]:saved_branch="bus"
	reset()
	active=true
	branch=saved_branch
	props.show()
	game.story.stage=Story.Stage.FINISHED
	game.bus.position.z=-680
	game.align_bus()
	game.set_door(true,true)
	game.watcher_director.reset(game.watcher)
	if saved=="forest":
		begin_forest()
		place_player(point(4,-683)+Vector3(0,.15,0),point(20,-694)+Vector3.UP)
	elif saved=="fork":
		fruit_taken.assign([0,1,2])
		hunger=100
		for fruit in fruit_nodes:fruit.hide()
		repairs.restore(data)
		set_phase("fork",repairs.objective())
		game.set_objective(repairs.objective(),true)
		place_player(Route.FOREST_FORK+Vector3(-3,.15,3),Route.WALK_PATH[1]+Vector3.UP)
		save_at("fork")
	elif saved=="loop":place_loop()
	else:
		place_town()
		if saved in ["burial","closet","dawn"]:
			knife=true
			ground_knife.hide()
			opponent.position=HOUSE+Vector3(0,.4,0)
			opponent.rotation.z=PI/2
			set_phase("burial","Take the shovel. Drag the body to the marked grave behind the house.")
			place_player(HOUSE+Vector3(0,.15,2),HOUSE+Vector3(0,.5,0))
			burial_remaining=180
			if saved in ["closet","dawn"]:
				opponent.hide()
				set_phase("closet_ready","Hide in the wardrobe. Stay inside until daylight.")
				place_player(HOUSE+Vector3(3.5,.15,-.8),HOUSE+Vector3(3.5,1.4,-2.5))
			if saved=="dawn":start_dawn()
			save_at(saved)

func place_player(at: Vector3, look: Vector3) -> void:
	game.passengers.release_player_seat(game.seated_index)
	game.seated_index=-1
	game.player.set_seated(false,Vector3.ZERO)
	if game.player.get_parent()!=game:game.player.reparent(game,false)
	game.player.global_position=at
	game.player.velocity=Vector3.ZERO
	game.player.rotation=Vector3.ZERO
	game.player.camera.position.y=1.57
	var direction: Vector3=look-game.player.camera.global_position
	game.player.rotation.y=atan2(-direction.x,-direction.z)
	game.player.camera.rotation=Vector3(clampf(atan2(direction.y,Vector2(direction.x,direction.z).length()),-1.35,1.35),0,0)
	game.player.enabled=true
	game.player.reset_zoom()

func set_phase(value: String, objective: String) -> void:
	phase=value
	if is_instance_valid(game.audio_story):game.audio_story.on_phase(value)
	state_time=0
	look_back_time=0
	look_back_armed=false
	game.current_target=""
	game.prompt.text=""
	game.caption_time=0
	game.subtitle_frame.hide()
	game.set_objective(objective)

func begin_forest() -> void:
	active=true
	props.show()
	game.watcher_director.reset(game.watcher)
	game.set_door(true)
	hunger=100
	set_phase("disembark","Step off the bus.")
	game.play_sound("stall")
	save_at("forest")

func allowed() -> Array:
	match phase:
		"forage":
			var ids: Array=[]
			for i in range(3):
				if i not in fruit_taken:ids.append("fruit"+str(i))
			return ids
		"fork":return ["shortcut","take_bus"]+repairs.available()
		"town":return ["knife","shop_pizza","shop_diner","shop_mart","shop_coffee_shop"]
		"confront":return ["defend"] if knife else ["knife"]
		"mirror":return ["mirror"] if mirror_wait<=0 else []
		"escape":return ["escape","shop_pizza","shop_diner","shop_mart","shop_coffee_shop"]
		"burial":return ["grave","body"] if shovel else ["shovel","body"]
		"closet_ready":return ["closet"]
		"dawn":return ["newspaper"] if coffee else ["coffee"]
		"loop":return ["ticket"]
	return []

func update_target() -> void:
	game.current_target=""
	game.prompt.text=""
	if phase=="closet":
		game.current_target="leave_closet"
		game.prompt.text="E   Leave the closet. Stay hidden until daylight."
		return
	var best := .65
	for id in allowed():
		var spot: Dictionary=spots[id]
		var position: Vector3=spot.parent.to_global(spot.local)
		var diff: Vector3=position-game.player.camera.global_position
		var aim: float=(-game.player.camera.global_basis.z).dot(diff.normalized())
		if diff.length()<spot.radius and aim>best:
			best=aim
			game.current_target=id
			game.prompt.text=("LMB or E   " if id=="defend" else "E   ")+spot.title
	if game.current_target.is_empty() and game.seated_index<0 and game.player.get_parent()==game.bus:
		for i in range(game.seats.size()):
			if not game.passengers.can_sit(i):continue
			var diff: Vector3=game.bus.to_global(game.seats[i]+Vector3(0,.45,0))-game.player.camera.global_position
			if diff.length()<1.9 and (-game.player.camera.global_basis.z).dot(diff.normalized())>.88:
				game.current_target="seat:"+str(i)
				game.prompt.text="E   Sit down"

func interact(id: String) -> void:
	if phase=="closet" and id=="leave_closet":
		fail("You opened the door before morning.")
		return
	if id not in allowed():return
	if id.begins_with("shop_"):
		game.show_document(id)
	elif id.begins_with("part"):
		if repairs.collect(id):
			game.play_sound("rustle")
			game.set_objective(repairs.objective(),true)
			save_at("fork")
	elif id=="repair_engine":
		if repairs.taken.size()!=5:return
		set_phase("repairing","Fit the parts. Tighten the housing.")
		game.player.enabled=false
		game.play_sound("knock")
	elif id.begins_with("fruit"):
		var index := int(id.trim_prefix("fruit"))
		fruit_taken.append(index)
		hunger=minf(100,hunger+22)
		fruit_nodes[index].hide()
		game.play_sound("rustle")
		if fruit_taken.size()==3:
			hunger=100
			pursuit_grace=5
			set_phase("fork",repairs.objective())
			game.set_objective(repairs.objective(),true)
			save_at("fork")
	elif id=="shortcut":start_walking()
	elif id=="take_bus":
		if not repairs.repaired:
			game.set_objective(repairs.objective(),true)
			return
		if not game.player_aboard():
			game.set_objective("Walk through the doors to board.")
			return
		branch="bus"
		game.set_door(false)
		game.engine.play()
		game.next_stop_label.text="NEXT STOP: LOOMESVILLE"
		set_phase("bus_depart","Loomesville is the final stop.")
	elif id=="knife":
		knife=true
		ground_knife.hide()
		held_blade.show()
		attack_ready_time=0
		set_phase("confront","Knife ready. Left-click or E to defend when the attacker gets close.")
	elif id=="defend":
		game.play_sound("impact")
		held_blade.hide()
		opponent.rotation.z=PI/2
		opponent.position.y=.4
		if branch=="walk":set_phase("mirror","That was my face. Look into the mirror at the back of the room.")
		else:
			burial_remaining=180
			set_phase("burial","Take the shovel. Drag the body to the marked grave behind the house.")
			game.say("It is still moving. Bury it before it gets up.",5,true)
			save_at("burial")
	elif id=="mirror":
		if not mirror_revealed:
			mirror_revealed=true
			mirror_face.show()
			mirror_wait=1.5
			game.play_sound("mirror")
			game.set_objective("My reflection. Look again.")
			return
		mirror_count+=1
		mirror_wait=1.5
		game.play_sound("mirror")
		if mirror_count==1:
			for eye in eyes:eye.hide()
		elif mirror_count==2:
			for part in mouth_parts:part.hide()
		else:nose.hide()
		if mirror_count<3:game.set_objective("Something is missing. Look again.  "+str(mirror_count)+" of 3")
		else:set_phase("escape","There is no face left. Leave the house and follow Forestry Way.")
	elif id=="escape":transition("loop")
	elif id=="shovel":
		shovel=true
		game.set_objective("E near the body to drag it. Take it through the back door to the lantern.")
	elif id=="body":
		dragging=not dragging
		game.player.movement_scale=.65 if dragging else 1.0
		game.set_objective("Drag the body to the lantern behind the house. E at the grave to bury it." if dragging else "The body is on the ground.")
	elif id=="grave":
		if not dragging or opponent.global_position.distance_to(HOUSE+Vector3(2.2,.4,-9))>3.5:
			game.say("Bring the body here first.",3,true)
			return
		dragging=false
		game.player.movement_scale=1
		game.player.enabled=false
		set_phase("burying","Cover the grave.")
		game.play_sound("dig")
	elif id=="closet":
		place_player(HOUSE+Vector3(3.5,.15,-3.22),HOUSE+Vector3(3.5,1.5,-1))
		game.player.enabled=false
		closet_beat=0
		set_phase("closet","Stay inside. Wait for daylight and birdsong.")
	elif id=="coffee":
		coffee=true
		game.play_sound("pour")
		game.set_objective("Read the morning newspaper on the counter.")
	elif id in ["newspaper","ticket"]:game.show_document(id)

func update(delta: float) -> void:
	# Entering the district is a boundary, not a single endpoint. A side detour
	# toward the mart must end the forest encounter before any gaze check.
	if not town_entered and phase in ["return","walk","fork","jumpscare"] and in_loomesville():
		branch="walk"
		place_town(true)
	if town_entered:
		pursuer.hide()
		trail_audio.stop()
		look_back_armed=false
		look_back_time=0
	district.forestry_marker.visible=phase=="escape"
	if phase in ["dead","ending"]:return
	state_time+=delta
	mirror_wait=maxf(0,mirror_wait-delta)
	status.text=""
	if phase=="disembark":
		var local: Vector3=game.bus.to_local(game.player.global_position)
		if game.player.get_parent()!=game.bus and local.x>3.3 and game.player.global_position.y<.4:
			set_phase("hunger_cue","")
			hunger=35
			hunger_cues_played+=1
			game.play_sound("stomach")
	elif phase=="hunger_cue":
		if state_time>=1.8:
			set_phase("forage","")
			game.set_objective("Find something to eat.",true)
	elif phase=="forage":
		hunger=maxf(0,hunger-delta*.12)
		status.text="FRUIT   "+str(fruit_taken.size())+" of 3"
		if hunger<=0:fail("You waited too long. The hunger took you.")
	elif phase in ["return","walk"]:
		var goal: Vector3=Route.FOREST_FORK if phase=="return" else walking_goal()
		pursuit(delta,goal)
		if phase in ["dead","jumpscare"] or look_back_armed:return
		var destination: Vector3=Route.FOREST_FORK if phase=="return" else Route.WALK_PATH[-1]
		if game.player.global_position.distance_to(destination)<3.8:
			pursuer.hide()
			if phase=="return":
				set_phase("fork",repairs.objective())
				save_at("fork")
			else:place_town(true)
	elif phase=="fork":
		if on_walking_path():start_walking()
	elif phase=="repairing":
		if state_time>=5:
			repairs.repaired=true
			game.player.enabled=true
			game.engine.play()
			set_phase("fork",repairs.objective())
			game.set_objective(repairs.objective(),true)
			save_at("fork")
	elif phase=="jumpscare":
		update_jumpscare()
	elif phase=="bus_depart":
		game.set_door(false)
		if game.can_drive():set_phase("bus_ride","Next stop: Loomesville.")
	elif phase=="bus_ride":
		var old_z: float=game.bus.position.z
		game.bus.position.z=lerpf(-680,Route.TERMINUS_Z,smoothstep(0,Route.FINAL_RIDE_SECONDS,state_time))
		game.align_bus()
		for wheel in game.wheels:wheel.rotate_object_local(Vector3.UP,(old_z-game.bus.position.z)/.52)
		game.engine.volume_db=-15
		if state_time>=Route.FINAL_RIDE_SECONDS:
			game.engine.volume_db=-22
			game.set_door(true)
			game.next_stop_label.text="LOOMESVILLE TERMINUS"
			game.play_sound("chime")
			game.passengers.begin_stop(5)
			set_phase("arrival","Loomesville. Step off the bus to go home.")
	elif phase=="arrival":
		if game.player.get_parent()!=game.bus:transition("town")
	elif phase=="transit":
		game.transition_shade.color.a=minf(1,state_time)
		if state_time>=1.1:
			game.transition_shade.hide()
			if next_scene=="loop":place_loop()
			else:place_town()
	elif phase=="town":
		if game.player.global_position.distance_to(HOUSE+Vector3(0,.1,4.5))<4:
			set_phase("confront","There is a knife on the small table beside the doorway.")
			game.say("That's... me." if branch=="walk" else "Someone followed me home.",3)
	elif phase=="confront":
		var target: Vector3=game.player.global_position
		target.x=clampf(target.x,HOUSE.x-4,HOUSE.x+4)
		target.z=clampf(target.z,HOUSE.z-4,HOUSE.z+4)
		target.y=.12
		# Let the player find and equip the weapon before the rush begins.
		if knife:attack_ready_time+=delta
		status.text="LMB or E   DEFEND" if knife else ""
		if knife and attack_ready_time>2.5:
			opponent.position=opponent.position.move_toward(district.attack_waypoint(opponent.position,target),delta*.65)
			var face := target-opponent.position
			if face.length()>.1:opponent.rotation.y=atan2(-face.x,-face.z)
			if opponent.global_position.distance_to(game.player.global_position)<.7:fail("The attacker reached you. Use left-click or E while it is within reach.")
	elif phase in ["burial","burying"]:
		burial_remaining=maxf(0,burial_remaining-delta)
		status.text="BURY BEFORE IT WAKES   %d:%02d" % [int(burial_remaining)/60,int(burial_remaining)%60]
		if burial_remaining<=0:
			fail("It woke before the grave was closed.")
			return
		if dragging:
			var ahead: Vector3=-game.player.camera.global_basis.z
			ahead.y=0
			opponent.global_position=game.player.global_position+ahead.normalized()*1.1+Vector3(0,.3,0)
		if phase=="burying" and state_time>=8:
			opponent.hide()
			game.player.enabled=true
			grave.material_override=game.mat("4a4030")
			set_phase("closet_ready","Hide in the wardrobe. Stay inside until daylight.")
			save_at("closet")
	elif phase=="closet":
		status.text="STAY HIDDEN"
		var times := [12.0,32.0,58.0]
		if closet_beat<3 and state_time>=times[closet_beat]:
			game.play_sound("knock" if closet_beat!=1 else "cry")
			game.describe_sound(["Knocking at the wardrobe","A distant cry outside","Footsteps stop outside the door"][closet_beat])
			closet_beat+=1
		if state_time>=90:start_dawn()
	elif phase=="mirror":
		mirror_face.position.x=-3.4+clampf((game.player.global_position.x-HOUSE.x+3.4)*.1,-.15,.15)

func start_walking() -> void:
	branch="walk"
	pursuit_grace=4
	town.show()
	set_phase("walk","Follow the golden path into Loomesville.")
	game.play_sound("rustle")

func on_walking_path() -> bool:
	var at := Vector2(game.player.global_position.x,game.player.global_position.z)
	if at.distance_to(Vector2(Route.FOREST_FORK.x,Route.FOREST_FORK.z))<5:return false
	for i in range(Route.WALK_PATH.size()-1):
		var a: Vector3=Route.WALK_PATH[i]
		var b: Vector3=Route.WALK_PATH[i+1]
		if Geometry2D.get_closest_point_to_segment(at,Vector2(a.x,a.z),Vector2(b.x,b.z)).distance_to(at)<4.2:return true
	return false

func walking_goal() -> Vector3:
	# Use the next bend, not the distant endpoint, for backward-gaze detection.
	var at := Vector2(game.player.global_position.x,game.player.global_position.z)
	var best := INF
	var goal: Vector3=Route.WALK_PATH[-1]
	for i in range(Route.WALK_PATH.size()-1):
		var a: Vector3=Route.WALK_PATH[i]
		var b: Vector3=Route.WALK_PATH[i+1]
		var distance := Geometry2D.get_closest_point_to_segment(at,Vector2(a.x,a.z),Vector2(b.x,b.z)).distance_to(at)
		if distance<best:
			best=distance
			goal=b
			if at.distance_to(Vector2(b.x,b.z))<2.0 and i+2<Route.WALK_PATH.size():goal=Route.WALK_PATH[i+2]
	return goal

func try_defend() -> bool:
	if phase!="confront" or not knife:return false
	var delta: Vector3=opponent.global_position+Vector3(0,1.2,0)-game.player.camera.global_position
	if delta.length()>2.8 or (-game.player.camera.global_basis.z).dot(delta.normalized())<.45:return false
	interact("defend")
	return true

func pursuit(delta: float, goal: Vector3) -> void:
	if town_entered or in_loomesville():
		pursuer.hide()
		trail_audio.stop()
		look_back_armed=false
		return
	pursuit_grace=maxf(0,pursuit_grace-delta)
	var ahead: Vector3=goal-game.player.global_position
	ahead.y=0
	ahead=ahead.normalized()
	var looking: Vector3=-game.player.camera.global_basis.z
	looking.y=0
	var backwards := looking.normalized().dot(ahead)<-.45
	# The empty view is the setup. Looking alone never opens a failure screen.
	pursuer.hide()
	if not look_back_armed:
		look_back_time=look_back_time+delta if backwards and pursuit_grace<=0 else 0.0
		if look_back_time>=.35:
			look_back_armed=true
			look_back_origin=game.player.global_position
	else:
		var movement: Vector3=game.player.global_position-look_back_origin
		if Vector2(movement.x,movement.z).length()>=.18:
			set_phase("jumpscare","")
			game.player.enabled=false
			game.player.velocity=Vector3.ZERO
			game.player.reset_zoom()
			trail_audio.stop()
			update_jumpscare()
			return
	var distance := lerpf(5.5,2.15,clampf(state_time/35.0,0,1)) if phase=="walk" else 7.0
	pursuer.position=game.player.global_position-ahead*distance+ahead.cross(Vector3.UP)*sin(state_time*.7)*.4
	trail_audio.volume_db=-2.5 if phase=="walk" else -7.0
	trail_audio.unit_size=7 if phase=="walk" else 5
	sound_clock-=delta
	if sound_clock<=0:
		trail_audio.play()
		sound_clock=2.4

func update_jumpscare() -> void:
	if town_entered or in_loomesville():
		place_town(true)
		return
	var camera: Camera3D=game.player.camera
	var forward: Vector3=-camera.global_basis.z
	forward.y=0
	forward=forward.normalized()
	pursuer.show()
	pursuer.position=camera.global_position+forward*lerpf(3.3,.62,smoothstep(0,.3,state_time))-Vector3(0,1.83,0)
	pursuer.rotation.y=atan2(forward.x,forward.z)
	for i in [1,3]:
		scare_limbs[i].rotation.x=lerpf(.1,1.45,smoothstep(0,.3,state_time))
		scare_limbs[i].rotation.z=-.18 if i==1 else .18
	game.transition_shade.color=Color(0,0,0,clampf((state_time-.55)*5,0,1))
	game.transition_shade.show()
	if state_time>=.9:
		pursuer.hide()
		fail("There was nothing behind you. Then you moved.")

func transition(destination: String) -> void:
	set_phase("transit","")
	next_scene=destination
	game.player.enabled=false
	game.transition_shade.color=Color(0,0,0,0)
	game.transition_shade.show()
	pursuer.hide()

func in_loomesville() -> bool:
	var at: Vector3=game.player.global_position
	return at.x>=96 and at.x<=166 and at.z<=-698 and at.z>=-808

func place_town(keep_position: bool=false) -> void:
	town_entered=true
	look_back_armed=false
	look_back_time=0
	game.transition_shade.hide()
	game.player.enabled=true
	game.watcher_director.reset(game.watcher)
	mirror_revealed=false
	mirror_face.hide()
	active=true
	town.show()
	# Keep the travelled trail visible at the edge of town.
	props.visible=keep_position
	pursuer.hide()
	opponent.show()
	double_model.visible=branch=="walk"
	intruder_model.visible=branch=="bus"
	opponent.position=HOUSE+Vector3(0,.12,-1)
	opponent.rotation=Vector3.ZERO
	knife=false
	ground_knife.show()
	attack_ready_time=0
	held_blade.hide()
	game.engine.stop()
	trail_audio.stop()
	game.player.movement_scale=1
	if not keep_position:place_player(Vector3(120,.15,-739),HOUSE+Vector3(0,1,5))
	set_phase("town","Follow the footprints to house 17.")
	save_at("town")

func place_loop() -> void:
	active=true
	town.hide()
	props.show()
	opponent.hide()
	pursuer.hide()
	daylight(true)
	game.bus.position.z=65
	game.align_bus()
	place_player(Vector3(5,.25,1.5),Vector3(5.35,.9,-.45))
	set_phase("loop","Morning. The shelter again. There is a ticket on the bench.")
	save_at("loop")

func start_dawn() -> void:
	daylight(true)
	game.play_sound("birds")
	place_player(HOUSE+Vector3(3.5,.15,-1.4),HOUSE+Vector3(3.5,1.2,3))
	set_phase("dawn","Daylight. It is quiet. Make coffee, then read the newspaper.")
	save_at("dawn")

func document_closed(kind: String) -> void:
	if kind=="ticket" and phase=="loop":complete("THE LAST SERVICE","One passenger. One ticket.\nDestination: Loomesville.\n\nThe clock is still 02:36.")
	elif kind=="newspaper" and phase=="dawn":complete("THE MORNING EDITION","The newspaper names you as the suspect.\nYou remember the ride.\nYou cannot remember lighting the match.")

func fail(reason: String) -> void:
	game.transition_shade.hide()
	game.transition_shade.color=Color(0,0,0,0)
	trail_audio.stop()
	set_phase("dead",reason)
	game.player.movement_scale=1
	held_blade.hide()
	game.show_menu(true)
	game.menu_page="result"
	game.clear_box(game.menu_box)
	game.menu_heading("THE NIGHT TOOK YOU")
	var copy: Label=game.label(reason,20)
	copy.custom_minimum_size.x=360
	copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.menu_box.add_child(copy)
	game.menu_box.add_child(game.button("RETRY CHECKPOINT",game.continue_game))
	game.menu_box.add_child(game.button("MAIN MENU",game.return_to_title))
	game.menu_box.add_child(game.button("EXIT TO WINDOWS",game.quit_cleanly))
	game.focus_first()

func complete(title: String, copy: String) -> void:
	set_phase("ending","")
	game.show_menu(true)
	game.menu_page="result"
	game.clear_box(game.menu_box)
	game.menu_heading(title)
	game.menu_box.add_child(game.label(copy,18))
	game.menu_spacer(18)
	game.menu_box.add_child(game.button("TRY THE OTHER PATH",func():
		game.start_game(Story.Stage.DEER)
		restore({"phase":"fork","branch":""})))
	game.menu_box.add_child(game.button("MAIN MENU",game.return_to_title))
	game.menu_box.add_child(game.button("EXIT TO WINDOWS",game.quit_cleanly))
	game.focus_first()
