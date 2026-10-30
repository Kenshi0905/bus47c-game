extends Node3D
## The complete preparation is visible on the table, with a hollow cup and kettle.
var game
var kettle: Node3D
var spoon: Node3D
var grounds: MeshInstance3D
var liquid: MeshInstance3D
var stream: MeshInstance3D
var steam: Array[MeshInstance3D]=[]
var kettle_hand: Node3D
var spoon_hand: Node3D
var kettle_home := Vector3(-.35,.0,-.15)
var poured := false
func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius*.92
	mesh.height=height
	mesh.radial_segments=12
	node.mesh=mesh
	node.material_override=game.mat(color)
	parent.add_child(node)
	node.position=at
	return node
func setup(g,home: Node3D) -> void:
	game=g
	name="CoffeeUtensils"
	home.add_child(self)
	position=Vector3(2.9,1.035,3)
	# Cup walls leave a visible opening, unlike a closed cylinder primitive.
	for i in range(16):
		var angle := i*TAU/16
		var wall: MeshInstance3D=game.block(self,Vector3(cos(angle)*.09,.115,sin(angle)*.09),Vector3(.038,.23,.016),"aaa99a")
		wall.rotation.y=-angle+PI/2
	cylinder(self,Vector3(0,.012,0),.09,.022,"aaa99a")
	var handle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius=.042
	ring.outer_radius=.063
	ring.rings=12
	ring.ring_segments=6
	handle.mesh=ring
	handle.material_override=game.mat("aaa99a")
	add_child(handle)
	handle.position=Vector3(.125,.12,0)
	handle.rotation.x=PI/2
	liquid=cylinder(self,Vector3(0,.026,0),.08,.009,"392719")
	grounds=cylinder(self,Vector3(0,.035,0),.06,.014,"31231b")
	var jar := cylinder(self,Vector3(-.58,.14,.1),.11,.28,"695137")
	jar.name="CoffeeTin"
	cylinder(self,Vector3(-.58,.288,.1),.115,.025,"928977")
	game.text3(self,"COFFEE",Vector3(-.58,.15,.207),18,Color("d1bd95")).pixel_size=.0019
	kettle=Node3D.new()
	add_child(kettle)
	kettle.name="EnamelKettle"
	cylinder(kettle,Vector3(0,.17,0),.17,.3,"818b83")
	cylinder(kettle,Vector3(0,.33,0),.16,.035,"aaa99a")
	cylinder(kettle,Vector3(0,.366,0),.035,.045,"252c28")
	var spout := cylinder(kettle,Vector3(.21,.23,0),.034,.2,"a1a596")
	spout.rotation.z=-.92
	for x in [-.13,.13]:game.block(kettle,Vector3(x,.45,0),Vector3(.035,.25,.035),"303632")
	game.block(kettle,Vector3(0,.575,0),Vector3(.3,.035,.035),"303632")
	var hotplate := cylinder(self,Vector3(-.35,.025,-.15),.215,.04,"303632")
	hotplate.name="Hotplate"
	spoon=Node3D.new()
	add_child(spoon)
	spoon.name="Teaspoon"
	game.block(spoon,Vector3(0,.11,0),Vector3(.015,.22,.013),"b6b7a6")
	var bowl := cylinder(spoon,Vector3(0,-.015,0),.03,.012,"b6b7a6")
	bowl.scale.z=1.5
	stream=cylinder(self,Vector3(.03,.36,0),.008,.32,"a38e62")
	stream.hide()
	for i in range(5):
		var puff := cylinder(self,Vector3.ZERO,.016,.055,"bcbca2")
		var m: StandardMaterial3D=game.mat("a5aba0")
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a=.14
		puff.material_override=m
		steam.append(puff)
	kettle_hand=hand(kettle,Vector3(0,.58,.04))
	spoon_hand=hand(spoon,Vector3(0,.17,0))
	reset()
func hand(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position=at
	game.block(root,Vector3(.015,0,.035),Vector3(.095,.055,.12),"b7a68a")
	for i in range(4):game.block(root,Vector3(-.03+i*.022,-.025,-.023),Vector3(.018,.065,.045),"ae997d")
	game.block(root,Vector3(.075,-.03,.15),Vector3(.11,.09,.24),"75898b").rotation.y=.35
	return root
func reset() -> void:
	poured=false
	kettle.position=kettle_home
	kettle.rotation=Vector3.ZERO
	spoon.position=Vector3(.27,.03,.18)
	spoon.rotation=Vector3(PI/2,0,.2)
	liquid.position.y=.026
	grounds.hide()
	stream.hide()
	for puff in steam:puff.hide()
	kettle_hand.hide()
	spoon_hand.hide()
func update(t: float) -> void:
	if t>=6.5 and not poured:
		poured=true
		game.play_sound("pour")
	kettle_hand.visible=t>5 and t<10
	spoon_hand.visible=t<2.5 or (t>9.5 and t<11.6)
	var scoop := smoothstep(0,1.0,t)
	spoon.position=Vector3(-.58,.35,.1).lerp(Vector3(0,.36,0),scoop)
	spoon.rotation=Vector3(0,0,-.7*smoothstep(1,2,t))
	grounds.visible=t>1.5
	if t>2.5:
		spoon.position=Vector3(.27,.03,.18)
		spoon.rotation=Vector3(PI/2,0,.2)
	var lift := smoothstep(5,6,t)
	var pour := smoothstep(6,7,t)*(1-smoothstep(8,9,t))
	kettle.position=kettle_home.lerp(Vector3(-.4,.43,0),lift)*(1-smoothstep(9,10,t))+kettle_home*smoothstep(9,10,t)
	kettle.rotation.z=-.55*pour
	stream.visible=t>6.5 and t<8.8
	liquid.position.y=lerpf(.026,.19,smoothstep(6.5,8.8,t))
	# Anchor the stream to the animated spout rather than the kettle's base.
	var tip: Vector3=kettle.transform*Vector3(.29,.291,0)
	var cup_surface := Vector3(0,liquid.position.y,0)
	stream.position=(tip+cup_surface)*.5
	stream.mesh.height=tip.distance_to(cup_surface)
	stream.quaternion=Quaternion(Vector3.UP,(tip-cup_surface).normalized())
	if t>9.5:
		spoon.position=Vector3(cos(t*9)*.035,.27,sin(t*9)*.035)
		spoon.rotation=Vector3(.15,0,.12)
	if t>=11.6:
		spoon.position=Vector3(.27,.03,.18)
		spoon.rotation=Vector3(PI/2,0,.2)
	for i in range(steam.size()):
		var puff: MeshInstance3D=steam[i]
		puff.visible=t>3
		puff.position=Vector3(sin(t*2+i)*.035,.23+fmod(t*.15+i*.07,.3),0)+(Vector3(-.35,.13,-.15) if t<6.5 else Vector3.ZERO)
