extends RefCounted
const Story=preload("res://scripts/story.gd")
const Scenarios=preload("res://tests/scenario_checks.gd")

static func run(g) -> bool:
	g.start_game(Story.Stage.DEER)
	var a=g.aftermath
	var e=a.events
	a.restore({"phase":"fork","branch":"walk"})
	var sign_at: Vector3=e.hazard.to_global(Vector3(0,2,0))
	a.place_player(e.hazard.to_global(Vector3(0,.15,3.5)),sign_at)
	e.observe_hazard()
	assert(e.hazard_seen and not e.hazard_changed and e.animal_face.visible)
	g.player.rotate_y(PI)
	e.observe_hazard()
	assert(e.hazard_away and not e.hazard_changed)
	a.repairs.collect("part0")
	e.observe_hazard()
	assert(e.hazard_changed and e.human_face.visible and not e.animal_face.visible)
	g.continue_game()
	assert(e.hazard_changed,"Changed warning must persist across checkpoint loads")
	# Safe search includes every required part and fruit, but not distant roaming.
	for at in a.Route.FRUIT_SITES+a.Route.REPAIR_SITES:
		a.place_player(at+Vector3(0,.15,0),at+Vector3.UP)
		e.update(1)
		assert(a.phase=="fork")
	a.place_player(Vector3(63,.15,-682),Vector3(65,1,-682))
	e.update(2)
	assert(a.phase=="backstab" and not g.player.enabled)
	a.update(2.3)
	assert(e.blur.visible and g.player.camera.position.y<.4 and a.pursuer.visible)
	var pause := InputEventAction.new()
	pause.action="pause_game"
	pause.pressed=true
	g._unhandled_input(pause)
	assert(g.paused,"Escape must pause the first-person fall")
	var clock: float=a.state_time
	g._process(20)
	assert(a.state_time==clock)
	g._unhandled_input(pause)
	assert(not g.paused)
	assert(not g.player.enabled)
	a.update(3.1)
	assert(a.phase=="dead" and not e.blur.visible)
	assert(g.get_viewport().gui_get_focus_owner().text=="TRY AGAIN")
	g.continue_game()
	assert(a.phase=="fork" and g.player.enabled and is_zero_approx(g.player.camera.rotation.z))
	a.start_walking()
	a.pursuit_grace=999
	g.player.walking_now=true
	g.player.velocity=Vector3(0,0,-1.8)
	a.pursuit(.1,a.walking_goal())
	assert(a.trail_audio.playing)
	var distant: float=a.pursuer.position.distance_to(g.player.position)
	a.pursuit(24,a.walking_goal())
	assert(a.pursuer.position.distance_to(g.player.position)<distant-8)
	g.player.walking_now=false
	a.pursuit(.01,a.walking_goal())
	assert(not a.trail_audio.playing,"Stopping must immediately silence pursuit steps")
	# Town route content, persistent blackout and burial while the body is released.
	a.restore({"phase":"town","branch":"walk"})
	assert(not a.arrival_prints.visible and not a.town_horror.bodies.visible)
	var coffee: Node3D=a.district.shops.coffee_shop
	a.place_player(coffee.to_global(Vector3(4.7,.15,-4.1)),coffee.to_global(Vector3(0,1,-4)))
	a.update(.1)
	assert(a.town_horror.coffee_blackout)
	a.place_player(coffee.to_global(Vector3(0,.15,7)),coffee.global_position+Vector3.UP)
	a.update(.1)
	for lamp in a.town_horror.coffee_lights:assert(not lamp.visible)
	g.continue_game()
	assert(a.town_horror.coffee_blackout)
	g.continue_game()
	assert(a.town_horror.coffee_blackout,"Blackout must survive repeated saves")
	a.restore({"phase":"town","branch":"bus"})
	assert(a.arrival_prints.visible and a.town_horror.bodies.visible and not a.pursuer.visible)
	assert(g.player.global_position.z> -730,"Bus arrival starts outside the welcome gate")
	assert(a.town_horror.bodies.get_child_count()>23)
	a.restore({"phase":"burial","branch":"bus"})
	a.shovel=true
	a.lay_body(a.HOUSE+Vector3(2.2,.18,-9))
	a.dragging=false
	a.place_player(a.HOUSE+Vector3(2.2,.15,-7.2),a.HOUSE+Vector3(2.2,.2,-9))
	g.update_target()
	assert(g.current_target=="grave" and a.grave_ready())
	g.request_interaction("grave")
	assert(a.phase=="burying","A body placed in the grave can be buried after release")
	a.update(8.1)
	assert(a.phase=="closet_ready")
	# Physically walk the full Forestry Way including the new fence opening.
	a.restore({"phase":"escape","branch":"walk"})
	a.place_player(e.PATH[0]+Vector3(0,.15,1),e.PATH[1]+Vector3.UP)
	a.update(.1)
	assert(a.phase=="forestry_walk" and e.arrow.visible)
	for i in range(1,e.PATH.size()-1):
		await Scenarios.walk_to(g,e.PATH[i]+Vector3(0,.15,0),1100)
	Input.action_press("forward")
	Input.action_press("sprint")
	for i in range(1000):
		var direction: Vector3=e.PATH[-1]-g.player.global_position
		g.player.rotation.y=atan2(-direction.x,-direction.z)
		await g.get_tree().physics_frame
		if a.phase=="forestry_fall":break
	Input.action_release("forward")
	Input.action_release("sprint")
	assert(a.phase=="forestry_fall" and e.prints.get_child_count()>8)
	a.update(4)
	assert(e.own_body.visible and e.tie_light.light_energy>.2)
	a.update(8.1)
	assert(a.phase=="waking" and not e.own_body.visible)
	a.update(3.1)
	assert(a.phase=="loop" and g.player.enabled and g.world_environment.ambient_light_energy>.4 and not e.blur.visible)
	print("PASS: changing hazard, bounded search and recovery, motion-linked near/far footsteps, route-specific bodies and prints, persistent blackout, released-body burial and walked Forestry Way first-person ending")
	return true
