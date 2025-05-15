#version 330 core
#extension GL_OES_standard_derivatives : enable
in vec3 fragCoord; // pixel position relative to quad (0,0 to quadSize)
out vec4 fragColor;

uniform vec2 size;
uniform vec2 resolution;
uniform float radius;
uniform float borderWidth;
uniform vec4 input;

// Rounded box signed distance function
float roundedBoxSDF(vec2 p, vec2 size, float r) {
    vec2 q = abs(p - size * 0.5) - (size * 0.5 - vec2(r));
    return length(max(q, 0.0)) - r;
}

void main() {
    vec2 localPos = fragCoord.xy * resolution.xy;

    vec4 borderColor = input;
    vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 0.0); // Background color

    float borderWidth = 4; // Thickness of the border in UV units
    float radius = 16; // Corner radius in UV units

    // Compute distance from edge of rounded rectangle
    float dist = roundedBoxSDF(localPos, size, radius);

    // Anti-aliasing width
    float aa = fwidth(dist);

    // Compute alpha mask for border band
    float alpha = smoothstep(-borderWidth - aa, -borderWidth + aa, dist)
            * (1.0 - smoothstep(0.0 - aa, 0.0 + aa, dist));

    fragColor = mix(backgroundColor, borderColor, alpha);
}
