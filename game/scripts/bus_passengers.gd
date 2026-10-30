extends Node3D
## Off-camera arrivals, real aisle movement, and unseen standing/seated swaps.
const MODELS := ["01_grinning_clerk", "03_long_neck_worker", "04_crooked_passenger", "01_grinning_clerk", "03_long_neck_worker"]
const Route=preload("res://scripts/route.gd")
const Story=preload("res://scripts/story.gd")
var view_checks=preload("res://scripts/watcher_encounter.gd").new()
var game
var outside: Node3D
var schedule: Array[int]=[]
var current_stop := 0
var seats: Array[Vector3] = []
var owners: Array[int] = [] # -1 empty, -2 player, otherwise actor index.
var actors: Array[Dictionary] = []
var requested := 0
var age := 0.0

func configure(positions: Array[Vector3]) -> void:
	seats = positions
	game=get_parent().get_parent()
	outside=Node3D.new()
	outside.name="DepartedPassengers"
	game.add_child(outside)
	for point in seats: owners.append(-1)
	for i in range(MODELS.size()):
		var actor := Node3D.new()
		actor.name = "Passenger" + str(i + 1)
		add_child(actor)
		var standing: Node3D = load("res://assets/characters/" + MODELS[i] + ".gltf").instantiate()
		var seated: Node3D = load("res://assets/characters/" + MODELS[i] + "_seated.gltf").instantiate()
		actor.add_child(standing)
		actor.add_child(seated)
		if i>=3:
			standing.scale=Vector3(.88,1.07,.9)
			seated.scale=Vector3(.88,1.07,.9)
		seated.hide()
		actor.hide()
		var limbs := rig_limbs(standing)
		actors.append({"node":actor, "standing":standing, "seated":seated, "limbs":limbs,
			"state":"pending", "seat":-1, "path":[], "stride":0.0, "time":0.0, "features":[], "corpse":null, "exit_stop":0,
			"corpse_staged":false, "corpse_reveal":0.0, "corpse_materials":[]})

func rig_limbs(model: Node3D) -> Array[Node3D]:
	var pivots: Array[Node3D] = []
	for side in [-1, 1]:
		var leg := Node3D.new()
		model.add_child(leg)
		leg.position = Vector3(side * .12, .96, 0)
		var arm := Node3D.new()
		model.add_child(arm)
		arm.position = Vector3(side * .22, 1.46, 0)
		# Mesh vertices in the source are in character-local coordinates.
		for mesh in model.get_children():
			if not mesh is MeshInstance3D: continue
			var center: Vector3 = mesh.get_aabb().get_center()
			if (center.x < 0) != (side < 0): continue
			var part := String(mesh.name)
			var pivot: Node3D = null
			if "trouser" in part or "shoe" in part: pivot = leg
			elif "sleeve" in part or "hand" in part or "thumb" in part or "cuff" in part: pivot = arm
			if pivot != null:
				mesh.reparent(pivot, false)
				mesh.position = -pivot.position
		pivots.append(leg)
		pivots.append(arm)
	return pivots

func reset(restored: int = 0, seed_value: int = 4707, stop: int = 0) -> void:
	requested=restored
	current_stop=stop
	age=0
	owners.fill(-1)
	var rng := RandomNumberGenerator.new()
	rng.seed=seed_value
	schedule.assign([rng.randi_range(2,3),rng.randi_range(3,4),rng.randi_range(3,4),4,4])
	# Spread the two Quarry arrivals across separate later stops.
	schedule[2]=7-schedule[1]
	for i in range(actors.size()):
		var actor: Dictionary=actors[i]
		if actor.node.get_parent()!=self:actor.node.reparent(self,false)
		if is_instance_valid(actor.corpse):actor.corpse.free()
		actor.corpse=null
		actor.corpse_staged=false
		actor.corpse_reveal=0.0
		actor.corpse_materials=[]
		actor.state="pending"
		actor.seat=-1
		actor.path=[]
		actor.time=0.0
		actor.exit_stop=schedule[i]
		actor.node.rotation=Vector3.ZERO
		actor.node.hide()
		actor.standing.show()
		actor.seated.hide()
		preload("res://scripts/face_loss.gd").restore(actor.standing)
		for part in actor.standing.find_children("*","MeshInstance3D",true,false):
			part.show()
			part.scale=Vector3.ONE
		for limb in actor.limbs:limb.rotation=Vector3.ZERO
		if i<restored:
			if schedule[i]<stop:
				actor.node.reparent(outside,false)
				actor.node.position=shelter_point(i)
				actor.node.show()
				make_faceless(i)
				# An earlier leg stays behind on checkpoint reload, never jumps ahead again.
				actor.corpse_staged=true
				actor.corpse_reveal=1.2
				actor.corpse.show()
			else:
				assign_seat(i)
				settle(i)

func begin_stop(index: int) -> void:
	current_stop=index

func shelter_point(index: int) -> Vector3:
	return Route.point(5.0+float(index%2)*.7,.11,Story.STOP_Z[schedule[index]]-3.0+float(index%3-1)*.7)

func facial(part: String) -> bool:
	for word in ["eye","pupil","brow","nose","mouth","grin","tear"]:
		if word in part:return true
	return false

func make_faceless(index: int) -> void:
	var actor: Dictionary=actors[index]
	for part in actor.standing.find_children("*","MeshInstance3D",true,false):
		if facial(String(part.name).to_lower()):part.hide()
	actor.state="faceless"
	if actor.corpse==null:build_corpse(index)

func build_corpse(index: int) -> void:
	var actor: Dictionary=actors[index]
	var root := Node3D.new()
	root.name="RoadsideBody"+str(index+1)
	outside.add_child(root)
	var z: float=Story.STOP_Z[schedule[index]]-52-float(index)*6
	root.position=Route.point(-8.9 if index%2==0 else 9.1,.0,z)
	var body: Node3D=load("res://assets/characters/"+MODELS[index]+".gltf").instantiate()
	root.add_child(body)
	body.position=Vector3(0,.17,.9)
	body.rotation=Vector3(-PI/2,.35 if index%2==0 else -.6,0)
	if index>=3:body.scale=Vector3(.88,1.07,.9)
	for part in body.find_children("*","MeshInstance3D",true,false):
		var key := String(part.name).to_lower()
		if facial(key) or "head" in key or "neck" in key or "ear" in key or "hair" in key or "cap" in key:part.hide()
	var pool := MeshInstance3D.new()
	pool.name="BloodPool"
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(24):
		var a := TAU*float(j)/24
		var b := TAU*float(j+1)/24
		for v in [Vector3(0,.018,-.5),Vector3(cos(b)*(1.05+.12*sin(b*5)),.018,-.5+sin(b)*1.7),Vector3(cos(a)*(1.05+.12*sin(a*5)),.018,-.5+sin(a)*1.7)]:
			mesh.set_normal(Vector3.UP)
			mesh.add_vertex(v)
	pool.mesh=mesh.commit()
	var blood: StandardMaterial3D=preload("res://scripts/blood_palette.gd").material()
	blood.roughness=.25
	blood.cull_mode=BaseMaterial3D.CULL_DISABLED
	pool.material_override=blood
	root.add_child(pool)
	game.light(root,Vector3(0,1.8,0),Color("b39b87"),1.0,5)
	root.hide()
	actor.corpse=root

func corpse_candidate(index: int, camera: Camera3D) -> Vector3:
	var forward := -camera.global_basis.z
	var local_view: Vector3=game.bus.global_basis.inverse()*forward
	if absf(forward.y)>.65 or (local_view.z>.6 and absf(local_view.x)<.6):return Vector3.INF
	var last_z: float=Story.STOP_Z[schedule[index]+1]+10 if schedule[index]<5 else -INF
	var best := Vector3.INF
	var score := -INF
	for offset in [-34,-28,-22,-16,-10]:
		var z: float=game.bus.position.z+offset
		if z<last_z or z>Story.STOP_Z[schedule[index]]-25:continue
		for side in [-1,1]:
			if absf(local_view.x)>.2 and signf(local_view.x)!=side:continue
			var point := Route.point(side*9.2,0,z)
			var occupied := false
			for other in actors:
				if other.corpse_staged and is_instance_valid(other.corpse) and other.corpse.position.distance_to(point)<6:occupied=true
			if occupied:continue
			var center := point+Vector3(0,.25,0)
			var diff := center-camera.global_position
			if diff.length()<13 or diff.length()>39:continue
			var aim := forward.dot(diff.normalized())
			if aim<.2 or not view_checks.window_clear(camera,game.bus,center):continue
			var on_screen := camera.is_position_in_frustum(center)
			# Place beyond the edge of the window where possible. A distant fog reveal
			# handles an already watched approach; nothing is repositioned afterward.
			if on_screen and diff.length()<25:continue
			var candidate_score := aim+(0.8 if not on_screen else 0.0)-absf(diff.length()-25)*.015
			if candidate_score>score:
				score=candidate_score
				best=point
	return best

func update_corpse(index: int, delta: float, camera: Camera3D) -> void:
	var actor: Dictionary=actors[index]
	if not actor.corpse_staged:
		var on_ride: bool=game.story.stage in Story.MOVING
		if not on_ride or game.bus.position.z>=Story.STOP_Z[schedule[index]]-12:return
		var candidate := corpse_candidate(index,camera)
		if candidate==Vector3.INF:return
		actor.corpse.position=candidate
		actor.corpse_staged=true
		actor.corpse_reveal=0.0
		for part in actor.corpse.find_children("*","MeshInstance3D",true,false):
			var material=part.get_active_material(0)
			if not material is StandardMaterial3D:continue
			actor.corpse_materials.append({"mesh":part,"original":part.material_override})
			var fade: StandardMaterial3D=material.duplicate()
			fade.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			fade.albedo_color.a=0.0
			part.material_override=fade
		actor.corpse.show()
	if actor.corpse_reveal<1.2:
		actor.corpse_reveal=minf(1.2,actor.corpse_reveal+delta)
		for entry in actor.corpse_materials:
			entry.mesh.material_override.albedo_color.a=smoothstep(0,1.2,actor.corpse_reveal)
		if actor.corpse_reveal>=1.2:
			for entry in actor.corpse_materials:entry.mesh.material_override=entry.original
			actor.corpse_materials=[]

func advance_exit(index: int, delta: float, camera: Camera3D) -> void:
	var actor: Dictionary=actors[index]
	var node: Node3D=actor.node
	actor.time+=delta
	if actor.state=="exit_rise":
		actor.standing.position.y=lerpf(-.3,0,minf(1,actor.time/.7))
		if actor.time>=.7:
			actor.state="exit_walk"
			actor.path=[Vector3(0,.78,node.position.z-.2),Vector3(0,.78,-2.05),Vector3(-.55,.78,-2.4),Vector3(-.55,.78,-3.55),Vector3(.72,.78,-3.35)]
	elif actor.state=="exit_stare":
		var direction: Vector3=node.to_local(camera.global_position)
		var target_yaw := node.rotation.y+atan2(-direction.x,-direction.z)
		node.rotation.y=lerp_angle(node.rotation.y,target_yaw,minf(1,delta*3))
		if actor.time>=3.4:
			actor.state="exit_door"
			actor.path=[Vector3(1.45,.78,-3.35),Vector3(3.6,.08,-3)]
	elif actor.state=="erasing":
		preload("res://scripts/face_loss.gd").update(actor.features,actor.time)
		if actor.time>=preload("res://scripts/face_loss.gd").DURATION:
			make_faceless(index)
	elif actor.state in ["exit_walk","exit_door","exit_shelter"]:
		if actor.path.is_empty():
			if actor.state=="exit_walk":actor.state="exit_stare"
			elif actor.state=="exit_door":
				node.reparent(outside,true)
				actor.state="exit_shelter"
				actor.path=[shelter_point(index)]
			else:
				actor.state="erasing"
				actor.features=preload("res://scripts/face_loss.gd").prepare(actor.standing)
				node.look_at(Vector3(game.bus.global_position.x,node.global_position.y,game.bus.global_position.z))
			actor.time=0
			for limb in actor.limbs:limb.rotation.x=0
			return
		var next: Vector3=actor.path[0]
		var diff := next-node.position
		node.position=node.position.move_toward(next,delta*.95)
		if diff.length()>.025:node.rotation.y=lerp_angle(node.rotation.y,atan2(-diff.x,-diff.z),minf(1,delta*6))
		actor.stride+=delta*5.2
		for limb in range(actor.limbs.size()):actor.limbs[limb].rotation.x=sin(actor.stride+(PI if limb>=2 else 0))*(.19 if limb%2==0 else -.13)
		if node.position.distance_to(next)<.025:actor.path.pop_front()

func exits_busy() -> bool:
	for actor in actors:
		if String(actor.state).begins_with("exit_") or actor.state=="erasing":return true
	return false

func request_count(count: int) -> void:
	requested = maxi(requested, mini(count, actors.size()))

func free_seat(exclude: int = -1) -> int:
	# Rear first, with alternating sides. Still works if the player takes one.
	for index in [4, 9, 8, 3, 2, 7, 1, 6, 0, 5]:
		if index != exclude and owners[index] == -1: return index
	return -1

func assign_seat(index: int) -> void:
	var seat := free_seat()
	actors[index].seat = seat
	if seat >= 0: owners[seat] = index

func can_sit(index: int) -> bool:
	if index < 0 or index >= seats.size(): return false
	var owner := owners[index]
	return owner == -1 or (owner >= 0 and actors[owner].state != "seated" and free_seat(index) >= 0)

func claim_player_seat(index: int) -> bool:
	if not can_sit(index): return false
	var owner := owners[index]
	if owner >= 0:
		var replacement := free_seat(index)
		owners[replacement] = owner
		actors[owner].seat = replacement
		if actors[owner].state != "pending":
			actors[owner].state = "walking"
			var at: Vector3 = actors[owner].node.position
			actors[owner].path = [Vector3(0,.78,at.z), Vector3(signf(seats[replacement].x)*.22,.78,seats[replacement].z-.18)]
	owners[index] = -2
	return true

func release_player_seat(index: int) -> void:
	if index >= 0 and owners[index] == -2: owners[index] = -1

func watched(camera: Camera3D, world_point: Vector3, radius: float = .5) -> bool:
	var viewport := camera.get_viewport().get_visible_rect().size
	var vertical := tan(deg_to_rad(camera.fov) * .5)
	var horizontal := vertical * viewport.x / maxf(viewport.y, 1)
	# Test the whole body against each frustum plane, including steep camera angles.
	var outside := [true,true,true,true,true]
	for x in [-radius,radius]:
		for y in [-1.15,1.15]:
			for z in [-radius,radius]:
				var local := camera.to_local(world_point+Vector3(x,y,z))
				var depth := -local.z
				outside[0]=outside[0] and depth<.02
				outside[1]=outside[1] and local.x < -depth*horizontal
				outside[2]=outside[2] and local.x > depth*horizontal
				outside[3]=outside[3] and local.y < -depth*vertical
				outside[4]=outside[4] and local.y > depth*vertical
	return not outside.has(true)

func actor_watched(index: int, camera: Camera3D) -> bool:
	return watched(camera, actors[index].node.global_position + Vector3(0,1.1,0))

func update(delta: float, camera: Camera3D, player_local: Vector3, doors_open: bool) -> void:
	age += delta
	for i in range(requested):
		var a: Dictionary=actors[i]
		if a.state=="faceless":
			update_corpse(i,delta,camera)
		elif String(a.state).begins_with("exit_") or a.state=="erasing":advance_exit(i,delta,camera)
		elif a.state=="seated" and schedule[i]==current_stop and doors_open and not exits_busy():
			owners[a.seat]=-1
			a.seat=-1
			a.state="exit_rise"
			a.time=0
			a.seated.hide()
			a.standing.show()
	for i in range(requested):
		var actor: Dictionary = actors[i]
		if actor.state in ["faceless","erasing"] or String(actor.state).begins_with("exit_"):continue
		if actor.seat < 0: assign_seat(i)
		if actor.seat < 0: continue
		var target: Vector3 = seats[actor.seat]
		var node: Node3D = actor.node
		if actor.state == "pending":
			if not doors_open or exits_busy() or age < i * 1.4: continue
			if i>0 and actors[i-1].state not in ["seated","faceless"]:continue
			# If the doorway is watched, an unseen rear aisle arrival is possible.
			for origin in [Vector3(3.15,.06,-3), Vector3(0,.78,3.85)]:
				if origin.distance_to(player_local) < 1.3: continue
				if watched(camera, to_global(origin) + Vector3(0,1.1,0)): continue
				node.position = origin
				node.show()
				actor.state = "walking"
				actor.path = [Vector3(1.45,.78,-3), Vector3(0,.78,-3)] if origin.x > 2 else []
				actor.path.append(Vector3(signf(target.x)*.22,.78,target.z-.18))
				break
		elif actor.state == "walking":
			if actor.path.is_empty():
				actor.state = "waiting"
				continue
			var next: Vector3 = actor.path[0]
			var difference := next - node.position
			var proposed := node.position.move_toward(next, delta * .7)
			# Pause before walking into the player; the aisle is deliberately narrow.
			if Vector2(proposed.x-player_local.x, proposed.z-player_local.z).length() < .55: continue
			node.position = proposed
			if difference.length() > .025:
				node.rotation.y = lerp_angle(node.rotation.y, atan2(-difference.x,-difference.z), delta * 6)
			actor.stride += delta * 5.2
			for limb in range(actor.limbs.size()):
				actor.limbs[limb].rotation.x = sin(actor.stride + (PI if limb >= 2 else 0)) * (.19 if limb % 2 == 0 else -.13)
			if node.position.distance_to(next) < .025: actor.path.pop_front()
		elif actor.state == "waiting":
			if not actor_watched(i,camera) and not watched(camera,to_global(target)+Vector3(0,.95,0)):
				settle(i)

func settle(index: int) -> void:
	var actor: Dictionary = actors[index]
	actor.node.position = seats[actor.seat]
	actor.node.rotation = Vector3.ZERO
	actor.standing.hide()
	actor.seated.show()
	actor.node.show()
	actor.state = "seated"

func all_aboard() -> bool:
	if exits_busy():return false
	for i in range(requested):
		var actor: Dictionary = actors[i]
		if actor.state=="faceless":continue
		if schedule[i]<=current_stop:return false
		if actor.state == "pending" or actor.node.position.x > 1.1 or actor.node.position.y < .7: return false
	return true

func first_visible() -> bool:
	return actors[0].node.visible

func first_actor() -> Node3D:
	return actors[0].node
