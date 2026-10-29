extends RefCounted
## Mesh-local origins are retained so resetting a journey restores every feature.
const DURATION := 4.2
static func prepare(model: Node3D) -> Array[Dictionary]:
	var parts: Array[Dictionary]=[]
	for part in model.find_children("*","MeshInstance3D",true,false):
		var key := String(part.name).to_lower()
		var group := -1
		if "eye" in key or "pupil" in key or "brow" in key or "tear" in key:group=0
		elif "nose" in key:group=1
		elif "grin" in key or "mouth" in key:group=2
		if group<0:continue
		if not part.has_meta("face_origin"):part.set_meta("face_origin",part.transform)
		parts.append({"node":part,"origin":part.get_meta("face_origin"),"delay":float(group)*.85,"height":part.get_aabb().get_center().y})
	return parts

static func update(parts: Array, age: float) -> void:
	for entry in parts:
		var part: Node3D=entry.node
		var t := maxf(0,age-float(entry.delay))
		part.transform=entry.origin
		# Pull away from the skin, then drop in staggered pieces. The head remains.
		part.position+=Vector3(sin(float(entry.height)*19)*t*.035,-minf(float(entry.height)-.09,t*t*1.8),-.05*minf(t*4,1)-t*.1)
		part.visible=t<2.25

static func restore(model: Node3D) -> void:
	for part in model.find_children("*","MeshInstance3D",true,false):
		if part.has_meta("face_origin"):part.transform=part.get_meta("face_origin")
