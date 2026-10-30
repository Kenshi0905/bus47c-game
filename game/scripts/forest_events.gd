extends Node3D
const Route=preload("res://scripts/route.gd")
const PATH=[Vector3(111,0,-760),Vector3(111,0,-789),Vector3(112,0,-802),Vector3(105,0,-813),Vector3(91,0,-828),Vector3(76,0,-843)]
var game
var after
var hazard: Node3D
var animal_face: Node3D
var human_face: Node3D
var hazard_seen := false
var hazard_away := false
var hazard_changed := false
var seen_inventory := 0
var boundary_age := 0.0
var trail_index := 0
var prints: Node3D
var print_origin := Vector3.ZERO
var print_side := 1
var blood_steps := false
var arrow: Label
var arrow_copy: Label
var blur: ColorRect
var blur_material: ShaderMaterial
var own_body: Node3D
var start_yaw := 0.0
var start_pitch := 0.0
var start_height := 1.57
var fall_origin := Vector3.ZERO

func setup(g,a) -> void:
	game=g
	after=a
	name="ForestEvents"
	prints=Node3D.new()
	add_child(prints)
	build_hazard()
	build_trail()
	arrow=game.label("▲",26,Color("d1bd83"))
	arrow.size=Vector2(36,36)
	arrow.pivot_offset=Vector2(18,18)
	game.hud.add_child(arrow)
	arrow_copy=game.label("",15,Color("d1bd83"))
	game.hud.add_child(arrow_copy)
	var ui: Control=game.transition_shade.get_parent()
	blur=ColorRect.new()
	ui.add_child(blur)
	ui.move_child(blur,game.transition_shade.get_index())
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter=Control.MOUSE_FILTER_IGNORE
	blur_material=ShaderMaterial.new()
	blur_material.shader=preload("res://assets/ui/failing_vision.gdshader")
	blur.material=blur_material
	own_body=preload("res://scripts/transformation_body.gd").new()
	add_child(own_body)
	own_body.setup(game)
	reset()

func reset() -> void:
	hazard_seen=false
	hazard_away=false
	hazard_changed=false
	seen_inventory=0
	boundary_age=0
	trail_index=0
	blood_steps=false
	for child in prints.get_children():child.free()
	if is_instance_valid(animal_face):animal_face.show()
	if is_instance_valid(human_face):human_face.hide()
	if is_instance_valid(arrow):arrow.hide()
	if is_instance_valid(arrow_copy):arrow_copy.hide()
	if is_instance_valid(blur):blur.hide()
	if is_instance_valid(own_body):own_body.reset()
	game.player.camera.rotation.z=0

func triangle(parent: Node3D, size: float, z: float, color: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(0,size*.6,z),Vector3(-size*.58,-size*.4,z),Vector3(size*.58,-size*.4,z)]:
		surface.set_normal(Vector3(0,0,1))
		surface.add_vertex(point)
	var mesh := MeshInstance3D.new()
	mesh.mesh=surface.commit()
	mesh.material_override=game.mat(color)
	mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	parent.add_child(mesh)

func stroke(parent: Node3D, a: Vector3, b: Vector3, width: float, color: String) -> void:
	var mesh: MeshInstance3D=game.block(parent,(a+b)*.5,Vector3(width,a.distance_to(b),.018),color)
	mesh.rotation.z=-atan2(b.x-a.x,b.y-a.y)
	if color in ["98271d","731911","bb4930","7e2118","a82118","771411"]:
		mesh.material_override=preload("res://scripts/blood_palette.gd").material()

func build_hazard() -> void:
	hazard=Node3D.new()
	after.props.add_child(hazard)
	hazard.name="ChangingAnimalWarning"
	hazard.position=Route.point(4.9,0,-686)
	hazard.rotation.y=PI*.3
	game.block(hazard,Vector3(0,1,0),Vector3(.1,2,.1),"6b6d5a")
	var panel := Node3D.new()
	hazard.add_child(panel)
	panel.position.y=2.05
	triangle(panel,1.6,0,"18211c")
	triangle(panel,1.4,.02,"c5a246")
	animal_face=Node3D.new()
	panel.add_child(animal_face)
	# Small editable animal silhouette and hoof marks.
	game.block(animal_face,Vector3(-.04,-.01,.06),Vector3(.6,.22,.04),"23261d")
	game.block(animal_face,Vector3(.29,.19,.06),Vector3(.14,.38,.04),"23261d").rotation.z=.3
	game.block(animal_face,Vector3(.38,.36,.06),Vector3(.23,.13,.04),"23261d")
	for x in [-.27,.16]:stroke(animal_face,Vector3(x,-.06,.06),Vector3(x-.07,-.34,.06),.045,"23261d")
	game.text3(animal_face,"ANIMAL CROSSING",Vector3(0,-.88,.07),25,Color("d0b771")).pixel_size=.0034
	game.block(animal_face,Vector3(0,-.88,0),Vector3(1.8,.28,.08),"29332a")
	human_face=Node3D.new()
	panel.add_child(human_face)
	var portrait: Node3D=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	human_face.add_child(portrait)
	portrait.position=Vector3(0,-.7,.08)
	portrait.rotation.y=PI
	portrait.scale=Vector3(.46,.46,.05)
	for part in portrait.find_children("*","MeshInstance3D",true,false):
		if part.get_aabb().get_center().y<1.1:part.hide()
	# Unequal finger-painted strokes, with torn edges and smeared second passes.
	var rng := RandomNumberGenerator.new()
	rng.seed=473609
	for side in [-1,1]:
		var a := Vector3(-.48,-.43*side,.15)
		var b := Vector3(.43,.49*side,.15)
		var last := a
		for i in range(1,19):
			var t := float(i)/18
			var next := a.lerp(b,t)+Vector3(rng.randf_range(-.025,.025),rng.randf_range(-.018,.018),0)
			var width := rng.randf_range(.036,.074)*(1-.45*t)
			stroke(human_face,last,next,width,"98271d" if i%4 else "731911")
			stroke(human_face,last+Vector3(.019,0,.004),next+Vector3(.032,0,.004),width*.18,"bb4930")
			last=next
	for i in range(7):
		var at := Vector3(rng.randf_range(-.35,.4),rng.randf_range(-.35,.25),.155)
		stroke(human_face,at,at+Vector3(-.013,-rng.randf_range(.04,.18),0),.009,"7e2118")
	# Scratched blood lettering, retained as individually editable strokes.
	var letters=[[[0,0],[0,1],[.55,.85],[0,.52],[.55,.25],[0,0]],[[.55,1],[0,1],[0,0],[.55,0],[0,0],[0,.5],[.4,.5]],[[0,1],[.12,0],[.3,.5],[.48,0],[.6,1]],[[0,0],[.3,1],[.6,0],[.47,.4],[.14,.4]],[[0,0],[0,1],[.55,.8],[0,.5],[.55,0]],[[.55,1],[0,1],[0,0],[.55,0],[0,0],[0,.5],[.4,.5]]]
	for i in range(letters.size()):
		for j in range(letters[i].size()-1):
			var a: Array=letters[i][j]
			var b: Array=letters[i][j+1]
			stroke(human_face,Vector3(-.86+i*.3+a[0]*.38,-1.03+a[1]*.31,.13),Vector3(-.86+i*.3+b[0]*.38,-1.03+b[1]*.31,.13),.028,"a82118")
	game.block(human_face,Vector3(0,-.89,.01),Vector3(1.95,.45,.08),"c2ae75")
	for i in range(6):stroke(human_face,Vector3(-.6+i*.24,-.95,.15),Vector3(-.61+i*.24,-1.2-float(i%3)*.06,.15),.019,"771411")
	game.light(hazard,Vector3(0,2.2,1.1),Color("c3aa73"),.85,4)

func build_trail() -> void:
	var root := Node3D.new()
	after.town.add_child(root)
	root.name="WalkableForestryWay"
	var continuous := PATH.duplicate()
	continuous.append_array([Vector3(61,0,-853),Vector3(51,0,-875),Vector3(56,0,-906)])
	preload("res://scripts/path_surface.gd").build(root,continuous,2.1,game.mat("4e4938"))
	for i in range(continuous.size()-1):
		for side in [-1,1]:
			var edge: Vector3=(continuous[i+1]-continuous[i]).normalized().cross(Vector3.UP)*1.4*side
			for t in [.2,.7]:
				var stone: MeshInstance3D=game.block(root,continuous[i].lerp(continuous[i+1],t)+edge+Vector3(0,.09,0),Vector3(.3,.18,.35),"414a40")
				stone.rotation.y=i*1.8
	for i in range(PATH.size()-1):
		for t in [.25,.7]:after.lantern(root,PATH[i].lerp(PATH[i+1],t)+Vector3(1.5,0,0))
	# A forgotten forestry checkpoint and a shallow culvert give the trail a history.
	var shelter := Node3D.new()
	root.add_child(shelter)
	shelter.position=Vector3(114,0,-793)
	for x in [-1.1,1.1]:game.block(shelter,Vector3(x,1.2,0),Vector3(.12,2.4,.12),"514d38")
	game.block(shelter,Vector3(0,2.45,0),Vector3(2.8,.12,1.5),"333b32")
	game.block(shelter,Vector3(0,.55,0),Vector3(2.1,.12,.55),"63573e")
	game.block(shelter,Vector3(0,1.65,-.08),Vector3(1.7,.65,.09),"473f31")
	game.text3(shelter,"FIREWATCH SECTOR 17",Vector3(0,1.65,.0),25).pixel_size=.003
	game.block(shelter,Vector3(.6,.72,0),Vector3(.28,.23,.18),"42473c")
	game.block(shelter,Vector3(.65,1.05,0),Vector3(.015,.5,.015),"777b64")
	for side in [-1,1]:
		for i in range(5):
			game.block(root,Vector3(107+side*1.7, .45,-808-i),Vector3(.1,.9,.1),"5d5140")
		game.block(root,Vector3(107+side*1.7,.8,-810),Vector3(.08,.08,4.4),"5d5140")
	var tree_mesh: ArrayMesh=game.forest.pine_mesh()
	for i in range(90):
		var t := float(i%45)/44
		var at: Vector3=PATH[2].lerp(PATH[-1],t)+Vector3((4.5+absf(sin(i*17))*8)*(1 if i<45 else -1),0,sin(i*11)*3)
		var tree := MeshInstance3D.new()
		tree.mesh=tree_mesh
		root.add_child(tree)
		tree.position=at
		tree.scale=Vector3.ONE*(.7+absf(sin(i*3))*.6)

func observe_hazard() -> void:
	if hazard_changed or after.phase not in ["disembark","hunger_cue","forage","fork","repairing"]:return
	var camera: Camera3D=game.player.camera
	var difference: Vector3=hazard.global_position+Vector3(0,2,0)-camera.global_position
	var watching := difference.length()<30 and (-camera.global_basis.z).dot(difference.normalized())>.86
	var inventory: int=after.fruit_taken.size()+after.repairs.taken.size()
	if watching and not hazard_seen:
		hazard_seen=true
		seen_inventory=inventory
	elif hazard_seen and not watching:hazard_away=true
	if hazard_away and inventory>seen_inventory and not watching:
		hazard_changed=true
		animal_face.hide()
		human_face.show()
		game.save_checkpoint()

func start_trail() -> void:
	trail_index=0
	after.set_phase("forestry_walk","Follow Forestry Way.")
	game.set_objective("Follow Forestry Way.",true)
	after.save_at("escape")

func start_fall(kind: String) -> void:
	start_yaw=game.player.rotation.y
	start_pitch=game.player.camera.rotation.x
	start_height=game.player.camera.position.y
	game.player.enabled=false
	game.player.velocity=Vector3.ZERO
	game.player.reset_zoom()
	after.trail_audio.stop()
	after.set_phase(kind,"")
	if kind=="backstab":
		after.pursuer.show()
		after.pursuer.global_position=game.player.global_position+game.player.global_basis.z*1.5
		game.play_sound("impact")
	else:
		fall_origin=game.player.global_position
		var forward := Basis(Vector3.UP,start_yaw)*Vector3.FORWARD
		var landing: Vector3=fall_origin+forward*1.70
		landing.y=.72
		own_body.begin(landing,start_yaw)

func update(delta: float) -> void:
	observe_hazard()
	if after.phase in ["forage","fork"] and not after.town_entered:
		var at: Vector3=game.player.global_position
		var range_value := pow((at.x-21)/27,2)+pow((at.z+689)/31,2)
		boundary_age=boundary_age+delta if range_value>1.0 and not game.player_aboard() else 0
		if boundary_age>1.4:start_fall("backstab")
	else:boundary_age=0
	if blood_steps and after.phase in ["escape","forestry_walk"] and game.player.walking_now:
		var at: Vector3=game.player.global_position
		if Vector2(at.x-print_origin.x,at.z-print_origin.z).length()>.8:
			add_footprint(at,game.player.rotation.y)
			print_origin=at
	if after.phase=="escape" and game.player.global_position.distance_to(PATH[0])<3.2:start_trail()
	if after.phase=="forestry_walk":
		if game.player.global_position.distance_to(PATH[trail_index])<2.5:
			trail_index+=1
			if trail_index>=PATH.size():start_fall("forestry_fall")
		if trail_index<PATH.size():set_blur(maxf(0,float(trail_index-2))*.6,0,0)
	elif after.phase in ["backstab","forestry_fall","waking"]:update_cutscene()
	update_arrow()

func set_blur(amount: float, dark: float, hurt: float) -> void:
	blur.visible=amount>0 or dark>0 or hurt>0
	blur_material.set_shader_parameter("strength",amount)
	blur_material.set_shader_parameter("darkness",dark)
	blur_material.set_shader_parameter("hurt",hurt)

func update_cutscene() -> void:
	var t: float=after.state_time
	var camera: Camera3D=game.player.camera
	if after.phase=="backstab":
		camera.position.y=lerpf(start_height,.24,smoothstep(.2,1.5,t))
		game.player.rotation.y=start_yaw+PI*smoothstep(.6,2.0,t)
		camera.rotation=Vector3(lerpf(start_pitch,.75,smoothstep(.9,2.1,t)),0,lerpf(0,-.48,smoothstep(.2,1.5,t)))
		after.pursuer.look_at(Vector3(camera.global_position.x,after.pursuer.global_position.y,camera.global_position.z))
		set_blur(smoothstep(.5,4.4,t)*6,clampf((t-4.2)*.9,0,.85),smoothstep(0,.4,t))
		if t>=5.3:
			blur.hide()
			after.fail("You strayed too far from the bus.")
	elif after.phase=="forestry_fall":
		camera.global_position=(fall_origin+Vector3.UP*start_height).lerp(own_body.torso.to_global(Vector3(0,.24,-.32)),smoothstep(.15,1.6,t))
		camera.rotation=Vector3(lerpf(start_pitch,-.44,smoothstep(.3,2,t)),0,.07*sin(minf(t,3)*.45))
		game.player.rotation.y=start_yaw
		own_body.animate(t)
		set_blur(.45+sin(t*1.7)*.2+smoothstep(8,11,t)*5,smoothstep(10,12,t),0)
		if t>=12:
			own_body.hide()
			after.place_loop()
			after.set_phase("waking","")
			game.player.enabled=false
			game.play_sound("birds")
	else:
		camera.position.y=lerpf(.45,1.57,smoothstep(0,3,t))
		camera.rotation.z=0
		set_blur((1-smoothstep(0,3,t))*4,1-smoothstep(0,2,t),0)
		if t>=3:
			after.set_phase("loop","Morning. The shelter again. There is a ticket on the bench.")
			game.player.enabled=true
			blur.hide()

func update_arrow() -> void:
	var visible: bool=after.phase in ["escape","forestry_walk"] and not game.paused and not game.modal
	arrow.visible=visible
	arrow_copy.visible=visible
	if not visible:return
	var target: Vector3=PATH[mini(trail_index,PATH.size()-1)]+Vector3.UP
	if after.phase=="escape" and game.player.global_position.z<after.HOUSE.z+6:target=after.HOUSE+Vector3(0,1,7.4)
	var camera: Camera3D=game.player.camera
	var local: Vector3=camera.to_local(target)
	var angle := atan2(local.x,-local.z)
	arrow.position=Vector2(622+sin(angle)*160,112)
	arrow.rotation=angle
	arrow_copy.position=Vector2(536,154)
	arrow_copy.text="FORESTRY WAY   %d m" % int(camera.global_position.distance_to(target))

func add_footprint(at: Vector3, yaw: float) -> void:
	var step := Node3D.new()
	prints.add_child(step)
	step.position=Vector3(at.x,.085,at.z)+Basis(Vector3.UP,yaw)*Vector3(print_side*.15,0,0)
	step.rotation.y=yaw
	print_side=-print_side
	for patch in [game.block(step,Vector3(0,0,-.1),Vector3(.16,.012,.23),"bd241e"),game.block(step,Vector3(0,0,.09),Vector3(.13,.012,.11),"bd241e")]:
		patch.material_override=preload("res://scripts/blood_palette.gd").material()
	if prints.get_child_count()>220:prints.get_child(0).free()
