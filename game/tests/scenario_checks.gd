extends RefCounted
const Route=preload("res://scripts/route.gd")
const Story=preload("res://scripts/story.gd")
const HOUSE=Vector3(120,0,-775)

static func walk_to(g, goal: Vector3, max_frames: int=480) -> void:
	Input.action_press("forward")
	Input.action_press("sprint")
	for i in range(max_frames):
		var difference: Vector3=goal-g.player.global_position
		difference.y=0
		if difference.length()<.2:break
		g.player.rotation.y=atan2(-difference.x,-difference.z)
		g.player.camera.rotation=Vector3.ZERO
		await g.get_tree().physics_frame
	Input.action_release("forward")
	Input.action_release("sprint")
	var difference: Vector3=goal-g.player.global_position
	difference.y=0
	assert(difference.length()<.3,"Physical route blocked: %s -> %s" % [g.player.global_position,goal])

static func aim(g, id: String, from: Vector3) -> void:
	var data: Dictionary=g.aftermath.spots[id]
	g.aftermath.place_player(from,data.parent.to_global(data.local))
	g.update_target()
	assert(g.current_target==id,"Reachable scenario interaction: "+id+" got "+g.current_target)

static func run(g) -> bool:
	g.start_game(Story.Stage.DEER)
	g.request_interaction("deer")
	var a=g.aftermath
	assert(a.phase=="disembark" and g.door_goal==1)
	a.update(12)
	assert(a.phase=="disembark" and a.hunger_cues_played==0 and a.hunger==100)
	assert(g.objective.text=="Step off the bus." and not g.subtitle_frame.visible)
	g.set_door(true,true)
	# Physically leave the stopped bus through its open doorway.
	g.player.position=Vector3(.3,.8,-3)
	g.player.rotation=Vector3.ZERO
	g.player.camera.rotation=Vector3.ZERO
	Input.action_press("right")
	for i in range(240):
		await g.get_tree().physics_frame
		if a.phase=="hunger_cue":break
	Input.action_release("right")
	assert(g.player.get_parent()==g,"Breakdown exit: pos=%s enabled=%s paused=%s seated=%s door=%s stage=%s" % [g.player.position,g.player.enabled,g.paused,g.player.seated,g.door_amount,g.story.stage])
	assert(a.phase=="hunger_cue" and a.hunger_cues_played==1 and g.objective.text.is_empty())
	assert(g.sfx.stream.resource_path.ends_with("stomach.wav"),"Stomach rumble starts after disembarking")
	g.show_menu(true)
	g._process(10)
	assert(a.phase=="hunger_cue")
	g.resume_game()
	a.update(1.9)
	g._process(10)
	assert(a.phase=="forage" and a.hunger_cues_played==1)
	assert(g.objective_panel.visible and g.objective_panel.position.y<100 and g.objective_persistent)
	assert(g.objective.text=="Find something to eat." and not g.subtitle_frame.visible)
	for i in range(3):
		var id := "fruit"+str(i)
		var spot: Dictionary=a.spots[id]
		var target: Vector3=spot.parent.to_global(spot.local)
		aim(g,id,Vector3(target.x,.15,target.z+1.7))
		g.request_interaction(id)
	assert(a.phase=="return" and a.hunger==100 and not g.subtitle_frame.visible)
	var goal: Vector3=Route.FOREST_FORK
	a.place_player(a.point(30,-700)+Vector3(0,.15,0),goal+Vector3.UP)
	a.pursuit_grace=0
	var hunger_before: float=a.hunger
	var timer_before: float=a.state_time
	g.show_menu(true)
	g._process(20)
	assert(a.state_time==timer_before and a.hunger==hunger_before)
	g.resume_game()
	# A backward look shows an empty forest. Only a subsequent physical step attacks.
	var forward: Vector3=(goal-g.player.global_position).normalized()
	g.player.camera.look_at(g.player.camera.global_position+forward.rotated(Vector3.UP,PI/2))
	a.update(.5)
	assert(a.phase=="return" and not a.look_back_armed)
	g.player.camera.look_at(g.player.camera.global_position-forward)
	a.update(.4)
	a.update(2)
	assert(a.phase=="return" and a.look_back_armed and not a.pursuer.visible and not g.paused)
	g.player.global_position.x+=.1
	a.update(.1)
	assert(a.phase=="return","Small camera/body settling must not count as a step")
	Input.action_press("right")
	for i in range(40):
		await g.get_tree().physics_frame
		if a.phase=="jumpscare":break
	Input.action_release("right")
	assert(a.phase=="jumpscare" and a.pursuer.visible and not g.paused and not g.player.enabled)
	var scare_time: float=a.state_time
	g.show_menu(true)
	g._process(2)
	assert(a.state_time==scare_time)
	g.resume_game()
	assert(not g.player.enabled)
	a.update(.3)
	assert(a.phase=="jumpscare" and a.pursuer.visible)
	a.update(.7)
	assert(a.phase=="dead" and g.paused)
	assert(not g.transition_shade.visible and g.menu.visible,"Capture fade must never cover the result menu")
	assert(g.transition_shade.get_index()<g.menu.get_index(),"Menus render above scene fades")
	var retry_button: Button=g.get_viewport().gui_get_focus_owner()
	assert(retry_button.text=="RETRY CHECKPOINT" and retry_button.is_visible_in_tree())
	retry_button.pressed.emit()
	assert(not g.paused and not g.menu.visible and not g.transition_shade.visible)
	a.update(.01)
	a.update(1.9)
	assert(a.phase=="forage" and a.fruit_taken.is_empty(),"Forest failure restores a safe checkpoint")
	# Walk the entire continuous trail; no sign interaction or endpoint teleport.
	a.restore({"phase":"fork","branch":"walk"})
	for i in range(1,Route.WALK_PATH.size()):
		await walk_to(g,Route.WALK_PATH[i]+Vector3(0,.15,0),1500)
		assert(a.phase in ["walk","town"],"Walking the path must activate it without E")
	assert(a.phase=="town" and a.branch=="walk")
	# A checkpoint camera faces the same direction as movement.
	var z_before: float=g.player.global_position.z
	Input.action_press("forward")
	await g.get_tree().create_timer(.3).timeout
	Input.action_release("forward")
	assert(g.player.global_position.z<z_before-.2)
	a.place_player(HOUSE+Vector3(0,.15,5.5),HOUSE+Vector3(0,1,0))
	a.update(.1)
	assert(a.phase=="confront")
	var still: Vector3=a.opponent.position
	a.update(20)
	assert(a.phase=="confront" and a.opponent.position==still,"Unarmed player has time to find the knife")
	aim(g,"knife",HOUSE+Vector3(0,.15,5.5))
	g.request_interaction(g.current_target)
	assert(a.knife and a.held_blade.visible and not a.ground_knife.visible)
	assert(not a.try_defend(),"Cannot hit from the doorway")
	await walk_to(g,HOUSE+Vector3(.3,.15,1.0))
	a.place_player(g.player.global_position,a.opponent.global_position+Vector3(0,1.2,0))
	g.update_target()
	var attack := InputEventAction.new()
	attack.action="attack" if a.branch=="walk" else "interact"
	attack.pressed=true
	g._unhandled_input(attack)
	assert(a.phase=="mirror")
	for i in range(3):
		aim(g,"mirror",HOUSE+Vector3(-3.4,.15,-3))
		g.request_interaction("mirror")
		a.update(1.6)
	assert(a.phase=="escape" and not a.eyes[0].visible and not a.mouth.visible and not a.nose.visible)
	aim(g,"escape",HOUSE+Vector3(-9,.15,17))
	g.request_interaction("escape")
	a.update(1.2)
	assert(a.phase=="loop" and g.world_environment.ambient_light_energy>.4)
	aim(g,"ticket",Vector3(5.35,.25,1))
	g.request_interaction("ticket")
	assert(g.modal and g.modal_kind=="ticket")
	g.close_document()
	assert(a.phase=="ending" and g.paused)
	g.return_to_title()
	g.continue_game()
	assert(a.phase=="loop","Main menu must preserve the later story checkpoint")
	# The bus branch completes the actual final leg before its town transition.
	g.start_game(Story.Stage.DEER)
	a.restore({"phase":"fork","branch":"bus"})
	g.player.global_position=g.bus.to_global(Vector3(.3,.8,-3))
	g.board_if_inside()
	assert(g.player.get_parent()==g.bus)
	g.request_interaction("take_bus")
	assert(a.phase=="bus_depart")
	g.set_door(false,true)
	a.update(.1)
	assert(a.phase=="bus_ride")
	a.update(10)
	assert(a.phase=="bus_ride" and g.bus.position.z< -710 and g.bus.position.z>Route.TERMINUS_Z)
	a.update(Route.FINAL_RIDE_SECONDS)
	assert(a.phase=="arrival" and is_equal_approx(g.bus.position.z,Route.TERMINUS_Z) and g.door_goal==1)
	g.set_door(true,true)
	g.player.position=Vector3(2.5,.15,-3)
	g.board_if_inside()
	a.update(.1)
	a.update(1.2)
	assert(a.phase=="town" and a.branch=="bus" and a.intruder_model.visible)
	a.place_player(HOUSE+Vector3(0,.15,5.5),HOUSE+Vector3(0,1,0))
	a.update(.1)
	still=a.opponent.position
	a.update(20)
	assert(a.phase=="confront" and a.opponent.position==still,"Unarmed player has time to find the knife")
	aim(g,"knife",HOUSE+Vector3(0,.15,5.5))
	g.request_interaction(g.current_target)
	assert(a.knife and a.held_blade.visible and not a.ground_knife.visible)
	assert(not a.try_defend(),"Cannot hit from the doorway")
	await walk_to(g,HOUSE+Vector3(.3,.15,1.0))
	a.place_player(g.player.global_position,a.opponent.global_position+Vector3(0,1.2,0))
	g.update_target()
	attack= InputEventAction.new()
	attack.action="attack" if a.branch=="walk" else "interact"
	attack.pressed=true
	g._unhandled_input(attack)
	assert(a.phase=="burial" and a.burial_remaining==180)
	a.update(181)
	assert(a.phase=="dead")
	g.continue_game()
	assert(a.phase=="burial" and a.burial_remaining==180)
	aim(g,"shovel",HOUSE+Vector3(1.5,.15,-7.3))
	g.request_interaction("shovel")
	aim(g,"body",HOUSE+Vector3(0,.15,1.6))
	g.request_interaction("body")
	assert(a.dragging and g.player.movement_scale<1)
	await walk_to(g,HOUSE+Vector3(1.3,.15,-3))
	await walk_to(g,HOUSE+Vector3(0,.15,-4.7))
	await walk_to(g,HOUSE+Vector3(0,.15,-6.1))
	await walk_to(g,HOUSE+Vector3(2.2,.15,-7.2))
	a.place_player(g.player.global_position,HOUSE+Vector3(2.2,.15,-9))
	a.update(.1)
	g.update_target()
	assert(g.current_target=="grave")
	g.request_interaction("grave")
	assert(a.phase=="burying" and not g.player.enabled)
	var remaining: float=a.burial_remaining
	g.show_menu(true)
	g._process(40)
	assert(a.burial_remaining==remaining)
	g.resume_game()
	assert(not g.player.enabled,"Pause must not release the burial movement lock")
	a.update(8.1)
	assert(a.phase=="closet_ready" and not a.opponent.visible)
	aim(g,"closet",HOUSE+Vector3(3.5,.15,-.8))
	g.request_interaction("closet")
	assert(a.phase=="closet" and not g.player.enabled)
	g.show_menu(true)
	g.resume_game()
	assert(not g.player.enabled,"Pause must not let the player walk out while hidden")
	a.interact("leave_closet")
	assert(a.phase=="dead")
	g.continue_game()
	assert(a.phase=="closet_ready")
	g.request_interaction("closet")
	a.update(89)
	assert(a.phase=="closet")
	a.update(1.1)
	assert(a.phase=="dawn" and g.player.enabled)
	aim(g,"coffee",HOUSE+Vector3(2.9,.15,1.4))
	g.request_interaction("coffee")
	aim(g,"newspaper",HOUSE+Vector3(3.9,.15,1.4))
	g.request_interaction("newspaper")
	assert(g.modal and g.modal_kind=="newspaper")
	g.close_document()
	assert(a.phase=="ending" and g.paused)
	print("PASS: physical breakdown exit, scattered fruit, look-back then step ambush, continuous golden path, reachable knife and LMB/E defense, distant terminus, retry/save, mirror, burial timer, closet/dawn and two ending documents")
	return true
