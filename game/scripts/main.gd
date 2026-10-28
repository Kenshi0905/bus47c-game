extends Node3D
const Story = preload("res://scripts/story.gd")
const Player = preload("res://scripts/player.gd")
const Forest = preload("res://scripts/forest.gd")
const Passengers = preload("res://scripts/bus_passengers.gd")
const MENU_FONT = preload("res://assets/ui/fonts/BebasNeue-Regular.ttf")
const SAVE := "user://checkpoint.json"
var story = Story.new()
var player: CharacterBody3D
var bus: Node3D
var forest: Node3D
var menu_chrome: Control
var menu_camera: Camera3D
var menu_is_pause := false
var menu_page := "title"
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
var passengers: Node3D
var seats: Array[Vector3] = []
var seated_index := -1
var steering: Node3D
var departure_id := ""
var watcher_phase := 0
var objective_time := 0.0
var objective_panel: PanelContainer
var subtitle_frame: PanelContainer
var controls_hint: Label
var modal_kind := ""
var sound_captions := false
var thought_subtitles := true
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
var menu_ambience: AudioStreamPlayer
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
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(8, 1.95, -11.8)
	menu_camera.fov = 57
	menu_camera.look_at(Vector3(3.5, 2.1, -1))
	show_menu(false)
	if "--smoke" in OS.get_cmdline_user_args(): call_deferred("smoke_test")
	if "--capture" in OS.get_cmdline_user_args(): call_deferred("capture_preview")

func _setup_inputs() -> void:
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "interact": KEY_E, "pause_game": KEY_ESCAPE, "stand": KEY_SPACE, "notes": KEY_TAB}
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
	forest = Forest.new()
	add_child(forest)
	_build_shelter()
	_build_bus()
	player = Player.new()
	add_child(player)
	player.position = Vector3(5.0,.1,4.2)
	player.rotation.y = 0.0
	player.footstep.connect(footfall)
	watcher = load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	add_child(watcher)
	watcher.position = Vector3(-22,0,-145)
	watcher.rotation.y = PI/2
	watcher.visible = true
	add_tie_glow(watcher)
	light(watcher, Vector3(0,2,-1),Color("7f9b9d"),.4,3)
	roadside_stop(-133,"MILL ROAD")
	roadside_stop(-273,"OLD QUARRY")
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
			seats.append(Vector3(side*.87,.78,z))
			block(bus,Vector3(side*.87,1.12,z),Vector3(.68,.17,.65),"526359",true)
			block(bus,Vector3(side*.87,1.51,z+.3),Vector3(.7,.8,.13),"46584f",true)
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
	build_steering_wheel()
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
	passengers = Passengers.new()
	bus.add_child(passengers)
	passengers.configure(seats)
	passenger = passengers.first_actor()
	for actor in passengers.actors: seated_passengers.append(actor.seated)
	targets["passenger"]=[passenger,Vector3(0,1.1,0)]


func _build_audio() -> void:
	ambience = audio("forest",-15,true)
	engine = audio("engine",-19,true)
	drone = audio("drone",-24,true)
	sfx = audio("door",-9,false)
	footsteps = audio("step",-14,false)
	menu_ambience = audio("drone",-31,true)

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
	b.custom_minimum_size.y = 38
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", MENU_FONT)
	b.add_theme_font_size_override("font_size", 26)
	var normal := StyleBoxEmpty.new()
	normal.content_margin_left = 17
	normal.content_margin_right = 17
	b.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "focus"]:
		var brush := StyleBoxTexture.new()
		brush.texture = preload("res://assets/ui/selection-brush.svg")
		brush.content_margin_left = 17
		brush.content_margin_right = 17
		b.add_theme_stylebox_override(state, brush)
	b.add_theme_color_override("font_color", Color("bbb9af"))
	for state in ["hover", "pressed", "focus"]:
		b.add_theme_color_override("font_" + state + "_color", Color("151a18"))
	b.mouse_entered.connect(func(): b.grab_focus())
	b.pressed.connect(callback)
	return b

func focus_first() -> void:
	for child in menu_box.get_children():
		if child is Button:
			child.grab_focus()
			break

func menu_heading(value: String) -> void:
	var heading := label(value, 42, Color("e3decd"))
	heading.add_theme_font_override("font", MENU_FONT)
	menu_box.add_child(heading)

func menu_spacer(height: float) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	menu_box.add_child(gap)


func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color(.025,.035,.033,.97)
	s.border_color=Color("8d3530")
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
	menu_shade.color=Color.WHITE
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader = preload("res://assets/ui/menu_atmosphere.gdshader")
	menu_shade.material = atmosphere
	menu_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	objective_panel = PanelContainer.new()
	hud.add_child(objective_panel)
	objective_panel.position = Vector2(32,586)
	objective_panel.custom_minimum_size = Vector2(360,50)
	var thought_style := StyleBoxFlat.new()
	thought_style.bg_color = Color(.025,.035,.03,.72)
	thought_style.border_color = Color("8c8d77")
	thought_style.border_width_left = 1
	thought_style.content_margin_left = 14
	thought_style.content_margin_right = 14
	thought_style.content_margin_top = 10
	thought_style.content_margin_bottom = 10
	objective_panel.add_theme_stylebox_override("panel",thought_style)
	objective = label("",17,Color("c2c4b9"))
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_panel.add_child(objective)
	prompt = label("",18,Color("d4d5ca"))
	hud.add_child(prompt)
	prompt.position = Vector2(360,522)
	prompt.size = Vector2(560,35)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var reticle := label("·",26,Color("d5cfb5"))
	hud.add_child(reticle)
	reticle.position = Vector2(636,342)
	subtitle_frame = PanelContainer.new()
	hud.add_child(subtitle_frame)
	subtitle_frame.position = Vector2(300,601)
	subtitle_frame.custom_minimum_size = Vector2(680,54)
	var caption_style := thought_style.duplicate()
	caption_style.border_width_left = 0
	caption_style.bg_color = Color(0,0,0,.58)
	subtitle_frame.add_theme_stylebox_override("panel",caption_style)
	subtitle = label("",21,Color("e7e7dc"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_frame.add_child(subtitle)
	subtitle_frame.hide()
	controls_hint = label("TAB   Shift notes",14,Color("999e93"))
	hud.add_child(controls_hint)
	controls_hint.position = Vector2(32,676)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.position = Vector2(65,62)
	menu.custom_minimum_size = Vector2(360, 0)
	menu.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",4)
	menu.add_child(menu_box)
	menu_chrome = Control.new()
	root.add_child(menu_chrome)
	menu_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var footer := label("HEADPHONES RECOMMENDED", 17, Color("9d5149"))
	footer.add_theme_font_override("font", MENU_FONT)
	menu_chrome.add_child(footer)
	footer.position = Vector2(66, 666)
	var version := label("CHAPTER 01   /   v0.4.0", 16, Color("9d9f94"))
	version.add_theme_font_override("font", MENU_FONT)
	menu_chrome.add_child(version)
	version.position = Vector2(1070, 666)
	modal_panel = PanelContainer.new()
	root.add_child(modal_panel)
	modal_panel.position = Vector2(350,80)
	modal_panel.custom_minimum_size = Vector2(580,520)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("c6bfa7")
	paper.border_color = Color("8a8068")
	paper.set_border_width_all(2)
	paper.content_margin_left = 35
	paper.content_margin_right = 35
	paper.content_margin_top = 30
	paper.content_margin_bottom = 26
	paper.shadow_color = Color(0,0,0,.7)
	paper.shadow_size = 18
	modal_panel.add_theme_stylebox_override("panel",paper)
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
	menu_is_pause = is_pause
	menu_page = "title"
	for sound in [ambience, engine, drone, sfx, footsteps]: sound.stream_paused = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not is_pause:
		menu_camera.make_current()
		if not menu_ambience.playing: menu_ambience.play()
	menu.show()
	menu_chrome.show()
	menu_shade.show()
	hud.hide()
	clear_box(menu_box)
	var logo := TextureRect.new()
	logo.texture = preload("res://assets/ui/bus47c-logo.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(360, 140)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_box.add_child(logo)
	menu_spacer(24)
	if is_pause: menu_box.add_child(button("RESUME JOURNEY", resume_game))
	elif FileAccess.file_exists(SAVE): menu_box.add_child(button("CONTINUE JOURNEY", continue_game))
	menu_box.add_child(button("NEW JOURNEY" if is_pause or FileAccess.file_exists(SAVE) else "START JOURNEY", func(): start_game(0)))
	if is_pause: menu_box.add_child(button("RESTART CHECKPOINT", continue_game))
	menu_box.add_child(button("HOW TO PLAY", func(): show_information("controls", is_pause)))
	menu_box.add_child(button("SETTINGS", func(): show_settings(is_pause)))
	if not is_pause: menu_box.add_child(button("CREDITS", func(): show_information("credits", is_pause)))
	menu_box.add_child(button("EXIT", quit_cleanly))
	focus_first()

func show_information(page: String, is_pause: bool) -> void:
	menu_page = page
	clear_box(menu_box)
	menu_heading("HOW TO PLAY" if page == "controls" else "CREDITS")
	menu_spacer(12)
	var copy := "WASD   Move\nMOUSE   Look\nE   Inspect / sit\nSPACE   Stand up\nTAB   Shift notes\nSHIFT   Walk faster\nESC   Pause / back\n\nRead the note at the shelter.\nWait for the bus to stop.\nWalk through its open doors.\n\nInspect the empty driver's seat,\nthen the dashboard clock.\nWatch the road. Watch the windows."
	if page == "credits":
		copy = "BUS 47C\nStory & direction — Ashmit Avash\n\nA game built in Godot\nMenu design — Canva + original vectors\nFont — Bebas Neue / SIL OFL\n\nFootstep references\nEffecism / Kerma T.C.\nEdited for this private prototype.\n\nChapter one is a work in progress."
	var body := label(copy, 18, Color("bebfb5"))
	menu_box.add_child(body)
	menu_spacer(18)
	menu_box.add_child(button("BACK", func(): show_menu(is_pause)))
	focus_first()


func resume_game() -> void:
	paused = false
	menu_ambience.stop()
	for sound in [ambience, engine, drone, sfx, footsteps]: sound.stream_paused = false
	menu.hide()
	menu_chrome.hide()
	menu_shade.hide()
	player.camera.make_current()
	hud.show()
	player.enabled = not modal
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if modal else Input.MOUSE_MODE_CAPTURED

func start_game(checkpoint: int) -> void:
	story.restore(checkpoint)
	running=true
	modal=false
	modal_panel.hide()
	reveal_delay=-1
	departure_id=""
	seated_index=-1
	player.set_seated(false,Vector3.ZERO)
	var restored := 3 if checkpoint>=Story.Stage.SECOND_STOP else (1 if checkpoint>=Story.Stage.PASSENGER else 0)
	passengers.reset(restored)
	watcher_phase = 3 if checkpoint>=Story.Stage.DEER else (1 if checkpoint>=Story.Stage.SECOND_STOP else 0)
	watcher.position = Vector3(9,0,-399) if watcher_phase==3 else (Vector3(17,0,-284) if watcher_phase==1 else Vector3(-22,0,-145))
	watcher.visible=true
	subtitle.text=""
	subtitle_frame.hide()
	caption_time=0
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

func say(value: String, duration: float = 4.0, essential: bool = false) -> void:
	if not thought_subtitles and not essential: return
	subtitle.text = value
	caption_time = duration
	subtitle_frame.modulate.a = 0
	subtitle_frame.show()

func describe_sound(value: String) -> void:
	if sound_captions: say("[" + value + "]",3,true)

func set_objective(value: String) -> void:
	objective.text = value
	objective_time = 4.5

func paper_label(value: String, size: int) -> Label:
	var text := label(value,size,Color("2f342f"))
	text.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return text

func show_document(kind: String) -> void:
	modal = true
	hud.hide()
	modal_kind = kind
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal_panel.show()
	clear_box(modal_box)
	var title := paper_label("47C  /  RELIEF SERVICE" if kind=="note" else "SHIFT NOTES",30)
	title.add_theme_font_override("font",MENU_FONT)
	modal_box.add_child(title)
	modal_box.add_child(paper_label("LOOMESVILLE FORESTRY DIVISION",12))
	modal_box.add_child(HSeparator.new())
	var copy := "47C is the last bus to Loomesville.\n\nThe driver will not answer you.\nBoard anyway.\n\nIf you hear someone behind you in the forest, keep walking.\n\nDo not look back."
	if kind=="journal": copy = "End of shift. Get home.\n\n" + objective.text + "\n\nRoute\nMill Road — Old Quarry — Loomesville\n\nEmpty seats are available.\nE to sit. Space to stand."
	modal_box.add_child(paper_label(copy,21))
	var close := button("FOLD NOTE  [E]" if kind=="note" else "CLOSE NOTES  [TAB]",close_document)
	close.add_theme_color_override("font_color",Color("30382f"))
	modal_box.add_child(close)
	close.grab_focus()

func show_note() -> void:
	show_document("note")

func close_document() -> void:
	var was_note := modal_kind=="note"
	modal = false
	modal_kind = ""
	modal_panel.hide()
	player.enabled = not paused
	hud.visible = not paused
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if was_note and story.interact("note"): apply_stage()

func apply_stage(save: bool = true) -> void:
	match story.stage:
		Story.Stage.STOP:
			set_objective("There's a note on the shelter bench.")
		Story.Stage.ARRIVING:
			set_objective("Wait for the last bus.")
			engine.play()
			describe_sound("An engine approaches")
		Story.Stage.BOARD:
			bus.position.z=0
			set_objective("Board through the open doors.")
			set_door(true)
			describe_sound("Air brakes release")
		Story.Stage.CAB:
			bus.position.z=0
			set_door(false)
			set_objective("Check the driver's seat.")
			engine.play()
		Story.Stage.CLOCK:
			set_objective("Look at the dashboard clock.")
			say("No driver.",3)
		Story.Stage.RIDING:
			set_objective("Find a seat. Mill Road is next.")
			next_stop_label.text="NEXT  /  MILL ROAD"
			set_door(false)
			say("Still 02:36.",3)
			drone.play()
		Story.Stage.PASSENGER:
			bus.position.z=-130
			passengers.request_count(1)
			set_objective("Look around the bus.")
			next_stop_label.text="MILL ROAD"
			play_sound("chime")
			set_door(true)
			engine.play()
			drone.play()
		Story.Stage.NEXT_RIDE:
			set_objective("Old Quarry is next.")
			next_stop_label.text="NEXT  /  OLD QUARRY"
		Story.Stage.SECOND_STOP:
			bus.position.z=-270
			passengers.request_count(3)
			next_stop_label.text="OLD QUARRY"
			set_objective("Check the route sign above the windshield.")
			play_sound("chime")
			set_door(true)
		Story.Stage.FINAL_RIDE:
			next_stop_label.text="NEXT  /  LOOMESVILLE"
			set_objective("Loomesville should be next.")
		Story.Stage.DEER:
			bus.position.z=-390
			deer.visible=true
			engine.stop()
			play_sound("impact")
			next_stop_label.text="SERVICE INTERRUPTED"
			set_objective("Look through the windshield.")
			describe_sound("Impact. Brakes hiss")
		Story.Stage.FINISHED:
			set_objective("Something is in the trees.")
			say("I need to get off this bus.",4)
			reveal_delay=6
	if save:save_checkpoint()


func _input(event: InputEvent) -> void:
	if running and not paused and event.is_action_pressed("notes"):
		if modal:close_document()
		else:show_document("journal")
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and paused and menu_page != "title":
		show_menu(menu_is_pause)
		return
	if event.is_action_pressed("pause_game") and running:
		if modal: close_document()
		elif paused: resume_game()
		else: show_menu(true)
	if not running or paused: return
	if event.is_action_pressed("stand") and not modal: stand_up()
	if event.is_action_pressed("interact"):
		if modal: close_document()
		elif current_target == "note": show_note()
		elif current_target.begins_with("seat:"): sit_down(int(current_target.get_slice(":",1)))
		elif current_target != "door": request_interaction(current_target)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running and not paused and not modal:
		show_menu(true)

func _process(delta: float) -> void:
	if not running or paused or modal:return
	var moving_stage: bool = story.stage in [Story.Stage.RIDING,Story.Stage.NEXT_RIDE,Story.Stage.FINAL_RIDE]
	if not moving_stage or can_drive():
		if story.tick(delta):apply_stage()
	if story.stage==Story.Stage.FINAL_RIDE and story.elapsed>19:deer.visible=true
	objective_time=maxf(0,objective_time-delta)
	objective_panel.visible=objective_time>0 and caption_time<=0
	objective_panel.modulate.a=minf(1,objective_time)
	if caption_time>0:
		caption_time=maxf(0,caption_time-delta)
		subtitle_frame.modulate.a=move_toward(subtitle_frame.modulate.a,minf(1,caption_time*3),delta*5)
		if caption_time<=0:subtitle_frame.hide()
	controls_hint.text="SPACE   Stand up     TAB   Shift notes" if seated_index>=0 else "TAB   Shift notes"
	if reveal_delay>=0:
		reveal_delay-=delta
		if reveal_delay<0:finish_slice()
	update_target()

func update_target() -> void:
	current_target=""
	var expected := {0:"note",2:"door",3:"driver",4:"clock",6:"passenger",8:"route",10:"deer"}
	var id: String=expected.get(story.stage,"")
	if id=="passenger" and not passengers.first_visible():id=""
	if not id.is_empty():
		var data: Array=targets[id]
		var point: Vector3=data[0].to_global(data[1])
		var diff: Vector3=point-player.camera.global_position
		var look: Vector3=-player.camera.global_transform.basis.z
		if diff.length()<(3.2 if id=="door" else 2.5) and look.dot(diff.normalized())>.88:current_target=id
	if current_target.is_empty() and seated_index<0 and player.get_parent()==bus:
		var best := .88
		for i in range(seats.size()):
			if not passengers.can_sit(i):continue
			var diff: Vector3=bus.to_global(seats[i]+Vector3(0,.45,0))-player.camera.global_position
			var aim: float=(-player.camera.global_transform.basis.z).dot(diff.normalized())
			if diff.length()<1.9 and aim>best:
				best=aim
				current_target="seat:"+str(i)
	var names := {"note":"Read note","door":"Board the bus","driver":"Check driver's seat","clock":"Read clock","passenger":"Look at passenger","route":"Read route sign","deer":"Look outside"}
	if current_target.begins_with("seat:"):prompt.text="E   Sit down"
	elif not current_target.is_empty():prompt.text=("WALK  /  " if current_target=="door" else "E   ")+names[current_target]
	else:prompt.text=""


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
	for sound in [ambience, engine, drone, sfx, footsteps, menu_ambience]:
		sound.stream_paused = false
		sound.stop()
		sound.stream = null
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func smoke_test() -> void:
	get_tree().create_timer(45).timeout.connect(func():get_tree().quit(2))
	# Exercise real menu actions and Escape without starting or changing a save.
	assert(menu_camera.current and not player.enabled)
	assert(get_viewport().gui_get_focus_owner() is Button)
	for page in ["HOW TO PLAY", "CREDITS", "SETTINGS"]:
		for control in menu_box.get_children():
			if control is Button and control.text == page:
				control.pressed.emit()
				break
		assert(menu_page != "title" and paused)
		await get_tree().process_frame
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		Input.parse_input_event(escape)
		await get_tree().process_frame
		escape.pressed = false
		Input.parse_input_event(escape)
		assert(menu_page == "title" and not running)
		assert(get_viewport().gui_get_focus_owner() is Button)
	assert(forest.tree_count > 3000 and forest.batches <= 104)
	assert(not forest.in_clearing(-20, -80))
	assert(forest.in_clearing(6, 0) and forest.in_clearing(7, -133))
	start_game(0)
	assert(player.camera.current and not menu_chrome.visible and not menu_ambience.playing)
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
	show_settings(true)
	assert(menu_page == "settings" and paused and not player.enabled)
	show_menu(true)
	resume_game()
	# Every empty passenger seat must be reachable by the interaction ray.
	for index in range(seats.size()):
		player.position=Vector3(0,.8,seats[index].z-.15)
		player.camera.look_at(bus.to_global(seats[index]+Vector3(0,.45,0)))
		update_target()
		assert(current_target=="seat:"+str(index),"Empty seat must be selectable")
		sit_down(index)
		await get_tree().physics_frame
		assert(player.seated and passengers.owners[index]==-2)
		var seated_position := player.position
		steps_before=step_index
		Input.action_press("forward")
		await get_tree().physics_frame
		assert(player.position.is_equal_approx(seated_position) and step_index==steps_before)
		Input.action_release("forward")
		stand_up()
		await get_tree().physics_frame
		assert(not player.seated and passengers.owners[index]==-1)
	# Notes open/close through the actual Tab event; reading them pauses progress.
	var tab := InputEventKey.new()
	tab.physical_keycode=KEY_TAB
	tab.keycode=KEY_TAB
	tab.pressed=true
	Input.parse_input_event(tab.duplicate())
	Input.flush_buffered_events()
	await get_tree().process_frame
	assert(modal and modal_kind=="journal", "Tab state: modal=%s paused=%s running=%s" % [modal,paused,running])
	var elapsed_before: float=story.elapsed
	_process(1)
	assert(story.elapsed==elapsed_before)
	tab.pressed=false
	Input.parse_input_event(tab.duplicate())
	tab.pressed=true
	Input.parse_input_event(tab.duplicate())
	Input.flush_buffered_events()
	await get_tree().process_frame
	assert(not modal)
	tab.pressed=false
	Input.parse_input_event(tab.duplicate())
	assert(story.tick(26))
	apply_stage(false)
	assert(not passenger.visible,"Arrivals must not pop into a watched seat")
	set_door(true,true)
	assert(door_collider.disabled and not ramp_collider.disabled)
	passengers.update(.01,player.camera,player.position,false)
	var reserved: int=passengers.actors[0].seat
	sit_down(reserved)
	assert(seated_index==reserved and passengers.actors[0].seat!=reserved,"Passenger must give an empty reserved seat to the player")
	player.camera.look_at(bus.to_global(Vector3(-20,1.6,player.position.z)))
	passengers.update(.1,player.camera,player.position,true)
	assert(passenger.visible and not passengers.actor_watched(0,player.camera),"Spawn must be outside camera view")
	var arrival_position: Vector3=passenger.position
	passengers.update(.1,player.camera,player.position,true)
	assert(passenger.position.distance_to(arrival_position)>0,"Passenger must actually walk")
	for frame in range(350):
		passengers.update(.05,player.camera,player.position,true)
		if passengers.actors[0].state=="waiting":break
	assert(passengers.actors[0].state=="waiting")
	player.camera.look_at(passenger.global_position+Vector3(0,1.1,0))
	passengers.update(1,player.camera,player.position,true)
	assert(passengers.actors[0].state=="waiting","No pose swap while watched")
	player.camera.look_at(bus.to_global(Vector3(-20,1.6,player.position.z)))
	passengers.update(.1,player.camera,player.position,true)
	assert(passengers.actors[0].state=="seated")
	assert(not passengers.can_sit(passengers.actors[0].seat),"Occupied seats cannot overlap the player")
	stand_up()
	player.camera.look_at(passenger.global_position+Vector3(0,1.1,0))
	update_target()
	assert(current_target=="passenger")
	request_interaction("passenger")
	story.elapsed=5
	# A player in the doorway or outside keeps the stop open and stationary.
	player.position=Vector3(1.2,.8,-3)
	set_door(false)
	update_door(.1)
	assert(door_goal==1 and door_amount>.98,"Closing doors must reopen around a player")
	process_departure()
	assert(door_goal==1 and story.stage==Story.Stage.PASSENGER)
	player.position=Vector3(2.4,.4,-3)
	board_if_inside()
	assert(player.get_parent()==self)
	process_departure()
	assert(door_goal==1 and story.stage==Story.Stage.PASSENGER)
	player.global_position=bus.to_global(Vector3(.3,.8,-3))
	board_if_inside()
	assert(player.get_parent()==bus)
	await get_tree().create_timer(1.6).timeout
	assert(story.stage==Story.Stage.NEXT_RIDE and door_amount<.01 and not door_collider.disabled)
	story.elapsed=8
	_physics_process(.2)
	assert(absf(steering.rotation.y)>.001,"Steering wheel must turn while driving")
	assert(story.tick(30.1))
	apply_stage(false)
	assert(door_goal==1)
	set_door(true,true)
	sit_down(0)
	player.camera.look_at(bus.to_global(Vector3(0,1.7,-20)))
	for frame in range(1000):passengers.update(.05,player.camera,player.position,true)
	assert(passengers.all_aboard() and passengers.actors[2].state=="seated")
	# Looking at the watcher must hold it in its distant position.
	watcher_phase=1
	watcher.position=Vector3(17,0,-284)
	story.elapsed=8
	player.camera.look_at(watcher.global_position+Vector3(0,1.1,0))
	update_watcher()
	assert(watcher_phase==1)
	player.camera.look_at(bus.to_global(Vector3(-30,1.8,0)))
	update_watcher()
	assert(watcher_phase==2 and watcher.position.x==12)
	caption_time=0
	set_objective("Wait here.")
	_process(5)
	assert(not objective_panel.visible,"Objective hints should fade away")
	request_interaction("route")
	await get_tree().create_timer(1.6).timeout
	assert(story.stage==Story.Stage.FINAL_RIDE and door_amount<.01)

	assert(story.tick(24.1))
	apply_stage(false)
	assert(deer.visible)
	assert(story.interact("deer"))
	apply_stage(false)
	finish_slice()
	assert(paused)
	print("PASS: menus, notes, ten seats, stand/footsteps, unseen arrivals, walking, unseen seating, watcher gaze, stop doors, obstruction, disembark/reboard, steering, ride and deer")
	quit_cleanly()


func capture_preview() -> void:
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-menu.png")
	# Real game scenery for the editable menu reference; no illustrated backdrop.
	menu.hide()
	menu_chrome.hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../work/menu-scene.png")
	menu.show()
	menu_chrome.show()
	show_settings(false)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-settings.png")
	show_menu(false)
	start_game(Story.Stage.BOARD)
	set_door(true,true)
	player.position=Vector3(4,.1,-5.3)
	player.camera.look_at(Vector3(1.3,1.6,-3))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-door.png")
	start_game(Story.Stage.SECOND_STOP)
	player.position=Vector3(0,.8,-2.5)
	player.camera.look_at(bus.to_global(Vector3(0,1.8,-18)))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-road.png")
	player.position=Vector3(0,.8,.4)
	player.camera.look_at(bus.to_global(Vector3(.4,1.7,3.1)))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-passengers.png")
	start_game(Story.Stage.DEER)
	player.position=Vector3(.2,.8,-3.1)
	player.camera.look_at(Vector3(.3,.4,-397))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-deer.png")
	start_game(Story.Stage.SECOND_STOP)
	player.position=Vector3(.3,.8,-4)
	player.camera.look_at(watcher.global_position+Vector3(0,1.45,0))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-watcher.png")
	objective_time=0
	caption_time=0
	start_game(Story.Stage.CAB)
	player.position=Vector3(.1,.8,-2.95)
	player.camera.look_at(bus.to_global(Vector3(-.65,1.76,-3.78)))
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-steering.png")
	show_document("note")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-note.png")
	close_document()
	show_document("journal")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-notes.png")
	close_document()
	start_game(Story.Stage.PASSENGER)
	passengers.reset()
	passengers.request_count(1)
	set_door(true,true)
	sit_down(3)
	player.camera.look_at(bus.to_global(Vector3(-20,1.8,2)))
	for frame in range(65):passengers.update(.1,player.camera,player.position,true)
	stand_up()
	player.position=Vector3(0,.8,2.3)
	player.camera.position.y=1.57
	player.camera.look_at(passenger.global_position+Vector3(0,1.1,0))
	await get_tree().create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-walking.png")
	sit_down(3)
	player.camera.look_at(watcher.global_position+Vector3(0,1.4,0))
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/v0.4-seated-view.png")
	print("Forest: ",forest.tree_count," trees, ",forest.understory_count," understory instances, ",forest.batches," batches")
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
	var desired := 1.0 if opened else 0.0
	if is_equal_approx(door_goal,desired) and not instant:return
	door_goal=desired
	if instant:
		door_amount=door_goal
		update_door(0)
	else:
		play_sound("door")
		describe_sound("Doors open" if opened else "Doors close")

func at_stop() -> bool:
	return story.stage in [Story.Stage.BOARD,Story.Stage.PASSENGER,Story.Stage.SECOND_STOP]

func doorway_occupied() -> bool:
	var at := bus.to_local(player.global_position)
	return at.x>.65 and at.x<2.2 and at.z>-4 and at.z<-2 and at.y<1.1

func player_aboard() -> bool:
	return player.get_parent()==bus and player.position.y>.65 and absf(player.position.x)<1.3

func can_drive() -> bool:
	return door_amount<.01 and door_goal==0 and player_aboard()

func update_door(delta: float) -> void:
	if door_goal==0 and door_amount>.01 and doorway_occupied():set_door(true)
	door_amount=move_toward(door_amount,door_goal,delta*.8)
	door_hinges[0].rotation.y=-door_amount*PI*.48
	door_hinges[1].rotation.y=door_amount*PI*.48
	door_collider.disabled=door_amount>.98
	var open_stop := door_amount>.05
	ramp_collider.disabled=not open_stop
	steps_node.visible=open_stop

func board_if_inside() -> void:
	if story.stage==Story.Stage.ARRIVING or door_amount<.98:return
	var local := bus.to_local(player.global_position)
	if player.get_parent()==bus and local.x>1.65:
		player.reparent(self,true)
	elif player.get_parent()!=bus and local.x<.65 and local.x>-.2 and local.z>-3.8 and local.z<-2.2 and local.y>.65:
		player.reparent(bus,true)
		if story.stage==Story.Stage.BOARD and story.interact("door"):apply_stage()


func footfall() -> void:
	step_index=(step_index+1)%6
	var surface := "bus" if player.get_parent()==bus else "gravel"
	footsteps.stream=load("res://assets/audio/step_"+surface+"_"+str(step_index)+".wav")
	footsteps.pitch_scale=1.0+float(step_index%3-1)*.025
	footsteps.volume_db=-7 if surface=="bus" else -5
	footsteps.play()


func roadside_stop(z: float, name_text: String) -> void:
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


func _physics_process(delta: float) -> void:
	if not running or paused or modal: return
	passengers.update(delta,player.camera,bus.to_local(player.global_position),door_amount>.98)
	if not at_stop() and door_goal==1 and player_aboard() and not doorway_occupied():set_door(false)
	update_door(delta)
	board_if_inside()
	process_departure()
	update_watcher()
	var old_z := bus.position.z
	if story.stage==Story.Stage.ARRIVING:bus.position.z=lerpf(65,0,smoothstep(0,12,story.elapsed))
	elif can_drive():
		match story.stage:
			Story.Stage.RIDING: bus.position.z=lerpf(0,-130,smoothstep(0,26,story.elapsed))
			Story.Stage.NEXT_RIDE: bus.position.z=lerpf(-130,-270,smoothstep(0,30,story.elapsed))
			Story.Stage.FINAL_RIDE: bus.position.z=lerpf(-270,-390,smoothstep(0,24,story.elapsed))
	var travel := old_z-bus.position.z
	for wheel in wheels: wheel.rotate_object_local(Vector3.UP,travel/.52)
	var turn := sin(-bus.position.z*.045)*.3+sin(-bus.position.z*.12)*.08 if absf(travel)>.001 else 0.0
	steering.rotation.y=lerp_angle(steering.rotation.y,turn,minf(1,delta*3))
	if story.stage==Story.Stage.ARRIVING:engine.volume_db=lerpf(-35,-15,1.0-bus.position.z/65.0)
	elif absf(travel)>.001: engine.volume_db=-15
	else: engine.volume_db=-22

func show_settings(is_pause: bool) -> void:
	menu_page = "settings"
	clear_box(menu_box)
	menu_heading("SETTINGS")
	menu_spacer(12)
	menu_box.add_child(label("Master volume",18))
	var volume := HSlider.new()
	volume.min_value=0
	volume.max_value=1
	volume.step=.02
	volume.value=db_to_linear(AudioServer.get_bus_volume_db(0))
	volume.value_changed.connect(func(v: float):AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,.001))))
	volume.custom_minimum_size.y = 28
	menu_box.add_child(volume)
	menu_box.add_child(label("Mouse sensitivity",18))
	var sensitivity := HSlider.new()
	sensitivity.min_value=.0006
	sensitivity.max_value=.004
	sensitivity.step=.0002
	sensitivity.value=player.sensitivity
	sensitivity.value_changed.connect(func(v: float):player.sensitivity=v)
	sensitivity.custom_minimum_size.y = 28
	menu_box.add_child(sensitivity)
	menu_box.add_child(label("Field of view",18))
	var fov := HSlider.new()
	fov.min_value=60
	fov.max_value=95
	fov.value=player.camera.fov
	fov.value_changed.connect(func(v:float):player.camera.fov=v)
	fov.custom_minimum_size.y = 28
	menu_box.add_child(fov)
	menu_spacer(16)
	menu_box.add_child(label("Changes apply immediately.\nUse arrow keys to adjust sliders.",17,Color("a8aaa0")))
	var thoughts := CheckButton.new()
	thoughts.text="Thought subtitles"
	thoughts.button_pressed=thought_subtitles
	thoughts.toggled.connect(func(value: bool):thought_subtitles=value)
	menu_box.add_child(thoughts)
	var sounds := CheckButton.new()
	sounds.text="Sound descriptions"
	sounds.button_pressed=sound_captions
	sounds.toggled.connect(func(value: bool):sound_captions=value)
	menu_box.add_child(sounds)
	menu_box.add_child(button("BACK",func():show_menu(is_pause)))
	volume.grab_focus()


func add_tie_glow(figure: Node3D) -> void:
	var tie := figure.find_child("red_tie*", true, false) as MeshInstance3D
	if tie == null: return
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("b72e29")
	glow.roughness = .8
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.emission_enabled = true
	glow.emission = Color("cd2923")
	glow.emission_energy_multiplier = 1.25
	tie.material_override = glow
	light(figure, Vector3(0,1.45,-.18), Color("d6342c"), .13, .48)

func build_steering_wheel() -> void:
	block(bus,Vector3(-.65,1.47,-3.98),Vector3(.09,.48,.09),"454d49").rotation.x=.65
	var mount := Node3D.new()
	bus.add_child(mount)
	mount.position=Vector3(-.65,1.76,-3.78)
	mount.rotation.x=deg_to_rad(65)
	steering=Node3D.new()
	mount.add_child(steering)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius=.245
	ring.outer_radius=.285
	ring.rings=20
	ring.ring_segments=6
	rim.mesh=ring
	rim.material_override=mat("131b1a")
	steering.add_child(rim)
	for i in range(3):
		var angle := i*TAU/3
		var spoke := block(steering,Vector3(sin(angle)*.14,0,cos(angle)*.14),Vector3(.035,.03,.27),"818879")
		spoke.rotation.y=angle
	var hub := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius=.074
	cylinder.bottom_radius=.074
	cylinder.height=.055
	cylinder.radial_segments=10
	hub.mesh=cylinder
	hub.material_override=mat("313e37")
	steering.add_child(hub)

func sit_down(index: int) -> void:
	if seated_index>=0 or not player_aboard() or not passengers.claim_player_seat(index):return
	seated_index=index
	player.set_seated(true,seats[index]+Vector3(0,0,-.08))
	player.rotation.y=0
	player.camera.rotation.x=0
	current_target=""

func stand_up() -> void:
	if seated_index<0:return
	for offset in [-.12,-.65,.6]:
		var at := Vector3(0,.8,clampf(seats[seated_index].z+offset,-2.6,3.8))
		var blocked := false
		for actor in passengers.actors:
			var other: Vector3=actor.node.position
			if actor.node.visible and Vector2(other.x-at.x,other.z-at.z).length()<.55:blocked=true
		if blocked:continue
		passengers.release_player_seat(seated_index)
		seated_index=-1
		player.set_seated(false,at)
		return
	say("The aisle is blocked.",2)

func request_interaction(id: String) -> void:
	if id.is_empty():return
	if story.stage==Story.Stage.PASSENGER and id=="passenger":
		if not passengers.first_visible():return
		if departure_id.is_empty():
			say("I didn't see you get on.",3)
			set_objective("Find a seat. Keep the aisle clear for boarding.")
		departure_id=id
	elif story.stage==Story.Stage.SECOND_STOP and id=="route":
		if departure_id.is_empty():set_objective("Find a seat. Keep the aisle clear for boarding.")
		departure_id=id
	elif story.interact(id):apply_stage()

func process_departure() -> void:
	if departure_id.is_empty():return
	if story.elapsed<4 or not player_aboard() or doorway_occupied() or not passengers.all_aboard():
		set_door(true)
		return
	set_door(false)
	if door_amount<.01:
		var id := departure_id
		departure_id=""
		if story.interact(id):apply_stage()

func update_watcher() -> void:
	var phase := watcher_phase
	if story.stage>=Story.Stage.NEXT_RIDE:phase=maxi(phase,1)
	if story.stage==Story.Stage.SECOND_STOP and story.elapsed>7:phase=maxi(phase,2)
	if story.stage==Story.Stage.FINAL_RIDE and story.elapsed>8:phase=maxi(phase,3)
	if story.stage>=Story.Stage.DEER and story.elapsed>4:phase=maxi(phase,4)
	var positions := [Vector3(-22,0,-145),Vector3(17,0,-284),Vector3(12,0,-280),Vector3(9,0,-399),Vector3(6.5,0,-397)]
	if phase!=watcher_phase:
		var destination: Vector3=positions[phase]
		if not passengers.watched(player.camera,watcher.global_position+Vector3(0,1.15,0)) and not passengers.watched(player.camera,destination+Vector3(0,1.15,0)):
			watcher.position=destination
			watcher_phase=phase
	watcher.rotation.y=PI/2 if watcher.position.x>0 else -PI/2
