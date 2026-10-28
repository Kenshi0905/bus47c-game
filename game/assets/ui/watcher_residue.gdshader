shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform float opacity = 0.4;
uniform vec3 tint : source_color = vec3(0.32,0.42,0.40);
void fragment() {
	vec2 p=UV*2.0-1.0;
	float cloud=pow(max(0.0,1.0-dot(p,p)),1.7);
	float grain=0.7+0.3*sin(UV.x*37.0)*sin(UV.y*29.0);
	ALBEDO=tint;
	ALPHA=cloud*grain*opacity;
}
