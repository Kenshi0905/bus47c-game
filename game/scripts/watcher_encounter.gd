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

func reset(figure: Node3D) -> void:
	departure.clear()
	state="hidden"
	age=0
	cooldown=2
	appearances=0
	zoom_dwell=0
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

func update(delta: float, figure: Node3D, camera: Camera3D, bus: Node3D, stage: int, zoom: bool) -> void:
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
		if age>=3.0:vanish(figure)
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
