#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 color_input;

void main()
{
    vec4 final_color = vec4(color_input);
    color = final_color;
}
