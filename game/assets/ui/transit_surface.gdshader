shader_type spatial;
uniform vec4 base : source_color = vec4(.22,.28,.22,1.0);
uniform int kind = 0; // painted metal, vinyl, rubber, plaster, timber
uniform float seed = 0.0;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() {local_pos=VERTEX;local_normal=NORMAL;}
void fragment() {
	vec3 n=abs(local_normal);
	vec2 p=n.y>.5?local_pos.xz:(n.x>.5?local_pos.zy:local_pos.xy);
	p+=vec2(seed,seed*.43);
	float cloud=noise(p*3.3)*.65+noise(p*9.0)*.35;
	float footprint=max(length(dFdx(p)),length(dFdy(p)));
	float detail=1.0-smoothstep(.008,.035,footprint);
	float grain=mix(.5,noise(p*180.0),detail);
	vec3 color=base.rgb*(.76+cloud*.29+(grain-.5)*.13);
	float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
	float rubbed=(1.0-smoothstep(.004,.026,edge))*(.3+cloud*.7);
	float rough=.77;
	if(kind==0) {
		float scratch=pow(noise(vec2(p.x*90.0,p.y*3.0)),11.0)*detail;
		color=mix(color,vec3(.28,.26,.19),rubbed*.18+scratch*.35);
		rough=.53+cloud*.22;
	} else if(kind==1) {
		float crease=pow(noise(vec2(p.x*7.0,p.y*2.0)),7.0);
		color*=.88+.16*cloud-crease*.2;
		color=mix(color,base.rgb*1.21,rubbed*.38);
		rough=.43+cloud*.22;
	} else if(kind==2) {
		float rib=sin(p.x*115.0)*(1.0-smoothstep(.7,2.5,fwidth(p.x*115.0)));
		color*=.89+rib*.08;
		rough=.9;
	} else if(kind==3) {
		color*=.82+noise(p*1.2)*.22;
		rough=.94;
	} else {
		float line=sin(p.x*43.0+noise(p*2.0)*4.0)*(1.0-smoothstep(.7,2.4,fwidth(p.x*43.0)));
		color*=.92+line*.09;
		rough=.72;
	}
	ALBEDO=color;
	ROUGHNESS=rough;
	SPECULAR=.35;
}
