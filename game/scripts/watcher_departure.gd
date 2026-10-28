extends RefCounted
## Editable mesh dissolve and a world-space smoke remnant, independent of renderer particles.
var root: Node3D
var pieces: Array[MeshInstance3D]=[]
var originals: Array[Dictionary]=[]
var sound: AudioStreamPlayer3D
var elapsed := 0.0
var active := false

func setup(figure: Node3D) -> void:
	if is_instance_valid(root):return
	root=Node3D.new()
	root.name="WatcherDeparture"
	figure.get_parent().add_child(root)
	for i in range(24):
		var piece := MeshInstance3D.new()
		var plane := QuadMesh.new()
		plane.size=Vector2(.45+float(i%4)*.14,.52+float(i%3)*.15)
		piece.mesh=plane
		var material := ShaderMaterial.new()
		material.shader=preload("res://assets/ui/watcher_residue.gdshader")
		material.set_shader_parameter("tint",Vector3(.36,.44,.41) if i!=0 else Vector3(.52,.12,.09))
		piece.material_override=material
		root.add_child(piece)
		pieces.append(piece)
	sound=AudioStreamPlayer3D.new()
	root.add_child(sound)
	sound.stream=preload("res://assets/audio/watcher_veil.wav")
	sound.volume_db=-8
	sound.unit_size=12
	sound.max_distance=50
	root.hide()

func begin(figure: Node3D) -> void:
	setup(figure)
	clear()
	active=true
	elapsed=0
	root.global_transform=figure.global_transform
	root.show()
	sound.play()
	for child in figure.find_children("*","MeshInstance3D",true,false):
		var mesh: MeshInstance3D=child
		var source=mesh.get_active_material(0)
		originals.append({"mesh":mesh,"material":mesh.material_override})
		var material := ShaderMaterial.new()
		material.shader=preload("res://assets/ui/watcher_dissolve.gdshader")
		material.set_shader_parameter("tint",source.albedo_color if source is StandardMaterial3D else Color("83938c"))
		mesh.material_override=material

func restore_materials() -> void:
	for entry in originals:
		if is_instance_valid(entry.mesh):entry.mesh.material_override=entry.material
	originals.clear()

func clear() -> void:
	restore_materials()
	active=false
	elapsed=0
	if is_instance_valid(root):root.hide()
	if is_instance_valid(sound):sound.stop()

func update(delta: float, figure: Node3D, camera: Camera3D) -> bool:
	if not active:return true
	elapsed+=delta
	var amount := clampf(elapsed/.75,0,1)
	for entry in originals:entry.mesh.material_override.set_shader_parameter("dissolve",amount)
	if elapsed>=.75:
		figure.hide()
		restore_materials()
	var fade := smoothstep(2.6,.55,elapsed)
	for i in range(pieces.size()):
		var theta := float(i)*2.399+elapsed*.6
		var radius := .13+elapsed*(.12+float(i%3)*.035)
		pieces[i].position=Vector3(cos(theta)*radius,.2+float(i%12)*.18+elapsed*.32,sin(theta)*radius)
		pieces[i].look_at(camera.global_position)
		pieces[i].material_override.set_shader_parameter("opacity",fade*(.58 if i==0 else .48))
	if elapsed>=2.6:
		clear()
		return true
	return false
