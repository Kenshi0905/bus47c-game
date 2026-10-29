extends RefCounted
const Route = preload("res://scripts/route.gd")
const Story = preload("res://scripts/story.gd")
var state := "hidden"
var age := 0.0
var cooldown := 2.0
var appearances := 0
var zoom_dwell := 0.0
var starting_yaw := 0.0
var departure = preload("res://scripts/watcher_departure.gd").new()
var tree_positions: Array[Vector3]=[]
var zip_origin := Vector3.ZERO
var tree_target := Vector3.ZERO
var hiding_point := Vector3.ZERO
var peek_side := Vector3.ZERO
var retreat_origin := Vector3.ZERO
var retreat_lean := 0.0
const ZIP_SECONDS := .62
const PEEK_SECONDS := 2.8
const RETREAT_SECONDS := .45

func reset(figure: Node3D) -> void:
	departure.clear()
	state="hidden"
	age=0
	cooldown=2
	appearances=0
	zoom_dwell=0
	figure.rotation.z=0
	figure.hide()

func appear(figure: Node3D, at: Vector3, yaw: float) -> void:
	figure.global_position=at
	figure.rotation.y=yaw
	figure.show()
	state="visible"
	age=0
	zoom_dwell=0
	appearances+=1

func vanish(figure: Node3D) -> void:
	departure.begin(figure)
	state="dissolving"
	age=0
	zoom_dwell=0

func find_tree(figure: Node3D, camera: Camera3D) -> Vector3:
	if tree_positions.is_empty():
		var forest: Node3D=figure.get_parent().forest
		# CPU-side placement data also works with the headless renderer.
		for point in forest.trunk_positions:tree_positions.append(forest.to_global(point))
	var bus: Node3D=figure.get_parent().bus
	var side := signf(figure.global_position.x-Route.center_x(figure.global_position.z))
	# Prefer a nearby trunk. The wider pass finds a clear tree farther into the
	# same woodland when the closest trunks sit behind a window pillar.
	for reach in [17.0,27.0]:
		var best := Vector3.INF
		var best_score := INF
		for tree in tree_positions:
			var distance := figure.global_position.distance_to(tree)
			if distance<3.5 or distance>reach:continue
			if side*(tree.x-Route.center_x(tree.z))<7.5:continue
			if not camera.is_position_in_frustum(tree+Vector3(0,1.8,0)):continue
			if not dash_path_clear(figure.global_position,camera,bus,tree):continue
			var score := absf(distance-8)+tree.distance_to(camera.global_position)*.035
			if score<best_score:
				best_score=score
				best=tree
		if best!=Vector3.INF:return best
	return Vector3.INF

func dash_path_clear(origin: Vector3, camera: Camera3D, bus: Node3D, tree: Vector3) -> bool:
	var away := tree-camera.global_position
	away.y=0
	var destination := tree+away.normalized()*.34
	for t in [0.0,.25,.5,.75,1.0]:
		var point := origin.lerp(destination,t)
		# Check both the red tie and the head. A visible end point alone can
		# otherwise send the entire middle of the dash behind a bus pillar.
		if not window_clear(camera,bus,point+Vector3(0,1.4,0)):return false
		if not window_clear(camera,bus,point+Vector3(0,1.95,0)):return false
	return true

func begin_zip(figure: Node3D, camera: Camera3D) -> void:
	tree_target=find_tree(figure,camera)
	if tree_target==Vector3.INF:
		# A steep view can hide every trunk. Keep him present until one is visible.
		return
	zip_origin=figure.global_position
	var away := tree_target-camera.global_position
	away.y=0
	away=away.normalized()
	hiding_point=tree_target+away*.34
	peek_side=away.cross(Vector3.UP).normalized()*.2
	if (hiding_point+peek_side).distance_to(zip_origin)>(hiding_point-peek_side).distance_to(zip_origin):peek_side=-peek_side
	departure.begin_trail(figure)
	state="zipping"
	age=0

func update_tree_encounter(delta: float, figure: Node3D, camera: Camera3D) -> bool:
	if state not in ["zipping","peeking","retreating"]:return false
	age+=delta
	if state=="zipping":
		var t := clampf(age/ZIP_SECONDS,0,1)
		figure.global_position=zip_origin.lerp(hiding_point,t*t*(3-2*t))
		figure.global_position.y+=sin(t*PI)*.08
		# The impossible glide keeps his face and red tie readable throughout the dash.
		var toward := camera.global_position-figure.global_position
		figure.rotation.y=atan2(-toward.x,-toward.z)
		departure.update_trail(delta,zip_origin,figure,camera)
		if age>=ZIP_SECONDS:
			state="peeking"
			age=0
	elif state=="peeking":
		var reveal := smoothstep(.15,.8,age)
		figure.global_position=hiding_point+peek_side*reveal
		var toward := camera.global_position-figure.global_position
		figure.rotation.y=atan2(-toward.x,-toward.z)
		var lean_sign := -signf(peek_side.dot(figure.global_basis.x))
		figure.rotation.z=lean_sign*.13*reveal
		departure.update_trail(delta,zip_origin,figure,camera,true)
		if age>=PEEK_SECONDS:
			retreat_origin=figure.global_position
			retreat_lean=figure.rotation.z
			state="retreating"
			age=0
	else:
		figure.global_position=retreat_origin.lerp(hiding_point,smoothstep(0,RETREAT_SECONDS,age))
		figure.rotation.z=lerpf(retreat_lean,0,clampf(age/RETREAT_SECONDS,0,1))
		if age>=RETREAT_SECONDS:vanish(figure)
	return true

func update(delta: float, figure: Node3D, camera: Camera3D, bus: Node3D, stage: int, zoom: bool) -> void:
	if update_tree_encounter(delta,figure,camera):return
	if state=="dissolving":
		if departure.update(delta,figure,camera):
			state="hidden"
			cooldown=7.0
		return
	if stage not in [Story.Stage.PASSENGER,Story.Stage.NEXT_RIDE,Story.Stage.SECOND_STOP,Story.Stage.THIRD_RIDE,Story.Stage.THIRD_STOP,Story.Stage.FOURTH_RIDE,Story.Stage.FOURTH_STOP,Story.Stage.FINAL_RIDE,Story.Stage.DEER]:return
	if state=="hidden":
		cooldown-=delta
		if cooldown>0:return
		var at := candidate(camera,bus,stage)
		if at!=Vector3.INF:
			var facing := camera.global_position-at
			appear(figure,at,atan2(-facing.x,-facing.z)+1.25)
		return
	age+=delta
	var facing := camera.global_position-figure.global_position
	if state=="turning":
		var destination_yaw := atan2(-facing.x,-facing.z)
		figure.rotation.y=lerp_angle(starting_yaw,destination_yaw,smoothstep(0,1.9,age))
		if age>=3.0:begin_zip(figure,camera)
		return
	var center := figure.global_position+Vector3(0,1.4,0)
	var aim := (-camera.global_basis.z).dot((center-camera.global_position).normalized())
	# Ordinary looking never dismisses him. A deliberate, settled zoom does.
	if zoom and camera.fov<58 and aim>.97 and window_clear(camera,bus,center):
		zoom_dwell+=delta
		if zoom_dwell>=.55:
			state="turning"
			starting_yaw=figure.rotation.y
			age=0
	else:zoom_dwell=0
	# Re-stage a missed encounter only once it is well behind and fully unseen.
	if facing.length()>43 and not camera.is_position_in_frustum(center) and not camera.is_position_in_frustum(center+Vector3.UP):
		var at := candidate(camera,bus,stage)
		if at!=Vector3.INF:
			figure.global_position=at
			var facing_at := camera.global_position-at
			figure.rotation.y=atan2(-facing_at.x,-facing_at.z)+1.25
			zoom_dwell=0

func candidate(camera: Camera3D, bus: Node3D, _stage: int) -> Vector3:
	var forward := -camera.global_basis.z
	var local_view := bus.global_basis.inverse()*forward
	if absf(forward.y)>.5 or (local_view.z>.65 and absf(local_view.x)<.65):return Vector3.INF
	var best := Vector3.INF
	var score := -INF
	for offset in range(-32,25,4):
		var z := bus.position.z+offset
		if z> -120 or z< -675:continue
		for side in [-1,1]:
			if absf(local_view.x)>.25 and signf(local_view.x)!=side:continue
			var point := Route.point(side*8.8,0,z)
			var diff := point+Vector3(0,1.4,0)-camera.global_position
			if diff.length()<9 or diff.length()>32:continue
			var aim := forward.dot(diff.normalized())
			if aim<.8 or not camera.is_position_in_frustum(point+Vector3(0,1.4,0)):continue
			if not window_clear(camera,bus,point+Vector3(0,1.4,0)):continue
			var current := -absf(aim-.965)-absf(diff.length()-17)*.004
			if current>score:
				score=current
				best=point
	return best

func window_clear(camera: Camera3D, bus: Node3D, point: Vector3) -> bool:
	var from := bus.to_local(camera.global_position)
	if absf(from.x)>1.35 or absf(from.z)>4.55:return true
	var direction := bus.to_local(point)-from
	var side_t := INF
	var front_t := INF
	if absf(direction.x)>.001:side_t=(signf(direction.x)*1.35-from.x)/direction.x
	if absf(direction.z)>.001:front_t=(signf(direction.z)*4.55-from.z)/direction.z
	var hit := from+direction*minf(side_t,front_t)
	if hit.y<1.78 or hit.y>2.88:return false
	if front_t<side_t:return direction.z<0 and absf(hit.x)>.09 and absf(hit.x)<1.25
	for z in [-4.55,-3.8,-2.2,-.7,.8,2.3,3.8,4.55]:
		if absf(hit.z-z)<.13:return false
	return true
