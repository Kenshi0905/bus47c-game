extends RefCounted
const Story=preload("res://scripts/story.gd")
const Route=preload("res://scripts/route.gd")

static func run(g) -> void:
	await g.get_tree().create_timer(.6).timeout
	# Departures, faceless shelter and body sighting from the bus window.
	await preload("res://tests/district_checks.gd").capture(g)
	var a=g.aftermath
	g.start_game(Story.Stage.PASSENGER)
	g.story.stage=Story.Stage.NEXT_RIDE
	g.story.elapsed=Story.DURATIONS[Story.Stage.NEXT_RIDE]*.4
	g.apply_stage(false)
	g.set_door(false,true)
	g._physics_process(.016)
	g.paused=true
	g.player.camera.look_at(g.bus.to_global(Vector3(22,1.9,-4)))
	g.watcher_director.reset(g.watcher)
	g.update_watcher(2)
	assert(g.watcher.visible)
	g.player.camera.look_at(g.watcher.global_position+Vector3(0,1.4,0))
	g.player.camera.fov=43
	Input.action_press("zoom")
	g.update_watcher(.56)
	g.update_watcher(3.1)
	assert(g.watcher_director.state=="zipping")
	g.update_watcher(.25)
	g.player.camera.look_at(g.watcher.global_position+Vector3(0,1.4,0))
	await g.capture_frame("watcher-dash")
	g.update_watcher(.4)
	g.update_watcher(.9)
	g.player.camera.look_at(g.watcher.global_position+Vector3(0,1.5,0))
	await g.capture_frame("watcher-tree-peek")
	g.start_game(Story.Stage.DEER)
	g.request_interaction("deer")
	a.place_player(Route.FRUIT_SITES[0]+Vector3(1.2,.15,2.2),Route.FRUIT_SITES[0]+Vector3(0,.8,0))
	a.set_phase("forage","Find something to eat.")
	g.paused=true
	await g.capture_frame("fruit-glow")
	a.restore({"phase":"fork","branch":"walk","parts":[0,1]})
	a.place_player(Route.REPAIR_SITES[2]+Vector3(0,.15,1.8),Route.REPAIR_SITES[2]+Vector3(0,.15,0))
	g.paused=true
	await g.capture_frame("repair-search")
	g.show_document("journal")
	await g.capture_frame("journal-crossed-tasks")
	g.close_document()
	a.restore({"phase":"town","branch":"walk"})
	for id in a.district.shops:
		var shop: Node3D=a.district.shops[id]
		a.place_player(shop.to_global(Vector3(-4,.15,14)),shop.to_global(Vector3(0,1.9,4)))
		g.paused=true
		await g.capture_frame(id+"-exterior")
	# Inactive mirror is dark glass, then E reveals the portrait.
	a.place_player(a.HOUSE+Vector3(-3.4,.15,-2.3),a.HOUSE+Vector3(-3.4,1.7,-5))
	a.set_phase("mirror","Look into the mirror.")
	g.paused=true
	await g.capture_frame("mirror-before")
	a.interact("mirror")
	await g.capture_frame("mirror-after-e")
	a.place_player(a.HOUSE+Vector3(2.6,.15,1.2),a.HOUSE+Vector3(4.65,.45,-.2))
	await g.capture_frame("house-vase-floor")
	a.set_phase("escape","Follow Forestry Way.")
	a.place_player(a.HOUSE+Vector3(-3,.15,12),a.HOUSE+Vector3(-9,1.5,15))
	a.update(.01)
	await g.capture_frame("forestry-way-marker")
	# Preserve the original rendered regression for the black failure screen.
	g.start_game(Story.Stage.DEER)
	g.request_interaction("deer")
	a.place_player(Vector3(22,.15,-700),Vector3(16,1.7,-706))
	a.set_phase("return","")
	a.pursuit_grace=0
	a.update(.4)
	g.player.global_position.x+=.3
	a.update(.01)
	a.update(1)
	assert(a.phase=="dead" and not g.transition_shade.visible)
	await g.capture_frame("caught-menu")
	var shot: Image=g.get_viewport().get_texture().get_image()
	var lit := 0
	for y in range(55,350,4):
		for x in range(60,550,4):
			var pixel := shot.get_pixel(x,y)
			if pixel.r+pixel.g+pixel.b>1.2:lit+=1
	assert(lit>100,"Rendered retry menu must stay visible")
	var retry: Button=g.get_viewport().gui_get_focus_owner()
	assert(retry.text=="RETRY CHECKPOINT")
	retry.pressed.emit()
	assert(not g.menu.visible and not g.transition_shade.visible)
	print("Rendered beta: tree dash and peek, viewed-side bodies, four shops, fruit and parts, journal strikes, mirror activation, vase floor, trail marker and visible retry menu")
	g.quit_cleanly()
