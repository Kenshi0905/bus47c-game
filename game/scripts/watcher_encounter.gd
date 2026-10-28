extends RefCounted
const Route = preload("res://scripts/route.gd")
var state := "hidden"
var age := 0.0
var cooldown := 1.2
var appearances := 0
var stage_seen := -1
var destination_yaw := 0.0

func reset(figure: Node3D) -> void:
	state="hidden"
	age=0
	cooldown=1.2
	appearances=0
	stage_seen=-1
	figure.hide()

func appear(figure: Node3D, at: Vector3, yaw: float) -> void:
	figure.global_position=at
	figure.rotation.y=yaw
	figure.show()
	state="visible"
	age=0
	appearances+=1

func vanish(figure: Node3D) -> void:
	figure.hide()
	state="hidden"
	cooldown=4.0
	age=0

func update(delta: float, figure: Node3D, camera: Camera3D, bus: Node3D, stage: int, zoom: bool) -> void:
	if stage_seen!=stage:
		stage_seen=stage
		reset_for_stage(figure)
	if stage not in [6,7,8,9,10]:return
	if state=="hidden":
		cooldown-=delta
		if cooldown>0 or appearances>=(3 if stage==7 else 1):return
		var at := candidate(camera,bus,stage)
		if at==Vector3.INF:return
		appear(figure,at,Route.heading(at.z)+(PI/2 if bus.to_local(at).x>0 else -PI/2))
		return
	age+=delta
	if state=="turning":
		figure.rotation.y=lerp_angle(figure.rotation.y,destination_yaw,minf(1,delta*12))
		if age>=.42:vanish(figure)
		return
	var diff := figure.global_position+Vector3(0,1.35,0)-camera.global_position
	var aim := (-camera.global_basis.z).dot(diff.normalized())
	# Zoom gets priority: the acknowledgement is brief, then the clearing is empty.
	if zoom and aim>.975:
		var facing := camera.global_position-figure.global_position
		destination_yaw=atan2(-facing.x,-facing.z)
		state="turning"
		age=0
	elif (age>.35 and aim>.997) or age>9:
		vanish(figure)

func reset_for_stage(figure: Node3D) -> void:
	figure.hide()
	state="hidden"
	age=0
	cooldown=1.2
	appearances=0

func candidate(camera: Camera3D, bus: Node3D, stage: int) -> Vector3:
	var forward := -camera.global_basis.z
	var local_view := bus.global_basis.inverse()*forward
	# The rear wall and floor are not windows.
	if absf(forward.y)>.45 or (local_view.z>.5 and absf(local_view.x)<.65):return Vector3.INF
	var points: Array[Vector3]=[]
	if stage==7:
		for z in range(-152,-270,-24):
			for side in [-1,1]:points.append(Route.point(side*9,0,z))
	else:
		points.append(Route.point(-22,0,-145) if stage==6 else (Route.point(17,0,-284) if stage==8 else Route.point(9,0,-399)))
	var best := Vector3.INF
	var best_score := -INF
	for point in points:
		var diff := point+Vector3(0,1.35,0)-camera.global_position
		if diff.length()<11 or diff.length()>52:continue
		var aim := forward.dot(diff.normalized())
		if aim<.79 or aim>.992:continue
		if not camera.is_position_in_frustum(point+Vector3(0,1.35,0)):continue
		# Favor a figure just beside the center of the view, visible through a window.
		var score := -absf(aim-.955)-diff.length()*.0005
		if score>best_score:
			best_score=score
			best=point
	return best
