extends Node
## Material and practical-light pass for the Compatibility renderer.
const TRANSIT=preload("res://assets/ui/transit_surface.gdshader")
const GLASS=preload("res://assets/ui/rain_glass.gdshader")
const ROAD=preload("res://assets/ui/wet_road.gdshader")
var game
var road_materials: Array[ShaderMaterial]=[]
var windows: Array[MeshInstance3D]=[]
var worn_surfaces := 0
var shadow_lights := 0

func setup(g) -> void:
	game=g
	name="SurfaceAtmosphere"
	process_priority=20
	for mesh in game.bus.find_children("*","MeshInstance3D",true,false):
		var old: Material=mesh.material_override
		if not old is StandardMaterial3D or old.emission_enabled:continue
		if old.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA:
			var material := ShaderMaterial.new()
			material.shader=GLASS
			material.set_shader_parameter("windshield",1.0 if mesh.position.z< -4.5 else 0.0)
			mesh.material_override=material
			windows.append(mesh)
			continue
		var color: String=old.albedo_color.to_html(false)
		var kind := 0
		if color in ["526359","46584f","393f3b"]:kind=1
		elif color in ["31372f","191e20"]:kind=2
		elif mesh.position.y>3.0:kind=3
		if mesh.get_parent()==game.bus or String(mesh.get_parent().name).begins_with("DoorLeaf"):wear(mesh,old.albedo_color,kind)
	for child in game.bus.get_children():
		if child is OmniLight3D:
			child.light_energy=.58
			child.light_color=Color("efc991")
			child.omni_range=3.75
			child.omni_attenuation=1.6
			if is_equal_approx(child.position.z,1.0):enable_shadow(child)
		elif child is SpotLight3D:
			child.light_color=Color("efd5a1")
			child.light_energy=3.2
	for mesh in game.find_children("*","MeshInstance3D",true,false):
		if String(mesh.name).begins_with("RoadSurface"):
			var layer: int=int(mesh.get_meta("road_layer",0))
			mesh.material_override=road_material(Color(["252b2c","929b8c","c7b784"][layer]),float(layer>0))
	var shelter: Node3D=game.get_node("ForestShelter")
	for child in shelter.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var old: StandardMaterial3D=child.material_override
			if not old.emission_enabled and child.position.y<2.0:wear(child,old.albedo_color,4 if child.position.y<1.2 else 0)
		elif child is OmniLight3D:
			child.light_energy=1.5
			child.omni_attenuation=1.7
			enable_shadow(child)
	var home: Node3D=game.aftermath.town.get_node("House17")
	for child in home.get_children():
		if child is OmniLight3D and is_equal_approx(child.position.x,0.0) and child.position.y<2.75:
			child.light_color=Color("dfc59d")
			child.light_energy=.61
			child.omni_range=4.7
			child.omni_attenuation=1.65
			enable_shadow(child)
		elif child is OmniLight3D:
			child.light_energy*=.78
	for material in game.aftermath.district.materials.values():
		if int(material.get_shader_parameter("kind"))==4:
			material.shader=ROAD
			road_materials.append(material)
	_process(0)

func enable_shadow(lamp: OmniLight3D) -> void:
	lamp.shadow_enabled=true
	lamp.shadow_bias=.035
	lamp.shadow_normal_bias=.55
	shadow_lights+=1

func wear(mesh: MeshInstance3D, color: Color, kind: int) -> void:
	var material := ShaderMaterial.new()
	material.shader=TRANSIT
	material.set_shader_parameter("base",color)
	material.set_shader_parameter("kind",kind)
	material.set_shader_parameter("seed",mesh.position.x*3.7+mesh.position.z*.23)
	mesh.material_override=material
	worn_surfaces+=1

func road_material(color: Color, paint: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader=ROAD
	material.set_shader_parameter("base",color)
	material.set_shader_parameter("paint",paint)
	road_materials.append(material)
	return material

func _process(_delta: float) -> void:
	if game==null:return
	var front: Vector3=game.bus.to_global(Vector3(0,0,-4.7))
	var forward: Vector3=-game.bus.global_basis.z
	var night := 1.0 if game.world_environment.ambient_light_energy<.4 and game.bus.visible else 0.0
	for material in road_materials:
		material.set_shader_parameter("bus_front",front)
		material.set_shader_parameter("bus_forward",forward)
		material.set_shader_parameter("lamps_on",night)
