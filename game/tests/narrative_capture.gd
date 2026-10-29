extends RefCounted
const Story=preload("res://scripts/story.gd")
static func run(g) -> void:
	await g.get_tree().create_timer(.4).timeout
	g.start_game(Story.Stage.DEER)
	var a=g.aftermath
	var e=a.events
	a.restore({"phase":"fork","branch":"walk"})
	a.place_player(e.hazard.to_global(Vector3(0,.15,3.8)),e.hazard.to_global(Vector3(0,1.9,0)))
	g.paused=true
	await g.capture_frame("animal-warning")
	e.hazard_changed=true
	e.animal_face.hide()
	e.human_face.show()
	await g.capture_frame("portrait-warning")
	var woods: Node3D=g.signs.boards[-1]
	a.place_player(woods.to_global(Vector3(0,.15,4.5)),woods.to_global(Vector3(0,1.9,0)))
	await g.capture_frame("woods-grammar")
	g.start_game(Story.Stage.SECOND_STOP,4707)
	g.paused=true
	var actor: Dictionary=g.passengers.actors[0]
	actor.node.reparent(g.passengers.outside,true)
	actor.node.position=g.passengers.shelter_point(0)
	actor.node.rotation=Vector3.ZERO
	actor.node.show()
	actor.standing.show()
	actor.seated.hide()
	actor.features=preload("res://scripts/face_loss.gd").prepare(actor.standing)
	preload("res://scripts/face_loss.gd").update(actor.features,1.3)
	a.place_player(actor.node.global_position+Vector3(0,.15,-3),actor.node.global_position+Vector3(0,1.5,0))
	await g.capture_frame("face-falling")
	a.restore({"phase":"town","branch":"bus"})
	a.place_player(Vector3(120,.15,-723),Vector3(120,3,-739))
	g.paused=true
	await g.capture_frame("welcome-gate")
	a.place_player(Vector3(125,.15,-748),Vector3(128,.6,-752))
	await g.capture_frame("town-bodies")
	for id in ["mart","diner","pizza","coffee_shop"]:
		var shop: Node3D=a.district.shops[id]
		a.place_player(shop.to_global(Vector3(-1,.15,15)),shop.to_global(Vector3(0,2.5,5.6)))
		await g.capture_frame(id+"-brand")
	a.place_player(Vector3(114.5,.15,-718.5),Vector3(114.6,.0,-721.5))
	await g.capture_frame("pavement-junction")
	var coffee: Node3D=a.district.shops.coffee_shop
	a.place_player(coffee.to_global(Vector3(4.7,.15,-4.2)),coffee.to_global(Vector3(-1,1.5,.8)))
	a.town_horror.update()
	await g.capture_frame("coffee-blackout")
	a.restore({"phase":"burial","branch":"bus"})
	a.shovel=true
	a.lay_body(a.HOUSE+Vector3(2.2,.18,-9))
	a.place_player(a.HOUSE+Vector3(2.2,.15,-6.7),a.HOUSE+Vector3(2.2,.15,-9))
	g.paused=true
	await g.capture_frame("burial-ready")
	a.restore({"phase":"escape","branch":"walk"})
	for i in range(12):e.add_footprint(a.HOUSE+Vector3(-.2,.0,5+i*.7),0)
	a.place_player(a.HOUSE+Vector3(-3,.15,15),a.HOUSE+Vector3(0,.5,7))
	g.paused=true
	await g.capture_frame("player-bloody-steps")
	a.place_player(e.PATH[3]+Vector3(0,.15,1),e.PATH[4]+Vector3.UP)
	e.start_trail()
	e.trail_index=4
	await g.capture_frame("forestry-way")
	g.paused=false
	e.start_fall("forestry_fall")
	a.state_time=4.8
	e.update_cutscene()
	await g.capture_frame("red-tie-reveal")
	a.update(12)
	a.update(3.1)
	g.paused=true
	await g.capture_frame("morning-wake")
	a.restore({"phase":"fork","branch":"walk"})
	a.place_player(Vector3(62,.15,-687),Vector3(64,1,-687))
	e.start_fall("backstab")
	a.state_time=2.2
	g.paused=false
	e.update_cutscene()
	await g.capture_frame("backstab-fall")
	a.update(3.3)
	await g.capture_frame("try-again")
	print("Rendered: changing hazard, gradual face fall, brands and blackout, clean pavement, route bodies, released-body grave, blood trail, Forestry Way and both first-person falls")
	g.quit_cleanly()
