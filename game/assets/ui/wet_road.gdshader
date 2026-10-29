shader_type spatial;
render_mode cull_disabled;
uniform vec4 base : source_color = vec4(.12,.14,.14,1.0);
uniform float paint = 0.0;
uniform vec3 bus_front = vec3(0.0,0.0,0.0);
uniform vec3 bus_forward = vec3(0.0,0.0,-1.0);
uniform float lamps_on = 1.0;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world.xz;
	float broad=noise(p*.72)*.65+noise(p*2.4)*.35;
	float wet=smoothstep(.44,.66,broad);
	float detail=1.0-smoothstep(.12,.5,max(length(dFdx(p*20.0)),length(dFdy(p*20.0))));
	float grit=mix(.5,noise(p*68.0),detail);
	ALBEDO=base.rgb*(.76+grit*.27)*(1.0-wet*.19);
	ROUGHNESS=mix(.89,.19,wet)*(1.0-paint*.12);
	SPECULAR=.62;
	vec3 right=vec3(-bus_forward.z,0.0,bus_forward.x);
	vec3 delta=world-bus_front;
	float ahead=dot(delta,bus_forward);
	float across=dot(delta,right);
	float streak=exp(-pow((abs(across)-.9)/.43,2.0))*exp(-max(ahead,0.0)*.17)*smoothstep(0.0,1.0,ahead);
	streak*=1.0-smoothstep(11.0,20.0,ahead);
	float breaks=.26+.74*noise(vec2(p.x*16.0,p.y*40.0));
	float grazing=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),2.0);
	// A bounded wet highlight follows the actual moving headlamps. No mirrored
	// scene or screen-space reflection buffer is required by Compatibility.
	EMISSION=vec3(.85,.57,.23)*streak*wet*breaks*grazing*lamps_on*.5;
}
