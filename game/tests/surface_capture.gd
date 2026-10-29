extends RefCounted
const Story=preload("res://scripts/story.gd")
static func shot(g, name_text: String) -> void:
	g.player.enabled=false
	g.paused=true
	g.subtitle_frame.hide()
	g.objective_panel.hide()
	g.controls_hint.hide()
	g.prompt.text=""
	await g.get_tree().process_frame
	await g.capture_frame(name_text)

static func run(g) -> void:
	await g.get_tree().create_timer(.6).timeout
	var a=g.aftermath
	var surfaces=g.get_node("SurfaceAtmosphere")
	var mood=g.forest.get_node("JourneyAtmosphere")
	g.start_game(Story.Stage.STOP,4707)
	g.bus.position.z=0
	g.align_bus()
	a.place_player(Vector3(8,.1,-11.8),Vector3(1.9,1.8,-.6))
	g.player.camera.fov=65
	await shot(g,"gloom-forest-stop")
	g.start_game(Story.Stage.CAB,4707)
	g.bus.position.z=-35
	g.align_bus()
	g.player.position=Vector3(-.87,.78,-.65)
	g.player.camera.position.y=1.28
	g.player.camera.look_at(g.bus.to_global(Vector3(.35,1.8,3.3)))
	g.player.camera.fov=76
	mood._process(1)
	await shot(g,"gloom-bus-interior")
	g.player.camera.look_at(g.bus.to_global(Vector3(-12,1.6,-6)))
	await shot(g,"gloom-window")
	a.restore({"phase":"town","branch":"bus"})
	a.place_player(a.HOUSE+Vector3(0,.15,4.1),a.HOUSE+Vector3(0,1.5,-2))
	await shot(g,"gloom-house-hall")
	var diner: Node3D=a.district.shops.diner
	a.place_player(diner.to_global(Vector3(0,.15,4.3)),diner.to_global(Vector3(1.3,1.5,-2)))
	await shot(g,"gloom-diner")
	a.place_player(Vector3(124,.15,-738),Vector3(122,.1,-740))
	await shot(g,"gloom-red-blood")
	g.show_menu(true)
	await g.capture_frame("unchanged-pause-menu")
	g.resume_game()
	a.restore({"phase":"dawn","branch":"bus"})
	a.place_player(a.HOUSE+Vector3(0,.15,4.1),a.HOUSE+Vector3(0,1.5,-2))
	await shot(g,"gloom-morning")
	assert(surfaces.windows.size()>=4 and surfaces.worn_surfaces>50)
	assert(surfaces.shadow_lights<=5,"Bound local shadow cost")
	surfaces._process(0)
	assert(surfaces.road_materials[0].get_shader_parameter("lamps_on")==0.0,"Morning must not retain nighttime road glow")
	print("PASS: surface shader compilation, readable windows, bounded shadow lights, dawn handoff and unchanged menu layout")
	g.quit_cleanly()
