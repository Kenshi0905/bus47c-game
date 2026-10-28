shader_type canvas_item;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment() {
	vec2 p=UV;
	float nick=.006+hash(vec2(floor(p.y*160.0),2.0))*.004;
	float nick_y=.008+hash(vec2(floor(p.x*180.0),7.0))*.004;
	float edge=min(min(p.x-nick,1.0-p.x-nick),min(p.y-nick_y,1.0-p.y-nick_y));
	float alpha=smoothstep(-.002,.001,edge);
	float fiber=hash(floor(p*vec2(720.0,920.0)))-.5;
	float stain=exp(-length((p-vec2(.94,.82))*vec2(7.0,5.0)))*.19;
	stain+=exp(-length((p-vec2(.08,.12))*vec2(8.0,6.0)))*.11;
	float crease=exp(-abs(p.x-.49)*260.0)*.075+exp(-abs(p.y-.515)*240.0)*.07;
	float ridge=exp(-abs(p.x-.496)*270.0)*.07+exp(-abs(p.y-.521)*250.0)*.06;
	vec3 paper=vec3(.78,.74,.62)+fiber*.045-stain-crease+ridge;
	paper-=exp(-max(edge,0.0)*80.0)*.15;
	COLOR=vec4(paper,alpha);
}
