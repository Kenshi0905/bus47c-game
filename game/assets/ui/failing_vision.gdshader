shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength = 0.0;
uniform float darkness = 0.0;
uniform float hurt = 0.0;
void fragment() {
	vec2 step_uv=SCREEN_PIXEL_SIZE*strength;
	vec3 c=texture(screen_tex,SCREEN_UV).rgb*.2;
	c+=texture(screen_tex,SCREEN_UV+vec2(step_uv.x,0.0)).rgb*.2;
	c+=texture(screen_tex,SCREEN_UV-vec2(step_uv.x,0.0)).rgb*.2;
	c+=texture(screen_tex,SCREEN_UV+vec2(0.0,step_uv.y)).rgb*.2;
	c+=texture(screen_tex,SCREEN_UV-vec2(0.0,step_uv.y)).rgb*.2;
	float edge=smoothstep(.25,.75,length(UV-.5));
	c=mix(c,vec3(.19,.006,.008),edge*hurt*.7);
	COLOR=vec4(c*(1.0-darkness),1.0);
}
