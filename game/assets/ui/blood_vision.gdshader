shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount = 0.0;
uniform float pulse = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(41.3,97.7)))*29173.2); }
void fragment() {
	vec2 uv=SCREEN_UV;
	vec2 offset=SCREEN_PIXEL_SIZE*amount*3.0;
	vec3 scene=(texture(screen_tex,uv).rgb+texture(screen_tex,uv+offset).rgb+texture(screen_tex,uv-offset).rgb)/3.0;
	float edge=smoothstep(.16,.68,length((UV-.5)*vec2(1.05,1.0)));
	float grain=hash(floor(UV*vec2(220.0,140.0)));
	float streak=pow(max(0.0,sin(UV.x*163.0+sin(UV.x*31.0)*3.0)),18.0);
	float drip=streak*smoothstep(1.0-amount*.85,1.0,UV.y);
	vec3 red=vec3(.62,.018,.012)*(.7+grain*.3);
	float coverage=clamp(amount*(.24+edge*.56+drip*.3)+pulse*.4,0.0,.91);
	COLOR=vec4(mix(scene,red,coverage),1.0);
}
