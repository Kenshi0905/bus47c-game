extends Node
var game
var after
var features: Array[Dictionary]=[]
var origin := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
func setup(g,a) -> void:
	game=g
	after=a
	for mesh in after.mirror_face.get_children():
		if mesh is MeshInstance3D and game.passengers.facial(String(mesh.name).to_lower()):
			var bounds: AABB=mesh.get_aabb()
			features.append({"node":mesh,"center":bounds.get_center(),"position":mesh.position,"scale":mesh.scale})
func reset() -> void:
	for f in features:
		f.node.position=f.position
		f.node.scale=f.scale
		f.node.show()
func start() -> void:
	if after.phase!="mirror":return
	origin=game.player.global_position
	yaw=game.player.rotation.y
	pitch=game.player.camera.rotation.x
	game.player.enabled=false
	game.player.velocity=Vector3.ZERO
	game.player.reset_zoom()
	after.mirror_revealed=true
	after.mirror_face.show()
	after.set_phase("mirror_scene","")
	game.play_sound("mirror")
func update() -> void:
	if after.phase=="mirror":
		var distance: float=game.player.global_position.distance_to(after.HOUSE+Vector3(-3.4,.1,-3.1))
		if distance<1.7:start()
	if after.phase!="mirror_scene":return
	var t: float=after.state_time
	var target: Vector3=after.HOUSE+Vector3(-3.4,.1,-3.0)
	game.player.global_position=origin.lerp(target,smoothstep(0,1.7,t))
	game.player.rotation.y=lerp_angle(yaw,0,smoothstep(0,1.7,t))
	game.player.camera.rotation.x=lerpf(pitch,0,smoothstep(0,1.7,t))
	for f in features:
		var key := String(f.node.name)
		var delay := 2.5 if "eye" in key or "pupil" in key or "brow" in key else (4.8 if "grin" in key or "mouth" in key else 6.3)
		var loss := smoothstep(delay,delay+2.6,t)
		# Shrink about each feature's own centre while it sinks into the face.
		var scale := Vector3(1-loss*.98,1-loss*.98,1)
		f.node.scale=scale
		f.node.position=f.position+f.center*(Vector3.ONE-scale)+Vector3(0,-loss*.018,loss*.065)
		f.node.visible=loss<.99
	after.mirror_count=mini(3,int(maxf(0,t-2)/2.2))
	if t>=10.5:
		after.mirror_count=3
		game.player.enabled=true
		after.set_phase("escape","Leave the house. Follow Forestry Way.")
		after.events.blood_steps=true
		after.events.print_origin=game.player.global_position
		after.save_at("escape")
