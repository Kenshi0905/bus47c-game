extends RefCounted
const Story=preload("res://scripts/story.gd")
const Route=preload("res://scripts/route.gd")
const Scenarios=preload("res://tests/scenario_checks.gd")

static func run(g) -> bool:
	g.start_game(Story.Stage.DEER)
	var a=g.aftermath
	a.restore({"phase":"fork","branch":"bus"})
	g.request_interaction("take_bus")
	assert(a.phase=="fork" and not a.repairs.repaired,"Food alone must not repair the engine")
	for i in range(5):
		var at: Vector3=Route.REPAIR_SITES[i]
		Scenarios.aim(g,"part"+str(i),at+Vector3(0,.15,1.5))
		g.request_interaction(g.current_target)
		g.request_interaction("part"+str(i))
		assert(a.repairs.taken.size()==i+1)
		if i==2:
			g.continue_game()
			assert(a.phase=="fork" and a.repairs.taken.size()==3,"Collected parts survive a checkpoint reload")
	assert(a.repairs.taken.size()==5 and not a.repairs.repaired)
	Scenarios.aim(g,"repair_engine",g.bus.to_global(Vector3(.55,.15,-6.5)))
	g.request_interaction("repair_engine")
	assert(a.phase=="repairing" and not g.player.enabled)
	a.update(2)
	var timer: float=a.state_time
	g.show_menu(true)
	g._process(10)
	assert(a.state_time==timer and not a.repairs.repaired)
	g.resume_game()
	assert(not g.player.enabled,"Pause cannot release the repair animation lock")
	a.update(3.1)
	assert(a.phase=="fork" and a.repairs.repaired and g.player.enabled)
	g.continue_game()
	assert(a.repairs.repaired and a.repairs.taken.size()==5)
	g.player.global_position=g.bus.to_global(Vector3(.3,.8,-3))
	g.board_if_inside()
	g.request_interaction("take_bus")
	assert(a.phase=="bus_depart")
	# The alternative path remains available with no repair items.
	a.restore({"phase":"fork","branch":"walk"})
	g.request_interaction("shortcut")
	assert(a.phase=="walk" and a.repairs.taken.is_empty())
	var at := Vector3(53,.15,-718)
	a.place_player(at,Route.WALK_PATH[2]+Vector3.UP)
	a.pursuit_grace=999
	a.state_time=1
	g.player.walking_now=true
	g.player.velocity=Vector3(0,0,-2.8)
	a.pursuit(.01,Route.WALK_PATH[2])
	var far: float=a.pursuer.position.distance_to(g.player.position)
	a.state_time=36
	a.pursuit(30,Route.WALK_PATH[2])
	assert(a.pursuer.position.distance_to(g.player.position)<far-2 and a.trail_audio.volume_db>-7)
	# Reproduce the side detour to the mart with an armed forest encounter.
	a.look_back_armed=true
	a.look_back_origin=at
	var mart: Node3D=a.district.shops.mart
	a.place_player(mart.to_global(Vector3(0,.15,7)),mart.to_global(Vector3(0,1.2,0)))
	a.update(.1)
	assert(a.phase=="town" and a.town_entered and not a.look_back_armed)
	for i in range(4):
		g.player.rotate_y(PI/2)
		g.player.position.x+=.3
		a.update(2)
	assert(a.phase=="town" and not a.pursuer.visible and not a.trail_audio.playing and not g.transition_shade.visible)
	assert(not a.mirror_face.visible and not a.mirror_revealed)
	a.set_phase("mirror","Look into the mirror.")
	a.place_player(a.HOUSE+Vector3(-3.4,.15,-3),a.HOUSE+Vector3(-3.4,1.7,-5))
	a.update(.01)
	assert(a.mirror_revealed and a.mirror_face.visible and a.mirror_count==0 and a.eyes[0].visible)
	a.update(10.6)
	a.update(.01)
	assert(a.phase=="escape" and a.district.forestry_marker.visible)
	var journal: String=preload("res://scripts/shift_journal.gd").content(g)
	assert("[s]" in journal and "Forestry Way" in journal)
	assert(Story.DURATIONS[Story.Stage.NEXT_RIDE]>30 and Route.FINAL_RIDE_SECONDS>36)
	g.start_game(Story.Stage.DEER)
	a.restore({"phase":"fork","branch":"walk"})
	a.start_walking()
	g.audio_story.update(8.1)
	assert(g.audio_story.bed.playing and g.audio_story.tension.playing)
	assert(g.audio_story.bed.stream.loop_end==44100*24,"Stereo ambience must loop in sample frames, not channel samples")
	var walk_age: float=g.audio_story.walk_age
	g.show_menu(true)
	g.audio_story.update(5)
	assert(g.audio_story.walk_age==walk_age and g.audio_story.bed.stream_paused)
	g.resume_game()
	a.fail("Audio recovery test")
	g.audio_story.update(.1)
	assert(g.audio_story.event.playing and not g.audio_story.event.stream_paused)
	assert(g.audio_story.event.stream.resource_path.ends_with("pack_death.wav") and not g.audio_story.bed.playing)
	g.start_game(0)
	assert(not g.audio_story.event.playing and not g.audio_story.bed.playing)
	print("PASS: five actual parts, repair lock and save recovery, optional unrepaired footpath, closer pursuit audio, safe town side detour, mirror activation, Forestry Way marker and crossed-out notes")
	return true
