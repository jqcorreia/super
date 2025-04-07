#version 330 core

in vec3 vPos;
out vec4 color;

uniform vec4 input;

void main()
{
    vec4 final_color = vec4(vPos.x, input.yz, 1.0);
    color = final_color;
}
