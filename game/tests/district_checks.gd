extends RefCounted
const Story=preload("res://scripts/story.gd")
const Scenarios=preload("res://tests/scenario_checks.gd")

static func run(g) -> bool:
	# New games vary, while a saved journey reproduces its departures.
	var schedules: Dictionary={}
	for seed_value in range(12):
		g.passengers.reset(0,seed_value,0)
		schedules[str(g.passengers.schedule)]=true
	assert(schedules.size()>1)
	g.start_game(Story.Stage.SECOND_STOP,4707)
	var schedule: Array=g.passengers.schedule.duplicate()
	g.save_checkpoint()
	g.continue_game()
	assert(g.trip_seed==4707 and g.passengers.schedule==schedule)
	var exit_stop: int=g.passengers.schedule[0]
	g.start_game(Story.Stage.SECOND_STOP if exit_stop==2 else Story.Stage.THIRD_STOP,4707)
	g.paused=true
	g.set_door(true,true)
	var p=g.passengers
	var actor: Dictionary=p.actors[0]
	g.player.camera.rotation=Vector3.ZERO
	for i in range(1000):
		p.update(.025,g.player.camera,g.player.position,true)
		if actor.state=="exit_stare":break
	assert(actor.state=="exit_stare" and not p.all_aboard())
	var stare: Vector3=actor.node.global_position
	p.update(1.7,g.player.camera,g.player.position,true)
	assert(actor.state=="exit_stare" and actor.node.global_position.is_equal_approx(stare),"Passenger must hold the stare before leaving")
	var toward_player: Vector3=g.player.camera.global_position-actor.node.global_position
	toward_player.y=0
	assert((-actor.node.global_basis.z).dot(toward_player.normalized())>.95,"Doorway stare faces the player")
	for i in range(2000):
		p.update(.025,g.player.camera,g.player.position,true)
		if actor.state=="faceless":break
	assert(actor.state=="faceless" and actor.node.get_parent()==p.outside)
	var skin := 0
	for part in actor.standing.find_children("*","MeshInstance3D",true,false):
		if p.facial(String(part.name).to_lower()):assert(not part.visible)
		if "head" in String(part.name):
			assert(part.visible)
			skin+=1
	assert(skin>0 and not actor.corpse.visible)
	var shelter: Vector3=actor.node.global_position
	for side in [-1,1]:preload("res://tests/roadside_checks.gd").check_body_side(g,0,side)
	assert(actor.node.global_position.is_equal_approx(shelter),"Departed passenger must stay at the shelter when the bus moves")
	assert(actor.corpse.visible and actor.corpse.get_node("BloodPool").visible)
	for part in actor.corpse.find_children("*","MeshInstance3D",true,false):
		if "head" in String(part.name).to_lower():assert(not part.visible)
	# Every store entrance and central aisle is a physical route, in both directions.
	g.start_game(Story.Stage.DEER)
	g.request_interaction("deer")
	g.set_door(true,true)
	g._physics_process(1)
	assert(not g.passengers.exits_busy(),"Remaining passengers must wait for Loomesville, not leave during the breakdown")
	g.aftermath.restore({"phase":"town","branch":"walk"})
	var a=g.aftermath
	for id in a.district.shops:
		var shop: Node3D=a.district.shops[id]
		a.place_player(shop.to_global(Vector3(0,.15,7)),shop.to_global(Vector3(0,1.6,0)))
		await Scenarios.walk_to(g,shop.to_global(Vector3(0,.15,1)))
		await Scenarios.walk_to(g,shop.to_global(Vector3(0,.15,-1.1)))
		g.player.camera.look_at(shop.to_global(Vector3(0,1.17,-2.8)))
		g.update_target()
		assert(g.current_target=="shop_"+id,"Counter clue must be accessible in "+id)
		g.request_interaction(g.current_target)
		assert(g.modal and g.modal_kind=="shop_"+id)
		g.close_document()
		await Scenarios.walk_to(g,shop.to_global(Vector3(0,.15,7)))
	assert(g.signs.boards.size()==5 and g.signs.drops.size()==30)
	var drop: Node3D=g.signs.drops[0].node
	var at: Vector3=drop.position
	g.signs.update(.5)
	assert(not drop.position.is_equal_approx(at))
	print("PASS: seeded departures, held stare, faceless shelter, stationary disembarked actors, matching headless body and blood pool, four physical shop entrances and counter notes, animated warning signs")
	return true

static func capture(g) -> void:
	g.start_game(Story.Stage.SECOND_STOP,4707)
	var exit_stop: int=g.passengers.schedule[0]
	g.start_game(Story.Stage.SECOND_STOP if exit_stop==2 else Story.Stage.THIRD_STOP,4707)
	g.paused=true
	g.set_door(true,true)
	var actor: Dictionary=g.passengers.actors[0]
	for i in range(1000):
		g.passengers.update(.025,g.player.camera,g.player.position,true)
		if actor.state=="exit_stare":break
	g.player.camera.look_at(actor.node.global_position+Vector3(0,1.5,0))
	g.passengers.update(1.1,g.player.camera,g.player.position,true)
	await g.capture_frame("passenger-stare")
	for i in range(2000):
		g.passengers.update(.025,g.player.camera,g.player.position,true)
		if actor.state=="faceless":break
	g.aftermath.place_player(actor.node.global_position-actor.node.global_basis.z*2.8+Vector3(0,.15,0),actor.node.global_position+Vector3(0,1.4,0))
	g.paused=true
	await g.capture_frame("shelter-face")
	g.player.reparent(g.bus,false)
	g.player.position=Vector3(.2,.8,-2.85)
	preload("res://tests/roadside_checks.gd").check_body_side(g,0,-1)
	g.aftermath.place_player(actor.corpse.global_position+Vector3(-2,.15,3.1),actor.corpse.global_position+Vector3(0,.2,-.4))
	g.paused=true
	await g.capture_frame("roadside-body")
	g.bus.position.z=actor.corpse.position.z+6
	g.align_bus()
	g.player.reparent(g.bus,false)
	g.player.position=Vector3(-.4,.8,.8)
	g.player.camera.look_at(actor.corpse.global_position+Vector3(0,.25,0))
	await g.capture_frame("body-from-window")
	var board: Node3D=g.signs.boards[0]
	g.aftermath.place_player(board.to_global(Vector3(.2,.15,5)),board.to_global(Vector3(0,2,0)))
	g.paused=true
	await g.capture_frame("bloody-warning")
	g.aftermath.restore({"phase":"town","branch":"walk"})
	g.aftermath.place_player(Vector3(120,.15,-727),Vector3(114,2,-744))
	g.paused=true
	await g.capture_frame("loomesville-street")
	for id in g.aftermath.district.shops:
		var shop: Node3D=g.aftermath.district.shops[id]
		g.aftermath.place_player(shop.to_global(Vector3(-.3,.15,4.6)),shop.to_global(Vector3(0,1.4,-2)))
		g.paused=true
		await g.capture_frame(id+"-interior")
	g.aftermath.place_player(g.aftermath.HOUSE+Vector3(0,.15,6.7),g.aftermath.HOUSE+Vector3(0,1.6,-3))
	g.paused=true
	await g.capture_frame("house-hall")
