extends CharacterBody3D
## A grounded, swept body follows the player's travelled path, never their gaze.
var game
var after
var trail: Array[Vector3]=[]
var last_player := Vector3.ZERO
var yaw := 0.0
var shape: CapsuleShape3D
var blocked_time := 0.0
var rope_length := 1.3

func setup(g,a) -> void:
	game=g
	after=a
	name="CorpsePhysics"
	collision_layer=0
	collision_mask=1
	shape=CapsuleShape3D.new()
	shape.radius=.29
	shape.height=1.82
	var collider := CollisionShape3D.new()
	collider.shape=shape
	collider.rotation.x=PI/2
	add_child(collider)
	add_collision_exception_with(game.player)
	reset()

func reset() -> void:
	trail.clear()
	blocked_time=0
	velocity=Vector3.ZERO
	yaw=0

func begin() -> void:
	reset()
	global_position=after.body_center()
	global_position.y=maxf(.35,global_position.y)
	yaw=after.opponent.rotation.y
	rotation.y=yaw
	last_player=game.player.global_position
	rope_length=maxf(1.3,Vector2(last_player.x-global_position.x,last_player.z-global_position.z).length())
	trail.append(last_player)
	after.lay_body(global_position,yaw)

func update_drag(delta: float) -> void:
	var at: Vector3=game.player.global_position
	if Vector2(at.x-last_player.x,at.z-last_player.z).length()>.12:
		trail.append(at)
		last_player=at
	# Keep 1.3 metres of rope. Looking around alone cannot move the corpse.
	var total := 0.0
	var previous := global_position
	for p in trail:
		total+=Vector2(p.x-previous.x,p.z-previous.z).length()
		previous=p
	if total<=rope_length+.005 or trail.is_empty():return
	var target: Vector3=trail[0]
	var direction := Vector3(target.x-global_position.x,0,target.z-global_position.z)
	if direction.length()<.16:
		trail.pop_front()
		return
	var wanted := atan2(direction.x,direction.z)
	var proposed := lerp_angle(yaw,wanted,1-exp(-delta*6))
	# Rotation also respects door frames. A capsule sweeps translation against
	# walls and furniture; a short ground probe prevents floating off a step.
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.transform=Transform3D(Basis(Vector3.UP,proposed)*Basis(Vector3.RIGHT,PI/2),global_position)
	query.collision_mask=1
	query.exclude=[get_rid(),game.player.get_rid()]
	if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():yaw=proposed
	else:
		# A long capsule can be blocked sideways at a narrow portal. Align to
		# the clear travel axis rather than pinning it against the door jamb.
		query.transform.basis=Basis(Vector3.UP,wanted)*Basis(Vector3.RIGHT,PI/2)
		if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():yaw=wanted
	rotation.y=yaw
	var origin := global_position
	var motion := direction.normalized()*minf(direction.length(),minf(total-rope_length,delta*2.7))
	for i in range(3):
		var hit := move_and_collide(motion)
		if not hit:break
		motion=hit.get_remainder().slide(hit.get_normal())
		if motion.length()<.001:break
	var ground_query := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.35,global_position-Vector3.UP*1.0,1,[get_rid(),game.player.get_rid()])
	var ground: Dictionary=get_world_3d().direct_space_state.intersect_ray(ground_query)
	if not ground.is_empty():global_position.y=move_toward(global_position.y,ground.position.y+.31,delta*2)
	after.lay_body(global_position,yaw)
	blocked_time=blocked_time+delta if global_position.distance_to(origin)<.002 else 0.0
	if global_position.distance_to(at)>3.2 or blocked_time>2.5:
		after.dragging=false
		game.player.movement_scale=1
		trail.clear()
		game.set_objective("The body caught on something. Move closer and pull from another angle.",true)
