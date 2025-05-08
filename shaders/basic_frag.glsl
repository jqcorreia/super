#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 input;

void main()
{
    vec4 final_color = vec4(input);
    color = final_color;
}
