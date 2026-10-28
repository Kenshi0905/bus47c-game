shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
varying vec2 patch_seed;
// Soft drifting low mist for the Compatibility renderer; kept outside the bus.
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
    patch_seed=MODEL_MATRIX[3].xz*.17;
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
    vec2 p=UV*vec2(4.0,2.0)+vec2(TIME*.018,TIME*.006)+patch_seed;
    float wisps=noise(p)*.65+noise(p*2.7)*.35;
    float edge=smoothstep(0.0,.22,UV.x)*smoothstep(0.0,.22,1.0-UV.x);
    edge*=smoothstep(0.0,.3,UV.y)*smoothstep(0.0,.35,1.0-UV.y);
    float distance_fade=smoothstep(2.0,7.0,length(VERTEX))*(1.0-smoothstep(75.0,110.0,length(VERTEX)));
    ALBEDO=vec3(.18,.25,.26);
    ALPHA=edge*wisps*.52*distance_fade;
}
