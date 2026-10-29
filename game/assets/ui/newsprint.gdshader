shader_type canvas_item;
void fragment() {
	vec4 source=texture(TEXTURE,UV);
	float grey=dot(source.rgb,vec3(.299,.587,.114));
	float dot_pattern=sin(UV.x*900.0)*sin(UV.y*600.0)*.05;
	grey=clamp(grey+dot_pattern,0.0,1.0);
	COLOR=vec4(mix(vec3(.10,.11,.09),vec3(.77,.75,.65),grey),source.a);
}
