extends CharacterBody3D
var camera: Camera3D
var enabled := false
var sensitivity := 0.0022
var step_time := 0.0
signal footstep

func _ready() -> void:
	var shape := CollisionShape3D.new()
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
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.35, 1.35)

func _physics_process(delta: float) -> void:
	if not enabled: return
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := transform.basis * Vector3(input.x, 0, input.y)
	var speed := 2.1 if not Input.is_action_pressed("sprint") else 3.6
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= 18.0 * delta
	else: velocity.y = -0.1
	move_and_slide()
	if input.length() > 0.1 and is_on_floor():
		step_time += delta
		if step_time > 0.5:
			step_time = 0.0
			footstep.emit()
