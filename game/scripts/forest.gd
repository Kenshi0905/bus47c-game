extends Node3D
const Route = preload("res://scripts/route.gd")
## Editable, seeded forest. Each 50 m roadside chunk shares instanced meshes.
const CHUNKS := 23
const TREES_PER_SIDE := 140
const SHRUBS_PER_SIDE := 160
const GRASS_PER_SIDE := 210
var tree_count := 0
var understory_count := 0
var batches := 0

func _ready() -> void:
	name = "DenseForest"
	var rng := RandomNumberGenerator.new()
	rng.seed = 470236
	var meshes := [pine_mesh(), bare_mesh(), shrub_mesh(), grass_mesh()]
	for chunk in range(CHUNKS):
		for side in [-1, 1]:
			var transforms: Array = [[], [], [], []]
			var center_z := -1025.0 + chunk * 50.0
			for kind in range(3):
				var count: int = [TREES_PER_SIDE, SHRUBS_PER_SIDE, GRASS_PER_SIDE][kind]
				for i in range(count):
					# Bias the foreground toward the road, with deep layers behind it.
					var spread := pow(rng.randf(), 1.55) * (37.0 if kind == 0 else 17.0)
					var x: float = (-6.9 - spread) if side < 0 else (5.8 + spread)
					var z := center_z + rng.randf_range(-25, 25)
					if in_clearing(x, z): continue
					var mesh_kind := kind + 1 if kind > 0 else (1 if rng.randf() < .15 else 0)
					var height := rng.randf_range(.75, 1.6) if kind == 0 else rng.randf_range(.65, 1.5)
					var width := rng.randf_range(.7, 1.2)
					var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(width, height, width))
					transforms[mesh_kind].append(Transform3D(basis, Route.point(x,0,z)-Vector3(0,0,center_z)))
					if kind == 0: tree_count += 1
					else: understory_count += 1
			for kind in range(4):
				add_batch(meshes[kind], transforms[kind], center_z, 165.0 if kind < 2 else 80.0, rng)
	add_mist()

func in_clearing(x: float, z: float) -> bool:
	if z< -120 and z> -690 and absf(x)<11:return true
	# Clear the actual world-space footpath and small, separate fruit patches.
	if z< -660 and z> -765:
		var world := Route.point(x,0,z)
		var at := Vector2(world.x,world.z)
		var path: Array=[Route.point(4,0,-683)]
		path.append_array(Route.WALK_PATH)
		for i in range(path.size()-1):
			if Geometry2D.get_closest_point_to_segment(at,Vector2(path[i].x,path[i].z),Vector2(path[i+1].x,path[i+1].z)).distance_to(at)<3.8:return true
		for fruit in Route.FRUIT_SITES:
			if world.distance_to(fruit)<2.1:return true
	# Preserve the shelter, boarding approach, stop signs and watcher sightlines.
	if x > 2.5 and x < 12 and z > -16 and z < 12: return true
	for stop_z in [-133.0, -273.0, -413.0, -553.0, Route.TERMINUS_Z-3]:
		if x > 2.5 and x < 10.5 and absf(z - stop_z) < 8: return true
		if x < -4 and x > -9 and absf(z - stop_z + 2) < 3: return true
	# Narrow gaps reveal the distant watcher between trunks rather than at the curb.
	for line in [[Vector2(0,-130),Vector2(-22,-145)], [Vector2(0,-270),Vector2(17,-284)], [Vector2(0,-270),Vector2(12,-280)], [Vector2(0,-390),Vector2(9,-399)]]:
		var closest := Geometry2D.get_closest_point_to_segment(Vector2(x,z),line[0],line[1])
		if closest.distance_to(Vector2(x,z)) < 2.6: return true
	return false

func add_mist() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(16, 3.8)
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/ui/ground_mist.gdshader")
	mesh.material = material
	for z in range(-1040, 100, 14):
		for side in [-1, 1]:
			for layer in range(2):
				var mist := MeshInstance3D.new()
				mist.mesh = mesh
				mist.position = Route.point(side * (8.5 + layer * 10 + sin(float(z)) * 2), .9 + sin(z * .13) * .32 + layer * .28, z + layer * 7)
				mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mist.visibility_range_end = 110
				add_child(mist)

func add_batch(mesh: ArrayMesh, transforms: Array, z: float, distance: float, rng: RandomNumberGenerator) -> void:
	if transforms.is_empty(): return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi.set_instance_transform(i, transforms[i])
		var tint := rng.randf_range(.75, 1.14)
		multi.set_instance_color(i, Color(tint * .96, tint, tint * .97))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.position.z = z
	instance.visibility_range_end = distance
	instance.visibility_range_end_margin = 12
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	batches += 1

func surface() -> SurfaceTool:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	return tool

func append_primitive(tool: SurfaceTool, primitive: PrimitiveMesh, transform: Transform3D, color: Color) -> void:
	var arrays := primitive.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		tool.set_color(color)
		tool.set_normal((transform.basis * normals[index]).normalized())
		tool.add_vertex(transform * vertices[index])

func cone(tool: SurfaceTool, base: float, top: float, height: float, at: Vector3, color: String, tilt: Vector3 = Vector3.ZERO) -> void:
	var shape := CylinderMesh.new()
	shape.bottom_radius = base
	shape.top_radius = top
	shape.height = height
	shape.radial_segments = 5
	shape.rings = 1
	append_primitive(tool, shape, Transform3D(Basis.from_euler(tilt), at), Color(color))

func finish(tool: SurfaceTool, double_sided: bool = false) -> ArrayMesh:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	if double_sided: material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	return tool.commit()

func pine_mesh() -> ArrayMesh:
	var tool := surface()
	cone(tool, .18, .08, 7.5, Vector3(0, 3.75, 0), "45473b")
	for tier in range(4):
		cone(tool, 2.25 - tier * .43, 0, 3.5 - tier * .28, Vector3(0, 4.0 + tier * 1.05, 0), "304335" if tier % 2 == 0 else "263b30")
	return finish(tool)

func bare_mesh() -> ArrayMesh:
	var tool := surface()
	cone(tool, .22, .055, 9, Vector3(0, 4.5, 0), "43463f", Vector3(0, 0, .04))
	for i in range(5):
		var side := -1.0 if i % 2 == 0 else 1.0
		cone(tool, .09, .025, 2.4, Vector3(side * .75, 4 + i * .8, .2 * (i % 2)), "3e423b", Vector3(.2, float(i), side * -.7))
	return finish(tool)

func shrub_mesh() -> ArrayMesh:
	var tool := surface()
	for i in range(3):
		var shape := SphereMesh.new()
		shape.radius = .52
		shape.height = .8
		shape.radial_segments = 5
		shape.rings = 2
		append_primitive(tool, shape, Transform3D(Basis.IDENTITY, Vector3((i - 1) * .38, .38 + (i % 2) * .2, 0)), Color("344637"))
	return finish(tool)

func grass_mesh() -> ArrayMesh:
	var tool := surface()
	for i in range(5):
		var angle := i * 2.4
		var base := Vector3(cos(angle), 0, sin(angle)) * .22
		tool.set_color(Color("46523d"))
		tool.set_normal(Vector3.UP)
		tool.add_vertex(base + Vector3(-.09, 0, 0))
		tool.add_vertex(base + Vector3(.15 * sin(angle), .35 + i * .07, .12))
		tool.add_vertex(base + Vector3(.09, 0, 0))
	return finish(tool, true)
