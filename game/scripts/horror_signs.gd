extends Node3D
const Route=preload("res://scripts/route.gd")
const ROAD_MARKERS := [-190.0,-350.0,-475.0]
const WORDS := ["WAVING CHILDREN\nPLEASE WAVE BACK","IF YOU CAN READ THIS\nYOU'RE IN RANGE\nOF THE ANOMALY","YOU'VE BEEN HERE BEFORE\nWE MADE SURE YOU FORGOT"]
var game
var drops: Array[Dictionary]=[]
var age := 0.0
var boards: Array[Node3D]=[]

func setup(g) -> void:
	game=g
	name="RoadsideWarnings"
	for i in range(ROAD_MARKERS.size()):
		var side: int=-1 if i%2==0 else 1
		var dimensions: Vector2=[Vector2(3.1,1.8),Vector2(3.6,2.3),Vector2(5.0,1.65)][i]
		var board := add_board(self,Route.point(side*7.7,0,ROAD_MARKERS[i]),WORDS[i],dimensions.x,dimensions.y,atan2(-side*.85,.53),21+i)
		board.rotation.z=sin(float(i*7+side))*.045
	# An overhead message is visible through the windshield, leaving the road open.
	var gantry := Node3D.new()
	add_child(gantry)
	gantry.transform=Route.frame(-610)
	for x in [-6,4.5]:game.block(gantry,Vector3(x,3.5,0),Vector3(.18,7,.18),"535c54",true)
	game.block(gantry,Vector3(-.75,6.7,0),Vector3(10.7,.18,.18),"535c54")
	var overhead := add_board(gantry,Vector3(-.75,3.75,0),"WE DIDN'T THINK YOU'D\nMAKE IT THIS FAR",7.5,1.5,0,94,false)
	game.light(overhead,Vector3(0,3.1,.9),Color("b28950"),.7,7)

func add_board(parent: Node3D, at: Vector3, copy: String, width: float=3.7, height: float=1.65, yaw: float=0, id: int=0, posts: bool=true) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position=at
	root.rotation.y=yaw
	boards.append(root)
	if posts:
		for x in [-width*.36,width*.36]:game.block(root,Vector3(x,1.0,-.08),Vector3(.13,2.0,.14),"524332",true)
	var board: MeshInstance3D=game.block(root,Vector3(0,2,0),Vector3(width,height,.13),"4a2920")
	var face := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size=Vector2(width,height)
	face.mesh=plane
	var material := ShaderMaterial.new()
	material.shader=preload("res://assets/ui/bloody_sign.gdshader")
	material.set_shader_parameter("seed",float(id))
	var paints := ["804133","b38b37","263f35","57332d"]
	material.set_shader_parameter("paint",Color("70372b") if copy.begins_with("DON'T") else (Color("14201b") if id==94 else Color(paints[posmod(id,4)])))
	face.material_override=material
	root.add_child(face)
	face.position=Vector3(0,2,.071)
	var label: Label3D=game.text3(root,copy,Vector3(0,2,.083),54,Color("2b281b") if id==21 else Color("c6bfa2"))
	if id==94:label.modulate=Color("d99847")
	label.font=game.MENU_FONT
	label.outline_size=0
	var longest := 1
	for line in copy.split("\n"):longest=maxi(longest,line.length())
	label.pixel_size=minf(.009,width*.84/(longest*54*.45))
	# Painted damage crosses the lettering as well as the board.
	for i in range(14):
		var x := sin(float(i*17+id))*width*.46
		var y := 2+cos(float(i*31+id))*height*.42
		var scratch: MeshInstance3D=game.block(root,Vector3(x,y,.088),Vector3(.02+float(i%3)*.012,.08+float(i%4)*.06,.006),"44392b")
		scratch.rotation.z=.25
	for i in range(6):
		var x := (-.43+float(i)*.17)*width
		var streak_length := height*(.25+float((i+id)%4)*.19)
		game.block(root,Vector3(x,2+height*.5-streak_length*.5,.096),Vector3(.035+float(i%2)*.025,streak_length,.012),"911c13")
		var drop: MeshInstance3D=game.block(root,Vector3(x,2-height*.5,.09),Vector3(.045,.14,.035),"a12819")
		drops.append({"node":drop,"x":x,"bottom":2-height*.5,"phase":float(i)*.47+float(id)*.13})
	game.light(root,Vector3(0,2,1.2),Color("b7ab8b"),1.1,4.8)
	return root

func update(delta: float) -> void:
	age+=delta
	for drop in drops:
		var t := fmod(age*.48+drop.phase,1.0)
		drop.node.position=Vector3(drop.x,drop.bottom-t*t*.9,.09)
		drop.node.scale.y=.5+t*.8
		drop.node.visible=t<.9
