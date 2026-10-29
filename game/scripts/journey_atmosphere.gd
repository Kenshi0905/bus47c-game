extends Node
## Slow changes in familiar light create anticipation between encounters.
## Only owns the bus journey; town, dawn and ending lighting keep their authority.
var game
var cabin: Array[Dictionary] = []
var baseline: Dictionary = {}
var age := 0.0
var engaged := false

func setup(g) -> void:
	game = g
	var env: Environment = game.world_environment
	baseline = {"ambient": env.ambient_light_energy, "fog": env.fog_density,
		"fog_color": env.fog_light_color, "moon": game.moon_light.light_energy}
	for child in game.bus.get_children():
		if child is OmniLight3D:
			cabin.append({"node": child, "energy": child.light_energy, "color": child.light_color})
	# Run after the main audio director so its established cues remain intact.
	process_priority = 10

func _process(delta: float) -> void:
	if game == null or baseline.is_empty(): return
	if game.aftermath.active:
		if engaged:
			# Aftermath may already have set dawn values this frame: restore only
			# cabin lights here, never overwrite its environment.
			restore_cabin()
			game.drone.volume_db = -24
			engaged = false
		return
	if not game.running:
		if engaged: reset()
		return
	if game.paused or game.modal: return
	engaged = true
	age += delta
	var depth := smoothstep(0.0, 620.0, -game.bus.position.z)
	var env: Environment = game.world_environment
	# Preserve nearby readability while allowing distant trees to disappear.
	env.ambient_light_energy = lerpf(.145, .105, depth)
	env.fog_density = lerpf(.022, .029, depth)
	env.fog_light_color = Color("18232a").lerp(Color("101b22"), depth)
	game.moon_light.light_energy = lerpf(.16, .12, depth)
	for item in cabin:
		var lamp: OmniLight3D = item.node
		var rear := smoothstep(-3.0, 3.0, lamp.position.z)
		# Rear seats lose warmth first. Slow voltage sag avoids flashing lights.
		var sag := (sin(age * .17 + rear * 1.7) * .5 + .5) * depth * .055
		lamp.light_energy = float(item.energy) * (lerpf(1.22, .84 - rear * .13, depth) - sag)
		lamp.light_color = Color("f0c995").lerp(Color("c8cbb5"), depth * (.45 + rear * .35))
	# Long troughs give the engine and individual sounds room to be heard.
	var breath := smoothstep(-.35, .75, sin(age * .075))
	game.drone.volume_db = lerpf(-33.0, -25.0, breath) + depth * 2.0

func restore_cabin() -> void:
	for item in cabin:
		item.node.light_energy = item.energy
		item.node.light_color = item.color

func reset() -> void:
	var env: Environment = game.world_environment
	env.ambient_light_energy = baseline.ambient
	env.fog_density = baseline.fog
	env.fog_light_color = baseline.fog_color
	game.moon_light.light_energy = baseline.moon
	game.drone.volume_db = -24
	restore_cabin()
	age = 0
	engaged = false
