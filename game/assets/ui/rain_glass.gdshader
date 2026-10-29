shader_type spatial;
render_mode cull_disabled, depth_draw_never;
uniform float windshield = 0.0;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){local_pos=VERTEX;local_normal=NORMAL;}
void fragment(){
	vec2 p=abs(local_normal.x)>.5?local_pos.zy:local_pos.xy;
	vec2 cell=floor(p*34.0),f=fract(p*34.0)-.5;
	float seed=hash(cell);
	vec2 center=vec2(hash(cell+4.2),hash(cell-3.6))*.55-.275;
	float lens=1.0-smoothstep(.06,.19,length((f-center)*vec2(1.0,.72)));
	lens*=step(.71,seed);
	float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
	float rim=1.0-smoothstep(.015,.16,edge);
	float trail=pow(max(0.0,sin(p.x*183.0+sin(p.x*19.0)*3.0)),32.0);
	trail*=.3+.7*hash(vec2(floor(p.x*26.0),0));
	float clarity=1.0-windshield*.65;
	float detail=1.0-smoothstep(.6,1.5,max(length(dFdx(p*34.0)),length(dFdy(p*34.0))));
	ALBEDO=mix(vec3(.18,.23,.22),vec3(.54,.47,.32),rim*.65);
	ROUGHNESS=mix(.17,.68,rim);
	SPECULAR=.55;
	ALPHA=.014+rim*.14+clarity*(lens*.095*detail+trail*.021);
}
