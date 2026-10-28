extends Node3D
## Off-camera arrivals, real aisle movement, and unseen standing/seated swaps.
const MODELS := ["01_grinning_clerk", "03_long_neck_worker", "04_crooked_passenger"]
var seats: Array[Vector3] = []
var owners: Array[int] = [] # -1 empty, -2 player, otherwise actor index.
var actors: Array[Dictionary] = []
var requested := 0
var age := 0.0

func configure(positions: Array[Vector3]) -> void:
	seats = positions
	for point in seats: owners.append(-1)
	for i in range(MODELS.size()):
		var actor := Node3D.new()
		actor.name = "Passenger" + str(i + 1)
		add_child(actor)
		var standing: Node3D = load("res://assets/characters/" + MODELS[i] + ".gltf").instantiate()
		var seated: Node3D = load("res://assets/characters/" + MODELS[i] + "_seated.gltf").instantiate()
		actor.add_child(standing)
		actor.add_child(seated)
		seated.hide()
		actor.hide()
		var limbs := rig_limbs(standing)
		actors.append({"node":actor, "standing":standing, "seated":seated, "limbs":limbs,
			"state":"pending", "seat":-1, "path":[], "stride":0.0})

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

func reset(restored: int = 0) -> void:
	requested = restored
	age = 0
	owners.fill(-1)
	for i in range(actors.size()):
		var actor: Dictionary = actors[i]
		actor.state = "pending"
		actor.seat = -1
		actor.path = []
		actor.node.hide()
		actor.standing.show()
		actor.seated.hide()
		if i < restored:
			assign_seat(i)
			settle(i)

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
		var actor: Dictionary = actors[i]
		if actor.seat < 0: assign_seat(i)
		if actor.seat < 0: continue
		var target: Vector3 = seats[actor.seat]
		var node: Node3D = actor.node
		if actor.state == "pending":
			if not doors_open or age < i * 1.4: continue
			if i>0 and actors[i-1].state!="seated":continue
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
	for i in range(requested):
		var actor: Dictionary = actors[i]
		if actor.state == "pending" or actor.node.position.x > 1.1 or actor.node.position.y < .7: return false
	return true

func first_visible() -> bool:
	return actors[0].node.visible

func first_actor() -> Node3D:
	return actors[0].node
