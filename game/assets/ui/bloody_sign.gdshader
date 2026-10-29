shader_type spatial;
render_mode cull_disabled;
uniform vec4 paint : source_color = vec4(0.25,0.10,0.08,1.0);
uniform float clock = 0.0;
uniform float seed = 0.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment() {
	vec2 pixel=floor(UV*vec2(256.0,128.0));
	float grain=hash(pixel+seed);
	vec3 color=paint.rgb*(.55+grain*.45);
	float streak=hash(vec2(floor(UV.x*35.0),seed));
	float scratches=step(.986,grain)*step(.4,fract(UV.y*51.0));
	color=mix(color,vec3(.18,.16,.11),scratches*.9);
	float border=step(UV.x,.02)+step(1.0-UV.x,.02)+step(UV.y,.04)+step(1.0-UV.y,.04);
	color=mix(color,vec3(.47,.40,.27),clamp(border,0.0,1.0)*.7);
	float line=1.0-smoothstep(.025,.1,abs(fract(UV.x*19.0)-.5));
	float length=.25+streak*.75;
	float blood=line*step(UV.y,length)*step(.47,streak);
	blood=max(blood,(1.0-smoothstep(.02,.12,UV.y))*.8);
	ALBEDO=mix(color,vec3(.58,.025,.018),blood);
	EMISSION=vec3(.32,.009,.004)*blood*.35;
	ROUGHNESS=mix(.95,.32,blood);
}
