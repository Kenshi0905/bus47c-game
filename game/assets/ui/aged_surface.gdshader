shader_type spatial;
uniform vec4 base : source_color = vec4(0.3,0.3,0.25,1.0);
uniform int kind = 0;
varying vec3 world;
varying vec3 normal_world;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	normal_world=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
}
void fragment() {
	// Fade subpixel grain instead of letting hard hash boundaries crawl in motion.
	vec3 grain_pos=world*20.0;
	vec3 grain_width=fwidth(grain_pos);
	float grain_visibility=1.0-smoothstep(.35,1.1,max(grain_width.x,max(grain_width.y,grain_width.z)));
	float grit=mix(.5,hash(floor(grain_pos)),grain_visibility);
	vec3 color=base.rgb*(0.83+grit*0.16);
	float horizontal=abs(normal_world.x)>0.5?world.z:world.x;
	if (kind==1) {
		float row=floor(world.y*7.0);
		vec2 brick=fract(vec2(horizontal*3.0+mod(row,2.0)*0.5,world.y*7.0));
		float mortar=step(brick.x,0.045)+step(brick.y,0.085);
		color=mix(color,vec3(0.23,0.23,0.20),clamp(mortar,0.0,1.0)*0.75);
	} else if (kind==2) {
		float phase=horizontal*48.0+sin(world.y*2.0)*3.0;
		float grain=sin(phase)*(1.0-smoothstep(.8,2.5,fwidth(phase)));
		color*=0.92+grain*0.065;
		color*=0.76+step(0.025,fract(world.y*6.0))*0.24;
	} else if (kind==3) {
		vec2 tile=fract(world.xz*1.7);
		float check=mod(floor(world.x*1.7)+floor(world.z*1.7),2.0);
		color*=mix(0.36,1.0,check);
		color*=0.5+0.5*step(0.035,min(tile.x,tile.y));
	} else if (kind==4) {
		color*=0.83+hash(floor(world*3.0))*0.17;
	} else if (kind==5) {
		vec2 wallpaper=fract(vec2(horizontal*4.0,world.y*3.0))-.5;
		float flower=step(abs(wallpaper.x)+abs(wallpaper.y),.2);
		color*=1.0-flower*.22;
	} else if (kind==6) {
		vec2 panel=fract(world.xz*.85);
		color*=0.55+0.45*step(.018,min(panel.x,panel.y));
		color*=.9+.1*hash(floor(world*3.0));
	} else if (kind==7) {
		float stain=hash(floor(world*4.5));
		color*=.87+.13*stain;
		float crease=1.0-smoothstep(.0,.025,abs(fract(horizontal*2.3)-.5));
		color*=1.0-crease*.14;
	} else if (kind==8) {
		vec2 tile=fract(world.xz*1.55);
		float edge=min(tile.x,tile.y);
		color*=.72+.28*smoothstep(.015,.04,edge);
	} else if (kind==9) {
		float board=fract(world.x*3.5);
		color*=.62+.38*smoothstep(.0,.025,board);
		float phase=world.z*40.0+sin(world.x*2.5);
		color*=.94+.05*sin(phase)*(1.0-smoothstep(.8,2.5,fwidth(phase)));
		float join=fract(world.z*.4+floor(world.x*3.5)*.37);
		color*=.8+.2*smoothstep(.0,.012,join);
	} else if (kind==10) {
		float panel=fract(horizontal*3.5);
		color*=.65+.35*smoothstep(.0,.035,panel);
		float phase=world.y*42.0+sin(horizontal*3.0);
		color*=.94+.045*sin(phase)*(1.0-smoothstep(.8,2.5,fwidth(phase)));
	}
	ALBEDO=color;
	ROUGHNESS=0.91;
}
