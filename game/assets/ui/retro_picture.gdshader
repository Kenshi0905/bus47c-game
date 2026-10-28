shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
	vec2 resolution=vec2(640.0,360.0);
	vec2 uv=(floor(SCREEN_UV*resolution)+.5)/resolution;
	vec3 col=texture(screen_texture,uv).rgb;
	float dither=(hash(floor(uv*resolution))-.5)/48.0;
	col=floor(clamp(col+dither,0.0,1.0)*40.0+.5)/40.0;
	float grey=dot(col,vec3(.299,.587,.114));
	col=mix(vec3(grey),col,.86)*vec3(.98,1.015,1.02);
	float scan=1.0-.035*mod(floor(SCREEN_UV.y*resolution.y),2.0);
	float grain=(hash(floor(SCREEN_UV*resolution)+floor(TIME*12.0))-.5)*.017;
	vec2 edge=SCREEN_UV*(1.0-SCREEN_UV);
	float vignette=mix(.69,1.0,pow(clamp(edge.x*edge.y*16.0,0.0,1.0),.25));
	COLOR=vec4(col*scan*vignette+grain,1.0);
}
