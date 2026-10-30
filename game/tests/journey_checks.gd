extends RefCounted
const Story=preload("res://scripts/story.gd")
static func run(g) -> bool:
	var a=g.aftermath
	for seed_value in range(40):
		g.passengers.reset(0,seed_value,0)
		for stop in g.passengers.schedule:assert(stop>=2 and stop<=4,"No passenger remains for Loomesville")
	for stage in [Story.Stage.PASSENGER,Story.Stage.SECOND_STOP,Story.Stage.THIRD_STOP,Story.Stage.FOURTH_STOP]:
		g.start_game(stage,4707)
		g.set_door(true,true)
		g.player.position=Vector3(1.8,.65,-3)
		g.board_if_inside()
		assert(a.phase=="bus_choke" and not g.player.enabled)
		g.show_menu(true)
		g._process(8)
		assert(a.state_time==0,"Choking pauses with the menu")
		g.resume_game()
		a.update(6.1)
		assert(a.phase=="dead" and g.menu.visible and not g.transition_shade.visible)
		g.continue_game()
		assert(g.story.stage==stage and not a.active and g.player.enabled)
	# A full penultimate stop cannot close the doors on its final departure.
	g.start_game(Story.Stage.FOURTH_STOP,4707)
	g.paused=true
	g.set_door(true,true)
	g.player.position=Vector3(-.8,.8,-4.1)
	g.player.camera.rotation=Vector3.ZERO
	for i in range(6000):
		g.passengers.update(.05,g.player.camera,g.player.position,true)
		if g.passengers.all_aboard():break
	for actor in g.passengers.actors:assert(actor.state=="faceless")
	a.restore({"phase":"closet","branch":"bus"})
	a.interact("closet")
	Input.action_press("zoom")
	a.update(3)
	assert(a.phase=="closet" and a.encounters.warned and a.encounters.roamers.visible)
	assert(absf(a.wardrobe_doors[0].rotation.y)>.7)
	a.update(2.3)
	Input.action_release("zoom")
	assert(a.phase=="closet_attack","A sustained peek is detected")
	a.update(11.1)
	assert(a.phase=="dead" and not a.encounters.overlay.visible)
	a.restore({"phase":"town","branch":"walk"})
	a.opponent.hide()
	a.set_phase("mirror","")
	a.place_player(a.HOUSE+Vector3(-3.4,.15,-3),a.HOUSE+Vector3(-3.4,1.7,-5))
	a.update(.1)
	assert(a.phase=="mirror_scene" and a.mirror_revealed)
	a.update(3.3)
	assert(a.eyes[0].visible and a.eyes[0].scale.x<1 and a.eyes[0].scale.x>.1 and a.nose.visible)
	a.update(7.3)
	assert(a.phase=="escape" and g.player.enabled and a.mirror_count==3)
	a.place_player(Vector3(76,.15,-843),Vector3(61,1,-853))
	a.events.start_fall("forestry_fall")
	var body=a.events.own_body
	var top: float=body.torso.global_position.y
	g.paused=false
	await g.get_tree().create_timer(1.8).timeout
	assert(body.torso.global_position.y<top-.15,"The physical ragdoll must fall under gravity")
	for piece in body.pieces:assert(piece.global_position.distance_to(body.torso.global_position)<1.8)
	assert(not body.tie.visible,"The protagonist still wears the original uniform during the fall")
	g.paused=true
	await g.get_tree().physics_frame
	var paused_at: Vector3=body.torso.global_position
	await g.get_tree().create_timer(.2).timeout
	assert(body.torso.global_position.distance_to(paused_at)<.015,"Pause freezes the physical body as well as the story clock")
	g.paused=false
	await g.get_tree().create_timer(6).timeout
	assert(body.tie.visible and body.light.light_energy>.05 and body.pieces[0].freeze)
	a.update(6)
	a.update(3.1)
	assert(a.phase=="loop" and g.player.enabled)
	a.restore({"phase":"dawn","branch":"bus"})
	a.interact("coffee")
	a.update(7.5)
	assert(a.coffee_station.stream.visible and not a.coffee)
	assert(a.presentation.panel.get_theme_stylebox("panel") is StyleBoxEmpty)
	assert(a.presentation.action_step.text=="Pour into the cup")
	a.update(4.6)
	assert(a.coffee and a.phase=="dawn" and not a.coffee_station.stream.visible)
	print("PASS: every forbidden stop death and retry, empty final bus, wider timed peek detection, automatic gradual mirror, physical transforming ragdoll, transparent pixel actions and staged coffee")
	return true
