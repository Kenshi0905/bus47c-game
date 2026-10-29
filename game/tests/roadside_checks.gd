extends RefCounted
const Story=preload("res://scripts/story.gd")

## Call after at least 1.1 seconds of the departure stare.
static func check_door_stare(g, actor_index: int) -> void:
	var actor: Dictionary=g.passengers.actors[actor_index]
	assert(actor.state=="exit_stare")
	assert(actor.node.position.x>.5 and actor.node.position.z< -3,"Passenger must stand beside the front door")
	var toward: Vector3=g.player.camera.global_position-actor.node.global_position
	toward.y=0
	var facing: Vector3=-actor.node.global_basis.z
	facing.y=0
	assert(facing.normalized().dot(toward.normalized())>.96,"Doorway stare must face the player, not the bus windshield")

## Call while the watcher is holding its zoom-triggered stare, age about 1.6.
static func finish_watcher_encounter(g) -> void:
	var director=g.watcher_director
	g.update_watcher(1.5)
	assert(director.state=="zipping" and g.watcher.visible)
	assert(director.tree_target!=Vector3.INF and director.tree_positions.has(director.tree_target),"The dash must end at an actual forest trunk")
	assert(director.dash_path_clear(director.zip_origin,g.player.camera,g.bus,director.tree_target),"The visible dash must stay clear of window pillars at every sampled point")
	var origin: Vector3=g.watcher.global_position
	g.update_watcher(.25)
	assert(g.watcher.global_position.distance_to(origin)>1 and g.watcher.visible,"The figure crosses the landscape visibly")
	assert(director.departure.root.visible)
	g.update_watcher(.4)
	assert(director.state=="peeking" and g.watcher.visible)
	g.update_watcher(.9)
	assert(g.watcher.global_position.distance_to(director.tree_target)<1 and g.watcher.visible)
	var peek: Vector3=g.watcher.global_position
	var age: float=director.age
	g.show_menu(true)
	g._physics_process(5)
	assert(director.age==age and g.watcher.global_position==peek,"Pause freezes the tree peek")
	g.resume_game()
	g.update_watcher(2)
	assert(director.state=="retreating")
	g.update_watcher(.5)
	assert(director.state=="dissolving" and director.departure.active)
	g.update_watcher(.4)
	assert(g.watcher.visible and director.departure.root.visible)
	g.update_watcher(.4)
	assert(not g.watcher.visible and director.departure.root.visible,"Smoke lingers after the retreat behind the trunk")
	g.update_watcher(2)
	assert(director.state=="hidden" and not director.departure.active)
	print("PASS: zoom turn, visible dash to real tree, held peek, pause, retreat and lingering remnant")

static func check_body_side(g, actor_index: int, side: int) -> void:
	var p=g.passengers
	var actor: Dictionary=p.actors[actor_index]
	assert(actor.state=="faceless")
	actor.corpse_staged=false
	actor.corpse_reveal=0.0
	actor.corpse.hide()
	g.story.stage=Story.Stage.THIRD_RIDE if p.schedule[actor_index]==2 else Story.Stage.FOURTH_RIDE
	g.bus.position.z=Story.STOP_Z[p.schedule[actor_index]]-25
	g.align_bus()
	g.player.camera.look_at(g.bus.to_global(Vector3(side*25,1.9,-4)))
	p.update(1.3,g.player.camera,g.player.position,false)
	assert(actor.corpse_staged and actor.corpse.visible)
	assert(signf(g.bus.to_local(actor.corpse.global_position).x)==side,"Body must be staged on the side being viewed")
	var at: Vector3=actor.corpse.global_position
	g.player.camera.look_at(g.bus.to_global(Vector3(-side*25,1.9,-4)))
	g.bus.position.z-=5
	g.align_bus()
	p.update(.5,g.player.camera,g.player.position,false)
	assert(actor.corpse.global_position==at,"A revealed body must never follow the camera or teleport")
