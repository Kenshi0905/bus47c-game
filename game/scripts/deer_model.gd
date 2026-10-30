extends Node3D
## Editable stag anatomy. Feet, hocks, ears and branched antlers stay separate.
var legs: Array[Node3D]=[]
var game
func ellipsoid(parent: Node3D, title: String, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=title
	var shape := SphereMesh.new()
	shape.radius=.5
	shape.height=1
	shape.radial_segments=10
	shape.rings=5
	node.mesh=shape
	node.material_override=game.mat(color)
	parent.add_child(node)
	node.position=at
	node.scale=size
	return node
func bone(parent: Node3D, title: String, a: Vector3, b: Vector3, radius: float, color: String, taper: float=.7) -> void:
	var node := MeshInstance3D.new()
	node.name=title
	var shape := CylinderMesh.new()
	shape.top_radius=radius*taper
	shape.bottom_radius=radius
	shape.height=a.distance_to(b)
	shape.radial_segments=7
	node.mesh=shape
	node.material_override=game.mat(color)
	parent.add_child(node)
	node.position=(a+b)*.5
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
func build(g) -> void:
	game=g
	name="LoomesvilleStag"
	ellipsoid(self,"Ribcage",Vector3(0,1.02,.1),Vector3(.48,.62,1.32),"795a3c")
	ellipsoid(self,"WhiteBelly",Vector3(0,.84,.08),Vector3(.34,.24,1.0),"a9916b")
	ellipsoid(self,"Haunch",Vector3(0,1.02,.57),Vector3(.48,.59,.48),"6e5137")
	bone(self,"RisingNeck",Vector3(0,1.04,-.43),Vector3(0,1.65,-.67),.19,"806044",.6)
	ellipsoid(self,"Throat",Vector3(0,1.38,-.62),Vector3(.21,.48,.23),"ae9875")
	ellipsoid(self,"Head",Vector3(0,1.69,-.76),Vector3(.26,.33,.45),"856549")
	ellipsoid(self,"LongMuzzle",Vector3(0,1.58,-1.01),Vector3(.19,.2,.34),"947452")
	ellipsoid(self,"BlackNose",Vector3(0,1.59,-1.17),Vector3(.17,.12,.09),"241f1b")
	for side in [-1,1]:
		ellipsoid(self,"Eye",Vector3(side*.118,1.73,-.84),Vector3(.028,.035,.055),"11130e")
		var ear := ellipsoid(self,"LongEar",Vector3(side*.22,1.89,-.62),Vector3(.15,.38,.09),"856748")
		ear.rotation.z=-side*.68
		var inner := ellipsoid(self,"EarInterior",Vector3(side*.224,1.895,-.668),Vector3(.085,.27,.018),"bba17d")
		inner.rotation.z=-side*.68
		var points := [Vector3(side*.07,1.84,-.68),Vector3(side*.16,2.09,-.54),Vector3(side*.33,2.29,-.4),Vector3(side*.46,2.48,-.29)]
		for i in range(3):
			bone(self,"AntlerBeam",points[i],points[i+1],.036-i*.008,"c0ac85",.65)
			bone(self,"AntlerTine",points[i+1],points[i+1]+Vector3(side*.03,.23,-.2),.022-i*.005,"c0ac85",.05)
		for back in [false,true]:
			var pivot := Node3D.new()
			pivot.name="HindLeg" if back else "ForeLeg"
			add_child(pivot)
			pivot.position=Vector3(side*.17,1.0,.56 if back else -.42)
			legs.append(pivot)
			var knee := Vector3(0,-.4,.13 if back else -.045)
			var ankle := Vector3(0,-.83,-.02 if back else .015)
			bone(pivot,"UpperLeg",Vector3.ZERO,knee,.075,"735238",.65)
			bone(pivot,"SlenderShin",knee,ankle,.032,"9d815c",.65)
			ellipsoid(pivot,"Hock",knee,Vector3(.09,.11,.09),"6d513a")
			bone(pivot,"Pastern",ankle,Vector3(0,-.94,-.055),.025,"8d7150")
			for toe in [-1,1]:ellipsoid(pivot,"ClovenHoof",Vector3(toe*.025,-.96,-.07),Vector3(.043,.08,.13),"29251e")
	var tail := ellipsoid(self,"WhiteTail",Vector3(0,1.1,.86),Vector3(.12,.3,.15),"c7b48c")
	tail.rotation.x=-.75
func gait(time: float, walking: bool) -> void:
	for i in range(legs.size()):
		legs[i].rotation.x=sin(time*10+(PI if i in [0,3] else 0))*.5 if walking else [.4,-.65,-.22,.7][i]
