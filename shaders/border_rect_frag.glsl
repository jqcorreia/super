#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 input;
uniform vec2 resolution;
uniform float iTime;

void main()
{
    vec2 uv = fragCoord.xy * resolution.xy;

    if (uv.x > 200) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        color = input;
    }

    float border = 1;
    float _borderX = resolution.x - border;
    float _borderY = resolution.y - border;
    if (uv.x < border || uv.x > _borderX || uv.y < border || uv.y > _borderY) {
        color = input;
    } else {
        color = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
