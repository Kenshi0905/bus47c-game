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
var door_leaf: MeshInstance3D
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
	block(self, Vector3(0,-0.2,0), Vector3(160,0.4,180), "18231c", true)
	block(self, Vector3(0,0.01,0), Vector3(5.7,0.03,180), "252b2c")
	for z in range(-80, 81, 5): block(self, Vector3(0,0.035,z), Vector3(0.1,0.015,2), "85816b")
	var rng := RandomNumberGenerator.new()
	rng.seed = 470236
	for i in range(180):
		var tree := Node3D.new()
		add_child(tree)
		var side := -1 if i % 2 == 0 else 1
		tree.position = Vector3(side*rng.randf_range(8,48),0,rng.randf_range(-80,80))
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
	player.footstep.connect(func(): if not footsteps.playing: footsteps.play())
	watcher = load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	add_child(watcher)
	watcher.position = Vector3(-8,0,-10)
	watcher.rotation.y = PI/2
	watcher.visible = false

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
	bus.position = Vector3(0,0,-48)
	block(bus,Vector3(0,.67,0),Vector3(2.7,.2,9.2),"31372f",true)
	block(bus,Vector3(0,3.05,0),Vector3(2.8,.16,9.3),"b8b5a0",true)
	for side in [-1,1]:
		block(bus,Vector3(side*1.35,1.16,0),Vector3(.1,.85,9.2),"3e5d50",true)
		block(bus,Vector3(side*1.35,1.67,0),Vector3(.1,.18,9.2),"a9aa90")
		# Transparent visual windows with invisible collision keep players inside.
		var glass := block(bus,Vector3(side*1.35,2.32,0),Vector3(.035,1.1,9),"4e737c",true)
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(.2,.33,.37,.12)
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		glass.material_override = gm
		for z in [-4.5,-3,-1.5,0,1.5,3,4.5]: block(bus,Vector3(side*1.35,2.35,z),Vector3(.1,1.35,.08),"a9aa90")
		for z in [-2.9,2.9]:
			var wheel := MeshInstance3D.new()
			var tire := CylinderMesh.new()
			tire.top_radius = .52
			tire.bottom_radius = .52
			tire.height = .22
			tire.radial_segments = 12
			wheel.mesh = tire
			wheel.material_override = mat("191e20")
			bus.add_child(wheel)
			wheel.position = Vector3(side*1.38,.52,z)
			wheel.rotation.z = PI/2
		for z in [-1.9,-.65,.6,1.85,3.1]:
			block(bus,Vector3(side*.87,1.12,z),Vector3(.68,.17,.65),"526359",true)
			block(bus,Vector3(side*.87,1.58,z+.3),Vector3(.7,.95,.13),"46584f",true)
			block(bus,Vector3(side*.87,.89,z),Vector3(.1,.4,.3),"6d7470")
	block(bus,Vector3(0,1.25,-4.55),Vector3(2.7,1,.12),"b8b5a0",true)
	block(bus,Vector3(0,2.3,-4.55),Vector3(2.6,1.1,.03),"334c58",true)
	block(bus,Vector3(0,1.8,4.55),Vector3(2.7,2.4,.1),"3e5d50",true)
	block(bus,Vector3(0,2.8,-4.62),Vector3(2,.3,.08),"172423")
	var route := text3(bus,"47C  LOOMESVILLE",Vector3(0,2.82,-4.68),30)
	route.rotation.y = PI
	for x in [-.9,.9]:
		block(bus,Vector3(x,1.22,-4.66),Vector3(.35,.2,.04),"e7d5a6",false,true)
		light(bus,Vector3(x,1.3,-5),Color("dfd6b3"),1.2,9)
	block(bus,Vector3(-.65,1.13,-3.5),Vector3(.65,.2,.6),"393f3b",true)
	block(bus,Vector3(-.65,1.55,-3.2),Vector3(.65,.85,.14),"393f3b",true)
	block(bus,Vector3(0,1.5,-4),Vector3(2.2,.25,.5),"252e2d",true)
	block(bus,Vector3(-.65,1.87,-3.85),Vector3(.4,.08,.34),"171f20")
	text3(bus,"02:36",Vector3(.5,2.55,-4.38),43,Color("d6b67b"))
	text3(bus,"NEXT STOP\nLOOMESVILLE",Vector3(-.65,2.55,-4.38),20)
	text3(bus,"47C   /   NIGHT SERVICE\nFOREST - MILL ROAD - LOOMESVILLE",Vector3(0,2.55,4.42),17).rotation.y = PI
	for z in [-2,1,3.5]:
		block(bus,Vector3(0,2.92,z),Vector3(.65,.035,.13),"e2cca2",false,true)
		light(bus,Vector3(0,2.7,z),Color("ddc69a"),.48,3.5)
	door_leaf = block(bus,Vector3(1.42,1.85,-3),Vector3(.08,2.05,1),"879080")
	text3(bus,"47C",Vector3(1.49,2.5,-3),27).rotation.y = PI/2
	targets["door"] = [bus,Vector3(1.5,1.5,-3)]
	targets["driver"] = [bus,Vector3(-.65,1.65,-3.5)]
	targets["clock"] = [bus,Vector3(.5,2.55,-4.3)]
	passenger = load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	bus.add_child(passenger)
	passenger.position = Vector3(0,.78,3.75)
	passenger.visible = false
	targets["passenger"] = [bus,Vector3(0,2.3,3.75)]

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
	b.text = value
	b.custom_minimum_size.y = 45
	b.add_theme_font_size_override("font_size",20)
	b.pressed.connect(callback)
	return b

func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(.035,.06,.065,.97)
	s.border_color = Color("8d8364")
	s.set_border_width_all(1)
	s.content_margin_left = 32
	s.content_margin_right = 32
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var heading := label("47C  /  LAST SERVICE",19,Color("c8b68b"))
	hud.add_child(heading)
	heading.position = Vector2(32,24)
	objective = label("",22)
	hud.add_child(objective)
	objective.position = Vector2(32,55)
	clock_label = label("02:36 AM",21,Color("c8b68b"))
	hud.add_child(clock_label)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position = Vector2(1110,25)
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
	menu.position = Vector2(70,50)
	menu.custom_minimum_size = Vector2(460,500)
	menu.add_theme_stylebox_override("panel",panel_style())
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",12)
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
	paused = true
	for sound in [ambience, engine, drone, sfx, footsteps]: sound.stream_paused = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
	hud.hide()
	clear_box(menu_box)
	menu_box.add_child(label("BUS 47C",54,Color("dfc99c")))
	menu_box.add_child(label("THE LAST SERVICE TO LOOMESVILLE",15,Color("a8b2a8")))
	menu_box.add_child(label("Prototype 0.1.0  /  The first passenger",17))
	if is_pause: menu_box.add_child(button("Resume journey",resume_game))
	elif FileAccess.file_exists(SAVE): menu_box.add_child(button("Continue from checkpoint",continue_game))
	menu_box.add_child(button("Start a new journey",func(): start_game(0)))
	if is_pause: menu_box.add_child(button("Restart checkpoint",continue_game))
	menu_box.add_child(label("Sound level",16))
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = .05
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	volume.value_changed.connect(func(v: float): AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,.001))))
	menu_box.add_child(volume)
	menu_box.add_child(label("Mouse sensitivity",16))
	var sensitivity := HSlider.new()
	sensitivity.min_value = .0006
	sensitivity.max_value = .004
	sensitivity.step = .0002
	sensitivity.value = player.sensitivity
	sensitivity.value_changed.connect(func(v: float): player.sensitivity = v)
	menu_box.add_child(sensitivity)
	menu_box.add_child(button("Quit",quit_cleanly))

func resume_game() -> void:
	paused = false
	for sound in [ambience, engine, drone, sfx, footsteps]: sound.stream_paused = false
	menu.hide()
	hud.show()
	player.enabled = not modal
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if modal else Input.MOUSE_MODE_CAPTURED

func start_game(checkpoint: int) -> void:
	story.restore(checkpoint)
	running = true
	modal = false
	modal_panel.hide()
	reveal_delay = -1
	passenger.visible = false
	watcher.visible = false
	player.velocity = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	if checkpoint >= Story.Stage.CAB:
		player.position = Vector3(.25,.82,-2.75)
		player.rotation.y = 0
	else:
		player.position = Vector3(5,.25,3.2)
		player.rotation.y = 0
	bus.position.z = -48 if checkpoint == 0 else 0
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
			objective.text = "Read the note on the bench."
			say("My shift ended an hour ago. There should have been someone here.")
		Story.Stage.ARRIVING:
			objective.text = "Wait for the last bus."
			engine.play()
			say("[An engine approaches through the trees]")
		Story.Stage.BOARD:
			bus.position.z = 0
			objective.text = "Board 47C through the front door."
			play_sound("door")
			create_tween().tween_property(door_leaf,"position:z",-2.2,.8)
			say("[Air brakes release. The door folds open.]")
		Story.Stage.CAB:
			bus.position.z = 0
			player.position = Vector3(.25,.82,-2.75)
			player.velocity = Vector3.ZERO
			create_tween().tween_property(door_leaf,"position:z",-3.0,.8)
			objective.text = "Inspect the empty driver's seat."
			engine.play()
			play_sound("door")
			say("[The door closes behind you]")
		Story.Stage.CLOCK:
			objective.text = "Check the clock above the dashboard."
			say("No driver. No footsteps. But we're moving.")
		Story.Stage.RIDING:
			objective.text = "Stay aboard. Watch the road."
			say("02:36. The clock hasn't changed since I got on.")
			drone.play()
		Story.Stage.PASSENGER:
			bus.position.z = 0
			passenger.visible = true
			watcher.visible = true
			objective.text = "Someone is at the back. Inspect the passenger."
			play_sound("chime")
			say("[Stop chime]  I never heard anyone board.",7)
			engine.play()
			drone.play()
		Story.Stage.FINISHED:
			objective.text = "The passenger is smiling at you."
			say("\"You were on this bus before.\"",6)
			reveal_delay = 5.5
	if save: save_checkpoint()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and running:
		if modal: close_note()
		elif paused: resume_game()
		else: show_menu(true)
	if event.is_action_pressed("interact") and running and not paused:
		if modal: close_note()
		elif current_target == "note": show_note()
		elif story.interact(current_target): apply_stage()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused and not modal:
		show_menu(true)

func _process(delta: float) -> void:
	if not running or paused or modal: return
	if story.tick(delta): apply_stage()
	if story.stage == Story.Stage.ARRIVING: bus.position.z = lerpf(-48,0,smoothstep(0,7,story.elapsed))
	if story.stage >= Story.Stage.CAB and story.stage <= Story.Stage.RIDING:
		for tree in trees:
			tree.position.z += delta*7
			if tree.position.z > 80: tree.position.z -= 160
	if story.stage == Story.Stage.RIDING and story.elapsed > 9:
		watcher.visible = true
	if caption_time > 0:
		caption_time -= delta
		if caption_time <= 0: subtitle.text = ""
	if reveal_delay >= 0:
		reveal_delay -= delta
		if reveal_delay < 0: finish_slice()
	update_target()

func update_target() -> void:
	current_target = ""
	var expected := {0:"note",2:"door",3:"driver",4:"clock",6:"passenger"}
	var id: String = expected.get(story.stage,"")
	if not id.is_empty():
		var data: Array = targets[id]
		var point: Vector3 = data[0].to_global(data[1])
		var diff: Vector3 = point-player.camera.global_position
		var look: Vector3 = -player.camera.global_transform.basis.z
		var max_distance := 3.2 if id == "door" else 2.5
		if diff.length() < max_distance and look.dot(diff.normalized()) > .78:
			current_target = id
	var names := {"note":"Read note", "door":"Board bus", "driver":"Inspect driver's seat", "clock":"Read clock", "passenger":"Inspect passenger"}
	prompt.text = "[ E ]  " + names[current_target] if not current_target.is_empty() else ""

func finish_slice() -> void:
	show_menu(true)
	clear_box(menu_box)
	menu_box.add_child(label("END OF THE FIRST RIDE",30,Color("dfc99c")))
	menu_box.add_child(label("Prototype 0.1.0 complete",21))
	var summary := label("The forest stop, driverless bus and first\npassenger encounter are now playable.\n\nNext: changing faces, the deer collision\nand the path into the woods.",19)
	menu_box.add_child(summary)
	menu_box.add_child(button("Replay from the bus",func(): start_game(Story.Stage.CAB)))
	menu_box.add_child(button("Start again",func(): start_game(0)))
	menu_box.add_child(button("Quit",quit_cleanly))

func quit_cleanly() -> void:
	for sound in [ambience, engine, drone, sfx, footsteps]:
		sound.stream_paused = false
		sound.stop()
		sound.stream = null
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func smoke_test() -> void:
	start_game(0)
	await get_tree().physics_frame
	assert(targets.size() == 5)
	assert(not passenger.visible)
	player.position = Vector3(5,.25,1.5)
	player.camera.look_at(Vector3(5.35,.95,-.45))
	update_target()
	assert(current_target == "note", "Note must be reachable from shelter entrance")
	assert(story.interact("note"))
	apply_stage(false)
	assert(story.tick(7.1))
	apply_stage(false)
	player.position = Vector3(2.5,.1,-3)
	player.camera.look_at(Vector3(1.5,1.5,-3))
	update_target()
	assert(current_target == "door", "Boarding prompt must be reachable outside bus")
	assert(story.interact("door"))
	apply_stage(false)
	assert(player.position.y > .7)
	player.camera.look_at(Vector3(-.65,1.65,-3.5))
	update_target()
	assert(current_target == "driver")
	assert(story.interact("driver"))
	apply_stage(false)
	player.camera.look_at(Vector3(.5,2.55,-4.3))
	update_target()
	assert(current_target == "clock")
	assert(story.interact("clock"))
	apply_stage(false)
	assert(story.tick(16.1))
	apply_stage(false)
	assert(passenger.visible)
	player.position = Vector3(0,.82,2)
	player.camera.look_at(Vector3(0,2.3,3.75))
	update_target()
	assert(current_target == "passenger")
	assert(story.interact("passenger"))
	apply_stage(false)
	finish_slice()
	assert(paused)
	print("PASS: complete scene flow, asset loading, boarding, passenger reveal and end menu")
	await get_tree().process_frame
	await get_tree().process_frame
	quit_cleanly()

func capture_preview() -> void:
	start_game(Story.Stage.PASSENGER)
	player.position = Vector3(-.1,.82,.1)
	player.rotation.y = PI
	player.camera.rotation.x = 0
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/prototype-preview.png")
	quit_cleanly()
