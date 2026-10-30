extends RefCounted
## Joined strips share vertices at corners instead of overlapping slabs.
static func build(parent: Node3D, points: Array, width: float, material: Material, elevation: float=.046) -> MeshInstance3D:
	var edges: Array[Vector3]=[]
	for i in range(points.size()):
		var before: Vector3=points[maxi(0,i-1)]
		var after: Vector3=points[mini(points.size()-1,i+1)]
		var tangent := (after-before).normalized()
		edges.append(tangent.cross(Vector3.UP).normalized()*width*.5)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var a: Vector3=points[i]+Vector3.UP*elevation
		var b: Vector3=points[i+1]+Vector3.UP*elevation
		for v in [a-edges[i],b+edges[i+1],a+edges[i],a-edges[i],b-edges[i+1],b+edges[i+1]]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(v)
	var node := MeshInstance3D.new()
	node.name="JoinedPath"
	node.mesh=surface.commit()
	node.material_override=material.duplicate()
	node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	parent.add_child(node)
	return node
