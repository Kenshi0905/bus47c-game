extends RefCounted
const Shot=preload("res://tests/surface_capture.gd")
static func run(g) -> void:
	await g.get_tree().create_timer(.6).timeout
	var a=g.aftermath
	g.start_game(0,4707)
	g.deer.show()
	g.deer.position=Vector3(7,.06,-7)
	g.deer.rotation=Vector3(0,.55,0)
	g.deer.gait(0,false)
	a.place_player(Vector3(9,.1,-10),Vector3(7,1.2,-7))
	await Shot.shot(g,"stag")
	a.restore({"phase":"town","branch":"bus"})
	a.place_player(Vector3(120,.15,-724),Vector3(119,.4,-772))
	await Shot.shot(g,"town-street")
	a.place_player(Vector3(131,.15,-755),Vector3(128.4,.65,-752))
	await Shot.shot(g,"stacked-bodies")
	a.restore({"phase":"dawn","branch":"bus"})
	a.place_player(a.HOUSE+Vector3(0,.15,4),a.HOUSE+Vector3(0,1.1,-2))
	await Shot.shot(g,"house-floor")
	a.interact("coffee")
	a.state_time=7.7
	a.coffee_station.update(7.7)
	a.presentation.update()
	await Shot.shot(g,"coffee-pour")
	a.restore({"phase":"town","branch":"walk"})
	a.opponent.hide()
	a.set_phase("mirror","")
	a.place_player(a.HOUSE+Vector3(-3.4,.15,-3),a.HOUSE+Vector3(-3.4,1.7,-5))
	a.mirror_sequence.start()
	a.state_time=2
	a.mirror_sequence.update()
	await Shot.shot(g,"mirror-start")
	a.state_time=6.5
	a.mirror_sequence.update()
	await Shot.shot(g,"mirror-decay")
	a.restore({"phase":"closet","branch":"bus"})
	a.interact("closet")
	Input.action_press("zoom")
	a.update(1.8)
	g.player.camera.position.z=-.36
	g.player.camera.rotation=Vector3(0,0,0)
	await Shot.shot(g,"wardrobe-peek")
	Input.action_release("zoom")
	a.restore({"phase":"escape","branch":"walk"})
	a.place_player(Vector3(111,.15,-787),Vector3(111,1,-803))
	await Shot.shot(g,"forestry-checkpoint")
	a.place_player(Vector3(76,.15,-843),Vector3(61,1,-853))
	a.events.start_fall("forestry_fall")
	g.paused=false
	await g.get_tree().create_timer(1.9).timeout
	await Shot.shot(g,"fall-uniform")
	g.paused=false
	await g.get_tree().create_timer(5.8).timeout
	await Shot.shot(g,"fall-suit")
	g.quit_cleanly()
