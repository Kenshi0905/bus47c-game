extends Node3D
## Jointed limbs settle on the ground before the uniform darkens into the suit.
var pieces: Array[RigidBody3D]=[]
var fabrics: Array[Dictionary]=[]
var joints: Array[PinJoint3D]=[]
var tie: MeshInstance3D
var lapels: Array[MeshInstance3D]=[]
var torso: RigidBody3D
var light: OmniLight3D
var game
const CENTERS=[Vector3(0,1.22,0),Vector3(-.12,.51,0),Vector3(.12,.51,0),Vector3(-.26,1.08,0),Vector3(.26,1.08,0)]
func setup(g) -> void:
	game=g
	name="TransformingPlayerRagdoll"
	var source: Node3D=load("res://assets/characters/01_grinning_clerk.gltf").instantiate()
	for i in range(5):
		var body := RigidBody3D.new()
		add_child(body)
		body.name=["Torso","LeftLeg","RightLeg","LeftArm","RightArm"][i]
		body.position=CENTERS[i]
		body.mass=10 if i==0 else 3
		body.linear_damp=2.5
		body.angular_damp=4
		body.collision_layer=0
		body.collision_mask=1
		body.freeze=true
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius=.14 if i==0 else .06
		capsule.height=.55 if i==0 else .78
		collision.shape=capsule
		body.add_child(collision)
		pieces.append(body)
	torso=pieces[0]
	for part in source.get_children():
		if not part is MeshInstance3D:continue
		var key := String(part.name).to_lower()
		if "head" in key or "neck" in key or "hair" in key or "ear" in key or "case" in key or "handle" in key or game.passengers.facial(key):continue
		var index := 0
		var side: bool=part.get_aabb().get_center().x>0
		if "trouser" in key or "shoe" in key:index=2 if side else 1
		elif "sleeve" in key or "hand" in key or "thumb" in key or "cuff" in key:index=4 if side else 3
		part.owner=null
		part.reparent(pieces[index],false)
		part.position=-CENTERS[index]
		if "shirt" in key or "sleeve" in key or "placket" in key:
			var material: StandardMaterial3D=part.get_active_material(0).duplicate()
			part.material_override=material
			fabrics.append({"material":material,"start":material.albedo_color})
	source.free()
	var suited: Node3D=load("res://assets/characters/06_faceless_watcher.gltf").instantiate()
	for part in suited.get_children():
		if part is MeshInstance3D and "red_tie" in String(part.name):
			part.owner=null
			part.reparent(torso,false)
			part.position=-CENTERS[0]+Vector3(0,0,-.035)
			tie=part
			var material: StandardMaterial3D=game.mat("ac1814",true)
			material.emission_energy_multiplier=0
			material.cull_mode=BaseMaterial3D.CULL_DISABLED
			tie.material_override=material
	suited.free()
	for side in [-1,1]:
		var lapel: MeshInstance3D=game.block(torso,Vector3(side*.09,.13,-.126),Vector3(.075,.24,.018),"323942")
		lapel.rotation.z=side*.28
		lapels.append(lapel)
	light=OmniLight3D.new()
	torso.add_child(light)
	light.position=Vector3(0,0,-.22)
	light.light_color=Color("e82118")
	light.omni_range=1.1
	reset()
func reset() -> void:
	for joint in joints:joint.queue_free()
	joints.clear()
	for i in range(pieces.size()):
		pieces[i].freeze=true
		pieces[i].linear_velocity=Vector3.ZERO
		pieces[i].angular_velocity=Vector3.ZERO
		pieces[i].transform=Transform3D(Basis.IDENTITY,CENTERS[i])
	for item in fabrics:item.material.albedo_color=item.start
	tie.hide()
	for lapel in lapels:lapel.hide()
	light.light_energy=0
	hide()
func begin(at: Vector3, yaw: float) -> void:
	reset()
	global_transform=Transform3D(Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,PI/2),at)
	show()
	for i in range(1,5):
		var joint := PinJoint3D.new()
		add_child(joint)
		joint.position=Vector3((-.12 if i==1 else .12),.92,0) if i<3 else Vector3((-.22 if i==3 else .22),1.43,0)
		joint.node_a=joint.get_path_to(torso)
		joint.node_b=joint.get_path_to(pieces[i])
		joint.set_param(PinJoint3D.PARAM_BIAS,.5)
		joints.append(joint)
	for i in range(pieces.size()):
		pieces[i].freeze=false
		pieces[i].sleeping=false
		pieces[i].linear_velocity=Vector3(0,-.7,0)
		pieces[i].angular_velocity=Vector3(.12,0,(-1 if i%2 else 1)*.22)
func animate(t: float) -> void:
	var change := smoothstep(2.5,7.5,t)
	for item in fabrics:item.material.albedo_color=item.start.lerp(Color("202731"),change)
	tie.visible=change>.05
	# Reveal from the knot down, keeping the top anchored to the chest.
	var growth := maxf(.01,change)
	tie.scale.y=growth*.9
	tie.position.y=-CENTERS[0].y+1.45*(1-growth)
	tie.material_override.emission_energy_multiplier=change*(.75+sin(t*3)*.15)
	for lapel in lapels:
		lapel.visible=change>.2
		lapel.scale.x=maxf(.01,change)
	light.light_energy=change*.12
	if t>2.6:
		for body in pieces:body.freeze=true

func _physics_process(_delta: float) -> void:
	if not visible:return
	var stopped: bool=game.paused or game.modal or game.aftermath.state_time>2.6
	for body in pieces:body.freeze=stopped
