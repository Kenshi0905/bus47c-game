extends CharacterBody3D
var camera: Camera3D
var enabled := false
var sensitivity := 0.0022
var step_distance := 0.0
var seated := false
var normal_fov := 76.0
var zooming := false
var movement_scale := 1.0
var collider: CollisionShape3D
signal footstep

func _ready() -> void:
	var shape := CollisionShape3D.new()
	collider = shape
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.57
	camera.fov = 76
	camera.near = 0.05
	add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		var zoom_scale := camera.fov/normal_fov
		rotate_y(-event.relative.x * sensitivity * zoom_scale)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity * zoom_scale, -1.35, 1.35)

func _physics_process(delta: float) -> void:
	if not enabled: return
	zooming=Input.is_action_pressed("zoom")
	camera.fov=lerpf(camera.fov,normal_fov*(.56 if zooming else 1.0),1-exp(-delta*12))
	camera.position.y = move_toward(camera.position.y, 1.28 if seated else 1.57, delta * 1.8)
	if seated:
		velocity = Vector3.ZERO
		return
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := global_transform.basis * Vector3(input.x, 0, input.y)
	var speed := 1.8 if not Input.is_action_pressed("sprint") else 2.8
	speed*=movement_scale
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= 18.0 * delta
	else: velocity.y = -0.1
	var before := position
	move_and_slide()
	var travelled := Vector2(position.x-before.x,position.z-before.z).length()
	if input.length() > 0.1 and is_on_floor() and travelled > .001:
		step_distance += travelled
		if step_distance > 1.15:
			step_distance = 0.0
			footstep.emit()
	elif input.length() < .1:
		step_distance = 0.0

func set_seated(value: bool, at: Vector3) -> void:
	seated = value
	position = at
	velocity = Vector3.ZERO
	step_distance = 0.0
	collider.set_deferred("disabled", value)

func reset_zoom() -> void:
	Input.action_release("zoom")
	zooming=false
	camera.fov=normal_fov
