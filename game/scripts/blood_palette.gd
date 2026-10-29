extends RefCounted
## A small colour floor keeps red legible at night without luminous puddles.
static func material() -> StandardMaterial3D:
	var blood := StandardMaterial3D.new()
	blood.albedo_color=Color("bd241e")
	blood.roughness=.3
	blood.emission_enabled=true
	blood.emission=Color("b51d16")
	blood.emission_energy_multiplier=.26
	blood.cull_mode=BaseMaterial3D.CULL_DISABLED
	return blood
