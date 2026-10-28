shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.3,0.35,0.34,1.0);
uniform float dissolve : hint_range(0.0,1.0) = 0.0;
varying vec3 local_point;
void vertex() { local_point=VERTEX; }
void fragment() {
	vec3 cell=floor(local_point*26.0);
	float grain=fract(sin(dot(cell,vec3(12.9898,78.233,39.425)))*43758.5453);
	if (grain<dissolve) { discard; }
	float edge=1.0-smoothstep(dissolve,dissolve+0.12,grain);
	ALBEDO=tint.rgb;
	ROUGHNESS=0.95;
	EMISSION=tint.rgb*0.18+vec3(0.28,0.39,0.37)*edge*0.65;
}
