shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
vec3 highlight(vec2 uv){vec3 c=texture(screen_texture,uv).rgb;return max(c-vec3(.62),vec3(0.0));}
void fragment() {
	// One grade for every gameplay scene, including dawn. UI sits on a later layer.
	vec2 resolution=vec2(854.0,480.0);
	vec2 uv=(floor(SCREEN_UV*resolution)+.5)/resolution;
	vec3 col=texture(screen_texture,uv).rgb;
	vec2 px=SCREEN_PIXEL_SIZE;
	vec3 glow=highlight(uv+px*vec2(4,0))+highlight(uv-px*vec2(4,0));
	glow+=highlight(uv+px*vec2(0,4))+highlight(uv-px*vec2(0,4));
	glow+=highlight(uv+px*vec2(9,5))+highlight(uv-px*vec2(9,5));
	glow+=highlight(uv+px*vec2(9,-5))+highlight(uv-px*vec2(9,-5));
	col+=glow*.025;
	float lum=dot(col,vec3(.2126,.7152,.0722));
	float shadows=1.0-smoothstep(.06,.38,lum);
	float lights=smoothstep(.3,.85,lum);
	col*=mix(vec3(1.0),vec3(.89,.985,1.06),shadows*.65);
	col*=mix(vec3(1.0),vec3(1.03,.995,.92),lights*.45);
	col=mix(vec3(dot(col,vec3(.2126,.7152,.0722))),col,.87);
	// A gentle toe and shoulder tame bright wallpaper without losing dark paths.
	col=pow(max(col,vec3(0.0)),vec3(1.045));
	col=col/(vec3(1.0)+col*.12);
	float dither=(hash(floor(uv*resolution))-.5)/150.0;
	col=floor(clamp(col+dither,0.0,1.0)*104.0+.5)/104.0;
	float grain=(hash(floor(SCREEN_UV*resolution)+floor(TIME*10.0))-.5)*.014;
	vec2 edge=SCREEN_UV*(1.0-SCREEN_UV);
	float vignette=mix(.73,1.0,pow(clamp(edge.x*edge.y*16.0,0.0,1.0),.28));
	COLOR=vec4(col*vignette+grain,1.0);
}
