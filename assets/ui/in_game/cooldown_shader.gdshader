shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = UV - center;

    float angle = atan(uv.y, uv.x) + 3.14159;
    float normalized_angle = angle / (2.0 * 3.14159);

    // Radial fill
    if (normalized_angle > progress) {
        COLOR.a = 0.0;
    }

    // Optional: add a pulsing glow effect when nearly ready
    if (progress > 0.9) {
        float pulse = (sin(TIME * 5.0) + 1.0) * 0.5;
        COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 1.0, 1.0), pulse * 0.3);
    }
}