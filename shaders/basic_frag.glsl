#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 input;

void main()
{
    vec4 final_color = vec4(fragCoord.x, input.yz, 1.0);
    color = final_color;
}
