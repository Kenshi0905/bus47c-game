extends Node3D
## Finite first-person sequences. They share the story clock and pause with it.
const PHASES=["closet_attack","forest_hounds","closet_exit","bus_choke"]
var game
var after
var actors: Node3D
var attacker: Node3D
var dogs: Array[Node3D]=[]
var jaws: Array[Node3D]=[]
var head: Node3D
var blood: Node3D
var overlay: ColorRect
var material: ShaderMaterial
var origin := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var camera_height := 1.57
var forest_age := 0.0
var cue := 0
var daylight_ready := false
var sound: AudioStreamPlayer3D
var limbs: Array[Node3D]=[]
var roamers: Node3D
var peek_exposure := 0.0
var warned := false

func setup(g,a) -> void:
	game=g
	after=a
	name="NightEncounters"
	actors=Node3D.new()
	add_child(actors)
	attacker=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	actors.add_child(attacker)
	game.add_tie_glow(attacker)
	limbs=game.passengers.rig_limbs(attacker)
	game.light(actors,Vector3(0,2.3,-1.3),Color("c46a57"),1.3,8)
	for i in range(3):build_hound(i)
	head=Node3D.new()
	actors.add_child(head)
	var portrait: Node3D=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	head.add_child(portrait)
	portrait.position.y=-1.72
	for part in portrait.find_children("*","MeshInstance3D",true,false):
		var key := String(part.name).to_lower()
		part.visible="head" in key or "ear" in key or "hair" in key or game.passengers.facial(key)
	blood=Node3D.new()
	actors.add_child(blood)
	for i in range(19):
		var patch: MeshInstance3D=game.block(blood,Vector3(sin(i*2.7)*(.3+i*.024),.071+i*.0005,-2.3+cos(i*4)*(.25+i*.03)),Vector3(.18+float(i%3)*.13,.006,.12+float(i%4)*.09),"bd241e")
		patch.material_override=preload("res://scripts/blood_palette.gd").material()
		patch.rotation.y=i*1.3
	sound=AudioStreamPlayer3D.new()
	actors.add_child(sound)
	sound.stream=preload("res://assets/audio/hell_hounds.wav")
	sound.position=Vector3(0,.6,-2.4)
	sound.volume_db=-9
	sound.unit_size=5
	var ui: Control=game.transition_shade.get_parent()
	overlay=ColorRect.new()
	ui.add_child(overlay)
	ui.move_child(overlay,game.transition_shade.get_index())
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	material=ShaderMaterial.new()
	material.shader=preload("res://assets/ui/blood_vision.gdshader")
	overlay.material=material
	build_roamers()
	reset()

func build_hound(index: int) -> void:
	var dog := Node3D.new()
	actors.add_child(dog)
	dog.name="HellHound"+str(index)
	dogs.append(dog)
	game.block(dog,Vector3(0,.54,0),Vector3(.43,.42,.85),"29282a")
	game.block(dog,Vector3(0,.8,-.46),Vector3(.36,.36,.37),"3a3030")
	game.block(dog,Vector3(0,.7,-.72),Vector3(.26,.18,.32),"443235")
	var jaw := Node3D.new()
	dog.add_child(jaw)
	jaw.position=Vector3(0,.61,-.49)
	game.block(jaw,Vector3(0,0,-.2),Vector3(.25,.06,.39),"6a2824")
	jaws.append(jaw)
	for side in [-1,1]:
		game.block(dog,Vector3(side*.14,.85,-.64),Vector3(.065,.05,.028),"e74b23",false,true)
		var ear: MeshInstance3D=game.block(dog,Vector3(side*.14,1.05,-.39),Vector3(.11,.28,.09),"342b2b")
		ear.rotation.z=side*-.25
		for z in [-.29,.3]:game.block(dog,Vector3(side*.19,.25,z),Vector3(.1,.5,.13),"29272a")
		for z in [-.15,-.3]:game.block(jaw,Vector3(side*.09,.055,z),Vector3(.035,.07,.04),"d6bea0")
	var tail: MeshInstance3D=game.block(dog,Vector3(0,.63,.64),Vector3(.07,.08,.5),"29272a")
	tail.rotation.x=-.45

func reset() -> void:
	forest_age=0
	peek_exposure=0
	warned=false
	if is_instance_valid(roamers):roamers.hide()
	daylight_ready=false
	cue=0
	actors.hide()
	overlay.hide()
	sound.stop()
	sound.stream_paused=false
	game.player.camera.rotation.z=0
	game.player.camera.position.x=0

func begin(kind: String) -> void:
	origin=game.player.global_position
	yaw=game.player.rotation.y
	pitch=game.player.camera.rotation.x
	camera_height=game.player.camera.position.y
	game.player.enabled=false
	game.player.confined=false
	game.player.velocity=Vector3.ZERO
	game.player.reset_zoom()
	game.player.camera.position.z=0
	after.held_blade.hide()
	after.trail_audio.stop()
	after.set_phase(kind,"")
	after.status.text=""
	cue=0
	if kind=="closet_exit":return
	actors.global_position=origin
	actors.global_position.y=.05 if kind=="closet_attack" else 0.0
	actors.rotation.y=yaw
	if kind=="closet_attack":
		# Face the opening regardless of the last peeking angle.
		yaw=PI
		actors.rotation.y=PI
	actors.show()
	attacker.visible=kind in ["closet_attack","bus_choke"]
	if kind=="bus_choke":actors.global_position=origin
	attacker.position=Vector3(0,0,-2.5)
	attacker.rotation.y=PI
	head.hide()
	blood.hide()
	for dog in dogs:dog.hide()
	overlay.show()
	material.set_shader_parameter("amount",0.0)
	game.play_sound("impact" if kind=="bus_choke" else ("knock" if kind=="closet_attack" else "rustle"))

func update(delta: float) -> void:
	update_roamers(delta)
	# The district remains safe. Only unfinished mirror business plus actually
	# crossing the surrounding forest boundary arms this encounter.
	if after.branch=="walk" and after.town_entered and after.phase in ["town","confront","mirror"] and after.mirror_count<3:
		var at: Vector3=game.player.global_position
		var forest: bool=at.z< -809 or at.x<94 or at.x>168 or at.z> -696
		forest_age=forest_age+delta if forest else 0.0
		if forest_age>1.2:begin("forest_hounds")
	else:forest_age=0
	if after.phase not in PHASES:return
	var t: float=after.state_time
	var camera: Camera3D=game.player.camera
	if after.phase=="bus_choke":
		attacker.position=Vector3(0,-.05,-.48)
		attacker.rotation=Vector3(.18,PI,0)
		for i in [1,3]:limbs[i].rotation.x=1.5
		camera.rotation=Vector3(lerpf(pitch,.42,smoothstep(0,1,t))+sin(t*13)*.025,0,sin(t*8)*.045)
		camera.position.y=lerpf(camera_height,.32,smoothstep(1.5,4.8,t))
		attacker.position.y=-smoothstep(1.5,4.8,t)*.9
		material.set_shader_parameter("amount",smoothstep(.3,5,t)*.85)
		material.set_shader_parameter("pulse",exp(-t*3)*.9)
		after.events.set_blur(smoothstep(1,5,t)*4,0,smoothstep(0,2,t)*.4)
		if cue==0:
			cue=1
			game.play_sound("choke")
		if t>=6:
			reset()
			after.fail("This was not your stop.")
		return
	if after.phase=="closet_exit":
		game.player.rotation.y=lerp_angle(yaw,PI,smoothstep(0,1.3,t))
		for i in range(2):after.wardrobe_doors[i].rotation.y=(-1.25 if i==0 else 1.25)*smoothstep(0,.55,t)
		game.player.global_position=origin.lerp(after.HOUSE+Vector3(3.5,.15,-1.5),smoothstep(.45,1.65,t))
		camera.position.y=lerpf(camera_height,1.57,smoothstep(.3,1.65,t))
		if t>=1.7:after.start_dawn()
		return
	var closet: bool=after.phase=="closet_attack"
	var forward := Basis(Vector3.UP,yaw)*Vector3.FORWARD
	if closet:
		for i in range(2):after.wardrobe_doors[i].rotation.y=(-1.4 if i==0 else 1.4)*smoothstep(.2,.65,t)
		attacker.position.z=lerpf(-2.5,-.85,smoothstep(.4,1.2,t))-1.25*smoothstep(1.1,3.1,t)
		attacker.position.x=1.15*smoothstep(3.8,4.8,t)
		attacker.rotation.x=-.45*smoothstep(1,2,t)
		for i in [1,3]:
			limbs[i].rotation.x=lerpf(0,1.25,smoothstep(.6,1.2,t))*(1-smoothstep(3.3,4.2,t))
			limbs[i].rotation.z=(.22 if i==1 else -.22)*smoothstep(.5,1.2,t)
		game.player.global_position=origin+forward*1.25*smoothstep(1.1,3.1,t)
	else:
		game.player.global_position=origin+forward*.4*smoothstep(.5,2,t)
	game.player.rotation.y=lerp_angle(game.player.rotation.y,yaw,clampf(delta*5,0,1))
	camera.position.y=lerpf(camera_height,.27,smoothstep(1.2,3.2,t))
	camera.rotation=Vector3(lerpf(pitch,-.03,smoothstep(1,3.3,t)),0,.24*smoothstep(1.8,3.3,t))
	if closet:camera.rotation.x=lerpf(pitch,1.02,smoothstep(1.2,2.7,t))*(1-smoothstep(3.5,5,t))
	if t>1.25 and cue==0:
		cue=1
		game.play_sound("impact")
		sound.play()
	if t>3.8 and cue==1:
		cue=2
		game.play_sound("impact")
		head.show()
		blood.show()
	head.position=Vector3(.18,.28,-2.3)
	head.rotation=Vector3(.3,t*.6,1.2)
	for i in range(dogs.size()):
		var dog: Node3D=dogs[i]
		dog.visible=t>(3.4 if closet else .3)+i*.22
		var progress := smoothstep(3.5 if closet else .3,6.5,t)
		dog.position=Vector3((-1.0 if i==0 else 1.0)*(.6+i*.35),0,lerpf(-7-i,-2.7-i*.25,progress))
		dog.look_at(actors.to_global(Vector3(.18,.3,-2.3)),Vector3.UP)
		dog.rotation.x=-.22*smoothstep(6.5,8,t)+sin(t*12+i)*.035
		jaws[i].rotation.x=.12+absf(sin(t*9+i))*.42
		if t>7:dog.position.y=absf(sin(t*8+i))*.045
	material.set_shader_parameter("amount",smoothstep(1,9.5,t)*.93)
	material.set_shader_parameter("pulse",exp(-pow((t-1.4)*4,2))*.4+exp(-pow((t-4)*3,2))*.5)
	if t>=11:
		var reason := "The thing saw you through the open door." if peek_exposure>=5 else "You left the wardrobe before daylight."
		reset()
		after.fail(reason if closet else "The forest took you before you faced the mirror.")

func build_roamers() -> void:
	roamers=Node3D.new()
	add_child(roamers)
	roamers.name="WardrobeNightVisitors"
	for i in range(2):
		var dog: Node3D=dogs[i].duplicate()
		roamers.add_child(dog)
		dog.scale=Vector3(.68,.85,.85)
	for i in range(2):
		var figure: Node3D=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
		roamers.add_child(figure)
		figure.scale=Vector3(.65,1.18,.7)
		figure.rotation.z=.1 if i==0 else -.1
		game.add_tie_glow(figure) if i==1 else game.light(figure,Vector3(0,1,-.3),Color("887e70"),.12,2)
		for part in figure.find_children("*","MeshInstance3D",true,false):
			if "red_tie" in String(part.name) and i==0:part.hide()

func update_roamers(delta: float) -> void:
	roamers.visible=after.phase=="closet" and not daylight_ready
	if not roamers.visible:return
	var t: float=after.state_time
	for i in range(roamers.get_child_count()):
		var actor: Node3D=roamers.get_child(i)
		var x := 3.25+sin(t*.24+i*2)*.65
		var z := 1.2+sin(t*.17+i*1.6)*2.5
		actor.global_position=after.HOUSE+Vector3(x,.07+absf(sin(t*4+i))*.025,z)
		actor.rotation.y=PI if cos(t*.17+i*1.6)>0 else 0
		if i==3 and peek_exposure>2:actor.look_at(Vector3(game.player.global_position.x,actor.global_position.y,game.player.global_position.z))
	# Exposure decays, so repeatedly tapping peek cannot reset detection instantly.
	peek_exposure=clampf(peek_exposure+delta*(1 if Input.is_action_pressed("zoom") else -1.6),0,5.2)
	if peek_exposure>2.7 and not warned:
		warned=true
		game.play_sound("knock")
	if peek_exposure<1:warned=false
	if peek_exposure>=5.2:
		roamers.hide()
		begin("closet_attack")
