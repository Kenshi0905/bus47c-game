extends RefCounted
static func run(g) -> void:
	await g.get_tree().create_timer(.5).timeout
	await g.capture_frame("title-f")
	g.show_information("controls",false)
	await g.capture_frame("controls")
	g.show_information("credits",false)
	await g.capture_frame("credits-menu")
	g.show_settings(false)
	await g.capture_frame("settings")
	g.show_menu(false)
	g.start_game(10)
	var a=g.aftermath
	a.restore({"phase":"fork","branch":"walk","parts":[0,1,2,3,4]})
	a.events.animal_face.hide()
	a.events.human_face.show()
	a.events.hazard_changed=true
	a.place_player(a.events.hazard.to_global(Vector3(0,.15,3)),a.events.hazard.to_global(Vector3(0,1.8,0)))
	g.paused=true
	await g.capture_frame("hand-painted-warning")
	a.place_player(g.bus.to_global(Vector3(.55,.15,-6.5)),g.bus.to_global(Vector3(.55,1.2,-4.9)))
	a.interact("repair_engine")
	a.update(2.4)
	await g.capture_frame("repair-progress")
	a.restore({"phase":"town","branch":"bus"})
	var spot: Dictionary=a.spots[a.town_horror.resident_spots[0]]
	a.place_player(spot.parent.to_global(Vector3(.4,.15,.9)),spot.parent.to_global(spot.local))
	await g.capture_frame("inspect-resident")
	a.interact(a.town_horror.resident_spots[0])
	var was_paused: bool=g.paused
	g.paused=false
	g._process(.25)
	g.paused=was_paused
	await g.capture_frame("resident-reaction")
	var diner: Node3D=a.district.shops.diner
	a.place_player(diner.to_global(Vector3(0,.15,4.3)),diner.to_global(Vector3(1.3,1.5,-2)))
	await g.capture_frame("diner-interior")
	a.restore({"phase":"closet","branch":"bus"})
	a.interact("closet")
	a.update(16)
	Input.action_press("zoom")
	a.update(.6)
	await g.capture_frame("closet-peek")
	Input.action_release("zoom")
	a.restore({"phase":"dawn","branch":"bus"})
	a.coffee=true
	a.place_player(a.HOUSE+Vector3(3.5,.15,1.6),a.HOUSE+Vector3(3.9,1.1,3))
	g.show_document("newspaper")
	await g.capture_frame("morning-newspaper")
	g.paused=false
	g.close_document()
	g.paused=true
	a.update(6)
	await g.capture_frame("morning-epilogue")
	a.update(16)
	assert(a.presentation.credit_card.is_visible_in_tree())
	await g.capture_frame("end-credits")
	a.restore({"phase":"escape","branch":"walk"})
	g.show_document("journal")
	await g.capture_frame("clear-journal")
	g.quit_cleanly()
