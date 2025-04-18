#version 330 core
layout(location = 0) in vec3 aPos;

uniform vec2 position;
uniform vec2 size;
uniform mat4 projection;

out vec3 fragCoord;

void main()
{
    vec2 pos = aPos.xy * size + position;
    fragCoord = aPos;

    gl_Position = projection * vec4(pos, 0.0, 1.0);
}
