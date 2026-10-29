extends SceneTree
const Atmosphere = preload("res://scripts/journey_atmosphere.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	var mood = g.forest.get_node("JourneyAtmosphere")
	mood.set_process(false)
	g.set_process(false)
	g.set_physics_process(false)
	g.start_game(0)
	g.player.enabled = false
	mood._process(1.0)
	var opening: float = g.world_environment.ambient_light_energy
	var warm: Color = mood.cabin[0].node.light_color
	g.bus.position.z = -620
	mood._process(40.0)
	assert(g.world_environment.ambient_light_energy < opening)
	assert(mood.cabin[0].node.light_color != warm)
	var frozen: float = mood.age
	g.paused = true
	mood._process(40.0)
	assert(mood.age == frozen, "Pause must freeze atmosphere")
	g.paused = false
	g.modal = true
	mood._process(40.0)
	assert(mood.age == frozen, "Reading must freeze atmosphere")
	g.modal = false
	g.aftermath.active = true
	g.aftermath.daylight(true)
	mood._process(1.0)
	assert(is_equal_approx(g.world_environment.ambient_light_energy, .6), "Atmosphere must not overwrite dawn")
	assert(mood.cabin[0].node.light_color == mood.cabin[0].color)
	g.aftermath.active = false
	mood.reset()
	assert(mood.age == 0)
	assert(is_equal_approx(g.world_environment.fog_density, mood.baseline.fog))
	if "--render" in OS.get_cmdline_user_args():
		g.start_game(0)
		g.player.enabled = false
		mood._process(0)
		await g.capture_frame("dread-shelter")
		g.start_game(StoryStage.CAB)
		mood._process(0)
		g.player.camera.look_at(g.bus.to_global(Vector3(0, 1.9, 3.5)))
		await g.capture_frame("dread-cabin-warm")
		g.bus.position.z = -620
		mood._process(55)
		await g.capture_frame("dread-cabin-late")
	print("Atmosphere checks passed: progression, pause, reading, dawn and reset")
	g.quit_cleanly()

const StoryStage = preload("res://scripts/story.gd").Stage
