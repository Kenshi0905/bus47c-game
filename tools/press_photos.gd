extends SceneTree
## Render the newspaper's photographs from this project's editable game models.
func _initialize() -> void:
	call_deferred("shoot")

func shoot() -> void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.set_physics_process(false)
	g.get_viewport().size=Vector2i(800,500)
	for node in g.get_children():
		if node is CanvasLayer:node.hide()
	g.aftermath.daylight(true)
	g.world_environment.fog_density=.006
	g.world_environment.ambient_light_energy=.8
	g.bus.position=Vector3.ZERO
	g.bus.rotation=Vector3.ZERO
	for part in g.bus.find_children("*","MeshInstance3D",true,false):
		if part.material_override is StandardMaterial3D:
			var material: StandardMaterial3D=part.material_override.duplicate()
			material.albedo_color=material.albedo_color.darkened(.58)
			material.emission_enabled=false
			part.material_override=material
	var camera: Camera3D=g.menu_camera
	camera.position=Vector3(9,3.2,-12)
	camera.fov=59
	camera.look_at(Vector3(0,1.7,0))
	camera.make_current()
	for x in [-4,4]:g.block(g,Vector3(x,1,-8),Vector3(.05,2,.05),"bbb395")
	g.block(g,Vector3(0,1,-8),Vector3(8,.18,.025),"bbad6f")
	g.text3(g,"POLICE   KEEP CLEAR",Vector3(0,1,-8.04),38).rotation.y=PI
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/ui/press-bus.png")
	var portrait: Node3D=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	g.add_child(portrait)
	portrait.position=Vector3(300,0,0)
	portrait.rotation.y=PI
	g.block(g,Vector3(300,1.5,-.7),Vector3(5,5,.1),"66665c")
	g.light(g,Vector3(299,2,2),Color("eeeecc"),2.0,5)
	camera.position=Vector3(300,1.6,1.6)
	camera.fov=40
	camera.look_at(Vector3(300,1.62,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://assets/ui/press-portrait.png")
	g.quit_cleanly()
