extends Node3D
const Story = preload("res://scripts/story.gd")
const Player = preload("res://scripts/player.gd")
const SAVE := "user://checkpoint.json"
var story = Story.new()
var player: CharacterBody3D
var bus: Node3D
var trees: Array[Node3D] = []
var targets: Dictionary = {}
var passenger: Node3D
var watcher: Node3D
var door_hinges: Array[Node3D] = []
var wheels: Array[MeshInstance3D] = []
var door_amount := 0.0
var door_goal := 0.0
var door_collider: CollisionShape3D
var ramp_collider: CollisionShape3D
var boarding_ramp: Node3D
var steps_node: Node3D
var seated_passengers: Array[Node3D] = []
var stop_figures: Array[Node3D] = []
var next_stop_label: Label3D
var deer: Node3D
var menu_shade: ColorRect
var step_index := 0
var running := false
var paused := false
var modal := false
var current_target := ""
var caption_time := 0.0
var reveal_delay := -1.0
var hud: Control
var objective: Label
var prompt: Label
var subtitle: Label
var clock_label: Label
var menu: PanelContainer
var menu_box: VBoxContainer
var modal_panel: PanelContainer
var modal_box: VBoxContainer
var ambience: AudioStreamPlayer
var engine: AudioStreamPlayer
var drone: AudioStreamPlayer
var sfx: AudioStreamPlayer
var footsteps: AudioStreamPlayer
var material_cache: Dictionary = {}
var view_width := 1280.0

func _ready() -> void:
	_setup_inputs()
	_build_world()
	_build_ui()
	_build_audio()
	set_door(false,true)
	bus.position.z=0
	player.position=Vector3(8,.1,-10)
	player.camera.look_at(Vector3(0,1.8,-1))
	show_menu(false)
	if "--smoke" in OS.get_cmdline_user_args(): call_deferred("smoke_test")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_preview")

func _setup_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "interact": KEY_E, "pause_game": KEY_ESCAPE}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)

func mat(color: String, glow: bool = false) -> StandardMaterial3D:
	var key := color + str(glow)
	if material_cache.has(key): return material_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.9
	if glow:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = 1.4
	material_cache[key] = m
	return m

func block(parent: Node3D, pos: Vector3, size: Vector3, color: String, solid: bool = false, glow: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat(color, glow)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		mesh.add_child(body)
	return mesh

func text3(parent: Node3D, value: String, pos: Vector3, size: int = 40, color: Color = Color("d4c49b")) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.font_size = size
	label.pixel_size = 0.006
	label.modulate = color
	label.no_depth_test = false
	label.outline_size = 3
	parent.add_child(label)
	label.position = pos
	return label

func light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.shadow_enabled = false
	parent.add_child(lamp)
	lamp.position = pos

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("09121c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("658096")
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("172832")
	env.fog_density = 0.013
	world.environment = env
	add_child(world)
	var moonlight := DirectionalLight3D.new()
	moonlight.rotation_degrees = Vector3(-38, -25, 0)
	moonlight.light_color = Color("91acc4")
	moonlight.light_energy = 0.25
	add_child(moonlight)
	var moon := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.0
	sphere.height = 4.0
	moon.mesh = sphere
	moon.material_override = mat("b4c5c7", true)
	add_child(moon)
	moon.position = Vector3(-25, 24, -60)
	block(self, Vector3(0,-0.2,0), Vector3(160,0.4,1200), "18231c", true)
	block(self, Vector3(-1.2,0.01,0), Vector3(7.4,0.03,1200), "252b2c")
	for z in range(-550, 101, 5): block(self, Vector3(-1.65,0.035,z), Vector3(0.13,0.015,2.6), "c7b784")
	for x in [-4.8,2.4]: block(self,Vector3(x,.035,-220),Vector3(.08,.015,650),"929b8c")
	for z in range(-540,100,20):
		for x in [-5.1,2.9]:
			block(self,Vector3(x,.4,z),Vector3(.07,.8,.07),"77877b")
			block(self,Vector3(x,.72,z),Vector3(.09,.1,.09),"bdac73",false,true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 470236
	for i in range(650):
		var tree := Node3D.new()
		add_child(tree)
		var side := -1 if i % 2 == 0 else 1
		tree.position = Vector3(side*rng.randf_range(8,48),0,rng.randf_range(-550,100))
		var height := rng.randf_range(4.5,10)
		block(tree,Vector3(0,height*0.35,0),Vector3(.22,height*.7,.22),"343831")
		for tier in range(3):
			var crown := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0
			cone.bottom_radius = (2.4-tier*.5)*height/8
			cone.height = height*.5
			cone.radial_segments = 5
			crown.mesh = cone
			crown.visibility_range_end=105
			crown.material_override = mat("20372b" if i%3 else "2b4031")
			tree.add_child(crown)
			crown.position.y = height*(.45+tier*.19)
		trees.append(tree)
	_build_shelter()
	_build_bus()
	player = Player.new()
	add_child(player)
	player.position = Vector3(5.0,.1,4.2)
	player.rotation.y = 0.0
	player.footstep.connect(footfall)
	watcher = load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	add_child(watcher)
	watcher.position = Vector3(-8,0,-10)
	watcher.rotation.y = PI/2
	watcher.visible = false
	roadside_stop(-133,"MILL ROAD",-5.0)
	roadside_stop(-273,"OLD QUARRY",3.4)
	deer=load("res://assets/deer.gltf").instantiate()
	add_child(deer)
	deer.position=Vector3(.3,.33,-397)
	deer.rotation.z=PI/2
	deer.visible=false

func _build_shelter() -> void:
	var shelter := Node3D.new()
	add_child(shelter)
	shelter.position = Vector3(5,0,0)
	block(shelter,Vector3(0,.1,0),Vector3(3.8,.2,2.2),"52534b",true)
	for x in [-1.7,1.7]:
		for z in [-.9,.9]: block(shelter,Vector3(x,1.4,z),Vector3(.09,2.6,.09),"546361",true)
	block(shelter,Vector3(0,2.78,0),Vector3(3.9,.16,2.4),"35483f",true)
	block(shelter,Vector3(0,1.5,-.95),Vector3(3.5,2.3,.08),"263b3d",true)
	block(shelter,Vector3(0,.67,-.5),Vector3(2.8,.15,.55),"6e5e45",true)
	block(shelter,Vector3(0,1.05,-.75),Vector3(2.8,.6,.1),"6e5e45",true)
	block(shelter,Vector3(.35,.755,-.45),Vector3(.36,.015,.26),"d8cba2")
	text3(shelter,"LOOMESVILLE FOREST",Vector3(0,2.35,-.88),28)
	text3(shelter,"LAST SERVICE  /  47C",Vector3(0,2.08,-.88),22)
	light(shelter,Vector3(0,2.5,0),Color("e6c289"),1.6,6)
	block(shelter,Vector3(0,2.65,0),Vector3(1.3,.035,.12),"e3ce9b",false,true)
	targets["note"] = [shelter, Vector3(.35,.95,-.45)]

func _build_bus() -> void:
	bus = Node3D.new()
	bus.name = "Bus47C"
	add_child(bus)
	bus.position.z = 65
	block(bus,Vector3(0,.67,0),Vector3(2.7,.2,9.2),"31372f",true)
	block(bus,Vector3(0,3.05,0),Vector3(2.8,.16,9.3),"b8b5a0",true)
	# The right wall has an actual 1.6m doorway, including its collision.
	for side in [-1,1]:
		var segments := [[0.0,9.2]] if side == -1 else [[-4.2,.8],[1.2,6.8]]
		for segment in segments:
			block(bus,Vector3(side*1.35,1.16,segment[0]),Vector3(.1,.85,segment[1]),"3e5d50",true)
			block(bus,Vector3(side*1.35,1.67,segment[0]),Vector3(.1,.18,segment[1]),"a9aa90")
			glass(bus,Vector3(side*1.35,2.32,segment[0]),Vector3(.025,1.1,segment[1]))
		var pillars := [-4.55,-3.8,-2.2,-.7,.8,2.3,3.8,4.55]
		for z in pillars: block(bus,Vector3(side*1.35,2.35,z),Vector3(.1,1.35,.07),"a9aa90")
		for z in [-1.5,2.9]:
			var wheel := MeshInstance3D.new()
			var tire := CylinderMesh.new()
			tire.top_radius=.52
			tire.bottom_radius=.52
			tire.height=.22
			tire.radial_segments=12
			wheel.mesh=tire
			wheel.material_override=mat("191e20")
			bus.add_child(wheel)
			wheel.position=Vector3(side*1.38,.52,z)
			wheel.rotation.z=PI/2
			wheels.append(wheel)
		for z in [-1.9,-.65,.6,1.85,3.1]:
			block(bus,Vector3(side*.87,1.12,z),Vector3(.68,.17,.65),"526359",true)
			block(bus,Vector3(side*.87,1.58,z+.3),Vector3(.7,.95,.13),"46584f",true)
			block(bus,Vector3(side*.87,.89,z),Vector3(.1,.4,.3),"6d7470")
	block(bus,Vector3(0,1.15,-4.55),Vector3(2.7,.8,.12),"b8b5a0",true)
	glass(bus,Vector3(0,2.25,-4.55),Vector3(2.55,1.35,.025))
	block(bus,Vector3(0,2.25,-4.56),Vector3(.045,1.4,.05),"66736a")
	block(bus,Vector3(0,1.8,4.55),Vector3(2.7,2.4,.1),"3e5d50",true)
	block(bus,Vector3(0,2.95,-4.62),Vector3(2,.18,.08),"172423")
	var route := text3(bus,"47C  LOOMESVILLE",Vector3(0,2.96,-4.68),30)
	route.pixel_size=.003
	route.rotation.y=PI
	for x in [-.9,.9]:
		block(bus,Vector3(x,1.22,-4.66),Vector3(.35,.2,.04),"e7d5a6",false,true)
		var headlight := SpotLight3D.new()
		bus.add_child(headlight)
		headlight.position=Vector3(x,1.3,-4.7)
		headlight.rotation.x=-.08
		headlight.light_color=Color("eadbb3")
		headlight.light_energy=3.0
		headlight.spot_range=38
		headlight.spot_angle=32
	block(bus,Vector3(-.65,1.13,-3.5),Vector3(.65,.2,.6),"393f3b",true)
	block(bus,Vector3(-.65,1.55,-3.2),Vector3(.65,.85,.14),"393f3b",true)
	block(bus,Vector3(0,1.4,-4.12),Vector3(2.2,.2,.5),"252e2d",true)
	block(bus,Vector3(-.65,1.66,-3.85),Vector3(.4,.05,.3),"171f20")
	block(bus,Vector3(.48,1.63,-3.95),Vector3(.38,.18,.08),"111c1d")
	var clock := text3(bus,"02:36",Vector3(.48,1.65,-3.9),30,Color("d6b67b"))
	clock.pixel_size=.002
	clock.outline_size=0
	next_stop_label=text3(bus,"NEXT  /  MILL ROAD",Vector3(0,2.9,-4.38),24)
	next_stop_label.pixel_size=.0025
	text3(bus,"47C  /  NIGHT SERVICE",Vector3(0,2.72,4.42),20).rotation.y=PI
	for z in [-2,1,3.5]:
		block(bus,Vector3(0,2.92,z),Vector3(.65,.035,.13),"e2cca2",false,true)
		light(bus,Vector3(0,2.7,z),Color("ddc69a"),.36,3.5)
	# Twin hinged leaves. Only the dedicated closed-door collider seals the opening.
	for index in range(2):
		var hinge := Node3D.new()
		bus.add_child(hinge)
		hinge.position=Vector3(1.35,.78,-3.8 if index==0 else -2.2)
		var dz := .4 if index==0 else -.4
		block(hinge,Vector3(0,.46,dz),Vector3(.065,.92,.78),"466353")
		var pane := block(hinge,Vector3(0,1.5,dz),Vector3(.035,1.1,.72),"718d89")
		var dm := StandardMaterial3D.new()
		dm.albedo_color=Color(.3,.5,.5,.15)
		dm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		pane.material_override=dm
		for edge in [-.38,.38]: block(hinge,Vector3(0,1.2,dz+edge),Vector3(.075,2.4,.045),"a0aa93")
		door_hinges.append(hinge)
	var seal := block(bus,Vector3(1.35,1.95,-3),Vector3(.08,2.4,1.6),"172423",true)
	seal.visible=false
	door_collider=seal.get_child(0).get_child(0)
	boarding_ramp=block(bus,Vector3(2.5,.44,-3),Vector3(2.3,.06,1.5),"53584d",true)
	boarding_ramp.rotation.z=-atan(1.02/2.0)
	boarding_ramp.visible=false
	ramp_collider=boarding_ramp.get_child(0).get_child(0)
	steps_node=Node3D.new()
	bus.add_child(steps_node)
	for i in range(5):
		block(steps_node,Vector3(3.15-i*.38,.09+i*.18,-3),Vector3(.4,.18,1.5),"697065")
		block(steps_node,Vector3(3.33-i*.38,.185+i*.18,-3),Vector3(.035,.02,1.5),"c1ab6b")
	targets["door"]=[bus,Vector3(1.5,1.5,-3)]
	targets["driver"]=[bus,Vector3(-.65,1.65,-3.5)]
	targets["clock"]=[bus,Vector3(.48,1.65,-3.9)]
	targets["route"]=[bus,Vector3(0,2.9,-4.38)]
	targets["deer"]=[bus,Vector3(0,1.9,-4.45)]
	var models := ["01_grinning_clerk","03_long_neck_worker","04_crooked_passenger"]
	for i in range(3):
		var person: Node3D=load("res://assets/characters/"+models[i]+"_seated.gltf").instantiate()
		bus.add_child(person)
		person.position=Vector3(.87 if i%2==0 else -.87,.77,3.1 if i<2 else 1.85)
		person.visible=false
		seated_passengers.append(person)
	passenger=seated_passengers[0]
	targets["passenger"]=[bus,Vector3(.87,1.9,3.1)]


func _build_audio() -> void:
	ambience = audio("forest",-15,true)
	engine = audio("engine",-19,true)
	drone = audio("drone",-24,true)
	sfx = audio("door",-9,false)
	footsteps = audio("step",-14,false)

func audio(file: String, volume: float, looped: bool) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	var stream = load("res://assets/audio/"+file+".wav").duplicate()
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size()/2
	a.stream = stream
	a.volume_db = volume
	add_child(a)
	return a

func play_sound(file: String) -> void:
	sfx.stream = load("res://assets/audio/"+file+".wav")
	sfx.play()

func label(value: String, size: int, color: Color = Color("ded8c7")) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.add_theme_color_override("font_shadow_color",Color(0,0,0,.8))
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",2)
	return l

func button(value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.custom_minimum_size.y=49
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color=Color("213630") if state in ["hover","focus"] else Color("122321")
		style.border_color=Color("c4ab78") if state in ["hover","focus"] else Color("40534a")
		style.border_width_bottom=1
		style.border_width_left=3 if state in ["hover","focus"] else 0
		style.content_margin_left=18
		style.content_margin_right=18
		b.add_theme_stylebox_override(state,style)
	b.add_theme_color_override("font_color",Color("dcd6c1"))
	b.pressed.connect(callback)
	return b


func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color(.025,.055,.05,.96)
	s.border_color=Color("a99465")
	s.border_width_left=2
	s.content_margin_left=34
	s.content_margin_right=34
	s.content_margin_top=28
	s.content_margin_bottom=28
	return s


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	menu_shade=ColorRect.new()
	root.add_child(menu_shade)
	menu_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_shade.color=Color(0,.025,.025,.45)
	menu_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var heading := label("47C  /  NIGHT SHIFT",14,Color("c8b68b"))
	hud.add_child(heading)
	heading.position = Vector2(32,24)
	objective = label("",18)
	hud.add_child(objective)
	objective.position = Vector2(32,55)
	clock_label = label("NIGHT SERVICE",14,Color("c8b68b"))
	hud.add_child(clock_label)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position = Vector2(1110,28)
	prompt = label("",22)
	hud.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.position = Vector2(400,420)
	prompt.size = Vector2(480,50)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var reticle := label("·",32,Color("d5cfb5"))
	hud.add_child(reticle)
	reticle.position = Vector2(635,340)
	subtitle = label("",22)
	hud.add_child(subtitle)
	subtitle.position = Vector2(190,595)
	subtitle.size = Vector2(900,80)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var help := label("WASD  Move     E  Inspect     Shift  Walk faster     Esc  Pause",16,Color("a9b1a7"))
	hud.add_child(help)
	help.position = Vector2(32,679)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.position = Vector2(64,48)
	menu.custom_minimum_size = Vector2(450,570)
	menu.add_theme_stylebox_override("panel",panel_style())
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",10)
	menu.add_child(menu_box)
	modal_panel = PanelContainer.new()
	root.add_child(modal_panel)
	modal_panel.position = Vector2(310,155)
	modal_panel.custom_minimum_size = Vector2(660,350)
	modal_panel.add_theme_stylebox_override("panel",panel_style())
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation",18)
	modal_panel.add_child(modal_box)
	modal_panel.hide()

func clear_box(box_ui: VBoxContainer) -> void:
	for child in box_ui.get_children():
		box_ui.remove_child(child)
		child.queue_free()

func show_menu(is_pause: bool) -> void:
	paused=true
	for sound in [ambience,engine,drone,sfx,footsteps]:sound.stream_paused=true
	player.enabled=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	menu.show()
	menu_shade.show()
	hud.hide()
	clear_box(menu_box)
	menu_box.add_child(label("LOOMESVILLE TRANSIT AUTHORITY",13,Color("9dbaac")))
	menu_box.add_child(label("47C",88,Color("e3cf9c")))
	menu_box.add_child(label("THE LAST SERVICE",20))
	menu_box.add_child(label("A way home. At any cost.",16,Color("98a69a")))
	var line := HSeparator.new()
	menu_box.add_child(line)
	if is_pause:menu_box.add_child(button("RESUME JOURNEY",resume_game))
	elif FileAccess.file_exists(SAVE):menu_box.add_child(button("CONTINUE JOURNEY",continue_game))
	menu_box.add_child(button("NEW JOURNEY",func():start_game(0)))
	if is_pause:menu_box.add_child(button("RESTART CHECKPOINT",continue_game))
	menu_box.add_child(button("SETTINGS",func():show_settings(is_pause)))
	menu_box.add_child(button("QUIT",quit_cleanly))
	menu_box.add_child(label("CHAPTER 01   /   NIGHT SHIFT\nv0.2.0     •     Headphones recommended",13,Color("82998c")))


func resume_game() -> void:
	paused = false
	for sound in [ambience, engine, drone, sfx, footsteps]: sound.stream_paused = false
	menu.hide()
	menu_shade.hide()
	hud.show()
	player.enabled = not modal
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if modal else Input.MOUSE_MODE_CAPTURED

func start_game(checkpoint: int) -> void:
	story.restore(checkpoint)
	running=true
	modal=false
	modal_panel.hide()
	reveal_delay=-1
	for p in seated_passengers:p.visible=false
	watcher.visible=false
	deer.visible=false
	player.velocity=Vector3.ZERO
	player.camera.rotation=Vector3.ZERO
	player.rotation=Vector3.ZERO
	if player.get_parent()!=self: player.reparent(self,false)
	if checkpoint>=Story.Stage.CAB:
		player.reparent(bus,false)
		player.position=Vector3(.2,.8,-2.85)
	else:player.position=Vector3(5,.25,3.2)
	bus.position.z=65 if checkpoint==0 else 0
	set_door(checkpoint==Story.Stage.BOARD,true)
	ambience.play()
	engine.stop()
	drone.stop()
	resume_game()
	apply_stage(false)
	save_checkpoint()


func continue_game() -> void:
	var value: Variant = null
	if FileAccess.file_exists(SAVE): value = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	var checkpoint := 0
	if value is Dictionary and value.get("version",0) == 1:
		var validator = Story.new()
		validator.restore(value.get("stage",0))
		checkpoint = validator.stage
	start_game(checkpoint)

func save_checkpoint() -> void:
	var path := SAVE
	if "--smoke" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args(): path = "user://test-checkpoint.json"
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		say("Checkpoint could not be saved. You can still finish this session.",5)
		return
	file.store_string(JSON.stringify({"version":1,"stage":story.checkpoint()}))
	file.close()
	var err := DirAccess.rename_absolute(path+".tmp",path)
	if err != OK: say("Checkpoint storage unavailable.",4)

func say(value: String, duration: float = 5.0) -> void:
	subtitle.text = value
	caption_time = duration

func show_note() -> void:
	modal = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal_panel.show()
	clear_box(modal_box)
	modal_box.add_child(label("A NOTE ON THE BENCH",26,Color("dfc99c")))
	var body := label("Firewatch relief service\n\n47C is the last bus to Loomesville.\nThe driver will not answer you. Board anyway.\n\nIf you hear someone behind you in the forest,\nkeep walking. Do not look back.",22)
	modal_box.add_child(body)
	modal_box.add_child(button("Fold the note  [E]",close_note))

func close_note() -> void:
	modal = false
	modal_panel.hide()
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if story.interact("note"): apply_stage()

func apply_stage(save: bool = true) -> void:
	match story.stage:
		Story.Stage.STOP:
			objective.text="Read the note on the bench."
			say("My shift ended an hour ago. There should have been someone here.")
		Story.Stage.ARRIVING:
			objective.text="Look down the road. Your bus is approaching."
			engine.play()
			say("[An engine approaches from down the road]",6)
		Story.Stage.BOARD:
			bus.position.z=0
			objective.text="Walk up the steps and through the open door."
			set_door(true)
			say("[Air brakes release. Both doors swing open.]")
		Story.Stage.CAB:
			bus.position.z=0
			set_door(false)
			objective.text="Inspect the empty driver's seat."
			engine.play()
			say("[The doors close behind you]")
		Story.Stage.CLOCK:
			objective.text="Read the small clock on the dashboard."
			say("No driver. The engine is still running.")
		Story.Stage.RIDING:
			objective.text="Next stop: Mill Road. Watch the road and windows."
			next_stop_label.text="NEXT  /  MILL ROAD"
			set_door(false)
			say("02:36. The clock hasn't moved.")
			drone.play()
		Story.Stage.PASSENGER:
			bus.position.z=-130
			passenger.visible=true
			objective.text="Inspect the passenger seated at the back."
			next_stop_label.text="MILL ROAD  /  STOPPING"
			play_sound("chime")
			say("[Stop chime]  That seat was empty.",7)
			engine.play()
			drone.play()
		Story.Stage.NEXT_RIDE:
			objective.text="Next stop: Old Quarry. Keep an eye on the roadside."
			next_stop_label.text="NEXT  /  OLD QUARRY"
			say("The passenger's eyes follow you. Outside, someone is waiting.",6)
		Story.Stage.SECOND_STOP:
			bus.position.z=-270
			for p in seated_passengers:p.visible=true
			next_stop_label.text="OLD QUARRY  /  STOPPING"
			objective.text="More passengers. Check the next-stop sign above the windshield."
			play_sound("chime")
			say("[Stop chime]  The figure is closer to the road this time.",7)
		Story.Stage.FINAL_RIDE:
			next_stop_label.text="NEXT  /  LOOMESVILLE"
			objective.text="Loomesville should be next. Watch ahead."
			say("Nobody has said a word.")
		Story.Stage.DEER:
			bus.position.z=-390
			deer.visible=true
			for p in seated_passengers:p.visible=true
			engine.stop()
			play_sound("impact")
			next_stop_label.text="SERVICE INTERRUPTED"
			objective.text="Look through the windshield. Inspect what is on the road."
			say("[A heavy impact. Brakes hiss. The engine cuts out.]")
		Story.Stage.FINISHED:
			objective.text="A deer lies in the headlights. The forest is silent."
			say("Something moved between the trees. I need to get off this bus.",6)
			reveal_delay=6
	if save:save_checkpoint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and running:
		if modal: close_note()
		elif paused: resume_game()
		else: show_menu(true)
	if event.is_action_pressed("interact") and running and not paused:
		if modal: close_note()
		elif current_target == "note": show_note()
		elif current_target=="door": say("Walk up the steps. The door is open.")
		elif story.interact(current_target): apply_stage()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused and not modal:
		show_menu(true)

func _process(delta: float) -> void:
	if not running or paused or modal:return
	if story.tick(delta):apply_stage()
	if story.stage==Story.Stage.FINAL_RIDE and story.elapsed>19:deer.visible=true
	if caption_time>0:
		caption_time-=delta
		if caption_time<=0:subtitle.text=""
	if reveal_delay>=0:
		reveal_delay-=delta
		if reveal_delay<0:finish_slice()
	update_target()


func update_target() -> void:
	current_target=""
	var expected := {0:"note",2:"door",3:"driver",4:"clock",6:"passenger",8:"route",10:"deer"}
	var id: String=expected.get(story.stage,"")
	if not id.is_empty():
		var data: Array=targets[id]
		var point: Vector3=data[0].to_global(data[1])
		var diff: Vector3=point-player.camera.global_position
		var look: Vector3=-player.camera.global_transform.basis.z
		if diff.length()<(3.2 if id=="door" else 2.5) and look.dot(diff.normalized())>.78:current_target=id
	var names := {"note":"Read note","door":"Walk through the open door","driver":"Inspect empty seat","clock":"Read dashboard clock","passenger":"Inspect seated passenger","route":"Read next stop","deer":"Inspect the road"}
	prompt.text=("WASD  /  " if current_target=="door" else "[ E ]  ")+names[current_target] if not current_target.is_empty() else ""


func finish_slice() -> void:
	show_menu(true)
	clear_box(menu_box)
	menu_box.add_child(label("END OF CHAPTER ONE",16,Color("bca270")))
	menu_box.add_child(label("The road stops here.",34))
	menu_box.add_child(label("Two stops. Three passengers.\nA figure at the roadside.\n\nThe next chapter takes you into the forest.",20))
	menu_box.add_child(button("REPLAY THE RIDE",func():start_game(Story.Stage.CAB)))
	menu_box.add_child(button("START AGAIN",func():start_game(0)))
	menu_box.add_child(button("QUIT",quit_cleanly))

func quit_cleanly() -> void:
	for sound in [ambience, engine, drone, sfx, footsteps]:
		sound.stream_paused = false
		sound.stop()
		sound.stream = null
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func smoke_test() -> void:
	get_tree().create_timer(25).timeout.connect(func():get_tree().quit(2))
	start_game(0)
	assert(targets.size()==7)
	player.position=Vector3(5,.25,1.5)
	player.camera.look_at(Vector3(5.35,.95,-.45))
	update_target()
	assert(current_target=="note")
	assert(story.interact("note"))
	apply_stage(false)
	story.elapsed=6
	_physics_process(.016)
	assert(bus.position.z>20 and bus.position.z<45,"Bus must approach forwards from distance")
	assert(story.tick(6.1))
	apply_stage(false)
	player.position=Vector3(3.15,.1,-3)
	player.rotation=Vector3.ZERO
	player.camera.rotation=Vector3.ZERO
	await get_tree().create_timer(1.4).timeout
	assert(door_amount>.98 and door_collider.disabled)
	Input.action_press("left")
	for i in range(240):
		await get_tree().physics_frame
		if story.stage==Story.Stage.CAB:break
	Input.action_release("left")
	assert(story.stage==Story.Stage.CAB,"Physical boarding failed")
	assert(player.get_parent()==bus)
	assert(player.position.y>.7 and player.position.x<.65)
	await get_tree().create_timer(1.4).timeout
	assert(not door_collider.disabled and door_amount<.01)
	# Standing still, riding, and pushing against a wall must not trigger footsteps.
	var steps_before := step_index
	await get_tree().create_timer(.2).timeout
	assert(step_index==steps_before)
	Input.action_press("right")
	await get_tree().create_timer(.8).timeout
	steps_before=step_index
	await get_tree().create_timer(.6).timeout
	assert(step_index==steps_before,"Pushing against closed door must not play footsteps")
	Input.action_release("right")
	player.position=Vector3(.2,.8,-2.85)
	player.camera.look_at(bus.to_global(Vector3(-.65,1.65,-3.5)))
	update_target()
	assert(current_target=="driver")
	assert(story.interact("driver"))
	apply_stage(false)
	player.camera.look_at(bus.to_global(Vector3(.48,1.65,-3.9)))
	update_target()
	assert(current_target=="clock")
	assert(story.interact("clock"))
	apply_stage(false)
	var local_before := player.position
	await get_tree().create_timer(.6).timeout
	assert(bus.position.z<0,"Bus must drive along the road")
	assert(player.position.distance_to(local_before)<.1,"Player should be carried by bus")
	show_menu(true)
	var paused_z := bus.position.z
	await get_tree().create_timer(.2).timeout
	assert(is_equal_approx(bus.position.z,paused_z))
	resume_game()
	assert(story.tick(26))
	apply_stage(false)
	assert(passenger.visible)
	player.position=Vector3(0,.8,2)
	player.camera.look_at(bus.to_global(Vector3(.87,1.9,3.1)))
	update_target()
	assert(current_target=="passenger")
	assert(story.interact("passenger"))
	apply_stage(false)
	assert(story.tick(30.1))
	apply_stage(false)
	assert(seated_passengers[1].visible and seated_passengers[2].visible)
	assert(story.interact("route"))
	apply_stage(false)
	assert(story.tick(24.1))
	apply_stage(false)
	assert(deer.visible)
	assert(story.interact("deer"))
	apply_stage(false)
	finish_slice()
	assert(paused)
	print("PASS: approach, physical boarding, hinged door collision, moving platform, pause, seated passengers, two stops and deer")
	quit_cleanly()


func capture_preview() -> void:
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.2-menu.png")
	start_game(Story.Stage.BOARD)
	set_door(true,true)
	player.position=Vector3(4,.1,-5.3)
	player.camera.look_at(Vector3(1.3,1.6,-3))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.2-door.png")
	start_game(Story.Stage.SECOND_STOP)
	player.position=Vector3(0,.8,-2.5)
	player.camera.look_at(bus.to_global(Vector3(0,1.8,-18)))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.2-road.png")
	player.position=Vector3(0,.8,.4)
	player.camera.look_at(bus.to_global(Vector3(.4,1.7,3.1)))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.2-passengers.png")
	start_game(Story.Stage.DEER)
	player.position=Vector3(.2,.8,-3.1)
	player.camera.look_at(Vector3(.3,.4,-397))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.2-deer.png")
	print("Rendered frame rate: ",Engine.get_frames_per_second())
	quit_cleanly()

func glass(parent: Node3D, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var g := block(parent,pos,size,"46636d",true)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(.3,.45,.5,.045)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	g.material_override = m
	return g


func set_door(opened: bool, instant: bool = false) -> void:
	door_goal=1.0 if opened else 0.0
	if instant: door_amount=door_goal
	if not instant: play_sound("door")
	update_door(0)


func update_door(delta: float) -> void:
	door_amount=move_toward(door_amount,door_goal,delta*.8)
	door_hinges[0].rotation.y=-door_amount*PI*.48
	door_hinges[1].rotation.y=door_amount*PI*.48
	door_collider.disabled=door_amount>.98
	var boarding: bool = story.stage==Story.Stage.BOARD
	ramp_collider.disabled=not boarding
	steps_node.visible=boarding


func board_if_inside() -> void:
	if story.stage!=Story.Stage.BOARD or door_amount<.98: return
	var local := bus.to_local(player.global_position)
	if local.x<.65 and local.x>-.2 and local.z>-3.8 and local.z<-2.2 and local.y>.65:
		player.reparent(bus,true)
		story.interact("door")
		apply_stage()


func footfall() -> void:
	step_index=(step_index+1)%6
	var surface := "bus" if player.get_parent()==bus else "gravel"
	footsteps.stream=load("res://assets/audio/step_"+surface+"_"+str(step_index)+".wav")
	footsteps.pitch_scale=1.0+float(step_index%3-1)*.025
	footsteps.volume_db=-7 if surface=="bus" else -5
	footsteps.play()


func roadside_stop(z: float, name_text: String, figure_x: float) -> void:
	var stop := Node3D.new()
	add_child(stop)
	stop.position=Vector3(4.6,0,z)
	block(stop,Vector3(0,1.3,0),Vector3(.09,2.6,.09),"8b9385")
	block(stop,Vector3(0,2.45,0),Vector3(1.6,.6,.08),"334b43")
	var name_label := text3(stop,name_text,Vector3(0,2.45,.06),27)
	name_label.pixel_size=.004
	name_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	block(stop,Vector3(0,.6,1),Vector3(2,.15,.5),"625b43")
	light(stop,Vector3(0,2.8,0),Color("8eaea3"),1.3,6)
	var figure: Node3D=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	add_child(figure)
	figure.position=Vector3(figure_x,0,z-2)
	figure.rotation.y=-PI/2 if figure_x>0 else PI/2
	light(self,figure.position+Vector3(0,2,-1),Color("b4bdaa"),.6,3)
	stop_figures.append(figure)


func _physics_process(delta: float) -> void:
	if not running or paused or modal: return
	var old_z := bus.position.z
	match story.stage:
		Story.Stage.ARRIVING: bus.position.z=lerpf(65,0,smoothstep(0,12,story.elapsed))
		Story.Stage.RIDING: bus.position.z=lerpf(0,-130,smoothstep(0,26,story.elapsed))
		Story.Stage.NEXT_RIDE: bus.position.z=lerpf(-130,-270,smoothstep(0,30,story.elapsed))
		Story.Stage.FINAL_RIDE: bus.position.z=lerpf(-270,-390,smoothstep(0,24,story.elapsed))
	var travel := old_z-bus.position.z
	for wheel in wheels: wheel.rotate_y(travel/.52)
	update_door(delta)
	board_if_inside()
	if story.stage==Story.Stage.ARRIVING:
		engine.volume_db=lerpf(-35,-15,1.0-bus.position.z/65.0)
	elif absf(travel)>.001: engine.volume_db=-15
	else: engine.volume_db=-22

func show_settings(is_pause: bool) -> void:
	clear_box(menu_box)
	menu_box.add_child(label("JOURNEY SETTINGS",28,Color("dfc99c")))
	menu_box.add_child(label("Master volume",18))
	var volume := HSlider.new()
	volume.min_value=0
	volume.max_value=1
	volume.step=.02
	volume.value=db_to_linear(AudioServer.get_bus_volume_db(0))
	volume.value_changed.connect(func(v: float):AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,.001))))
	menu_box.add_child(volume)
	menu_box.add_child(label("Mouse sensitivity",18))
	var sensitivity := HSlider.new()
	sensitivity.min_value=.0006
	sensitivity.max_value=.004
	sensitivity.step=.0002
	sensitivity.value=player.sensitivity
	sensitivity.value_changed.connect(func(v: float):player.sensitivity=v)
	menu_box.add_child(sensitivity)
	menu_box.add_child(label("Field of view",18))
	var fov := HSlider.new()
	fov.min_value=60
	fov.max_value=95
	fov.value=player.camera.fov
	fov.value_changed.connect(func(v:float):player.camera.fov=v)
	menu_box.add_child(fov)
	menu_box.add_child(label("WASD    Move\nMOUSE    Look\nE    Inspect\nSHIFT    Walk faster\nESC    Pause\n\nBoard by walking through the open doors.",18))
	menu_box.add_child(button("BACK",func():show_menu(is_pause)))
