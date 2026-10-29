shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform float strength = 0.0;
void fragment() {
	float glow=pow(max(0.0,1.0-length((UV-0.5)*2.0)),2.0);
	ALBEDO=vec3(1.0,0.025,0.008);
	ALPHA=glow*strength;
}
