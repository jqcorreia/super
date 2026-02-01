#version 330 core
layout(location = 0) in vec2 aPos;
layout(location = 1) in vec2 aTex;

uniform vec2 position;
uniform vec2 size;
uniform mat4 projection;

out vec2 texCoord;

void main()
{
    vec2 pos = position + aPos * size;
    gl_Position = projection * vec4(pos, 0.0, 1.0);
    texCoord = aTex;
}
