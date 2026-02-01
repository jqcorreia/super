#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 input;
uniform vec2 resolution;

void main()
{
    vec2 center = vec2(0.5, 0.5);
    vec4 col;
    vec2 uv = fragCoord.xy;

    if (length(center - uv) > 0.5) {
        col = vec4(0);
    }
    else {
        col = input;
    }

    // Output to screen
    color = col;
}
