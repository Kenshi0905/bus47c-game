extends Node3D
const Route=preload("res://scripts/route.gd")
const NAMES=["fan belt","ignition coil","fuse block","fuel coupling","starter relay"]
var game
var after
var taken: Array[int]=[]
var items: Array[Node3D]=[]
var repaired := false

func setup(g,a) -> void:
	game=g
	after=a
	name="ScatteredMachineParts"
	for i in range(Route.REPAIR_SITES.size()):
		var root := Node3D.new()
		add_child(root)
		root.name=NAMES[i].to_pascal_case()
		root.position=Route.REPAIR_SITES[i]+Vector3(0,.15,0)
		root.rotation.y=float(i)*.8
		items.append(root)
		var mesh := MeshInstance3D.new()
		if i==0 or i==3:
			var ring := TorusMesh.new()
			ring.inner_radius=.17 if i==0 else .08
			ring.outer_radius=.22 if i==0 else .15
			ring.rings=12
			ring.ring_segments=6
			mesh.mesh=ring
		else:
			var part := BoxMesh.new()
			part.size=Vector3(.3,.19,.23)
			mesh.mesh=part
		mesh.material_override=game.mat("9b916e")
		root.add_child(mesh)
		for j in range(3):game.block(root,Vector3(-.1+j*.1,.12,.1),Vector3(.04,.045,.14),"b6b197")
		game.block(root,Vector3(0,.14,.0),Vector3(.12,.025,.07),"b39858",false,true)
		game.light(root,Vector3(0,.45,0),Color("b4a670"),.5,2.4)
		after.hotspot("part"+str(i),root,Vector3(0,.15,0),"Take the "+NAMES[i],2.7)
	game.block(game.bus,Vector3(.55,1.13,-4.78),Vector3(.8,.55,.035),"393e36")
	for y in [.98,1.09,1.2]:game.block(game.bus,Vector3(.55,y,-4.81),Vector3(.65,.025,.025),"6b705e")
	after.hotspot("repair_engine",game.bus,Vector3(.55,1.15,-4.9),"Fit the engine parts",2.8)

func reset() -> void:
	taken.clear()
	repaired=false
	for item in items:item.show()

func available() -> Array:
	var result: Array=[]
	if repaired:return result
	for i in range(items.size()):
		if i not in taken:result.append("part"+str(i))
	if taken.size()==5:result.append("repair_engine")
	return result

func collect(id: String) -> bool:
	var i := int(id.trim_prefix("part"))
	if i<0 or i>=items.size() or i in taken:return false
	taken.append(i)
	items[i].hide()
	return true

func restore(data: Dictionary) -> void:
	reset()
	var saved: Variant=data.get("parts",[])
	if saved is Array:
		for value in saved:
			if (value is float or value is int) and int(value)>=0 and int(value)<5 and int(value) not in taken:
				taken.append(int(value))
				items[int(value)].hide()
	repaired=data.get("repaired",false)==true and taken.size()==5

func objective() -> String:
	if repaired:return "The engine is ready. Board the bus or take the footpath."
	if taken.size()==5:return "Fit the five parts at the front of the bus, or take the footpath."
	return "Find engine parts   %d of 5\nOr take the footpath to Loomesville." % taken.size()
