shader_type canvas_item;
// Title-only film texture: no screen-reading pass and no rapid flashing.
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
void fragment() {
    vec2 uv = UV;
    float grain = hash(floor(uv * vec2(1280.0,720.0)) + floor(TIME * 5.0));
    float left_veil = (1.0 - smoothstep(0.28, 0.67, uv.x)) * 0.88;
    float edge = pow(clamp(length((uv - 0.5) * vec2(1.15, 1.6)),0.0,1.0), 2.0) * 0.65;
    float scan = step(0.6, fract(uv.y * 360.0)) * 0.018;
    COLOR = vec4(vec3(0.012 + grain * 0.025), clamp(max(left_veil, edge) + scan + grain * 0.055,0.0,0.96));
}
