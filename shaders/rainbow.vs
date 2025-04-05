#version 330 core
layout (location = 0) in vec3 aPos;

out vec2 TexCoord;

void main()
{
    gl_Position = vec4(aPos, 1.0);
    // Pass the position as texture coordinates (0-1 range)
    TexCoord = (aPos.xy + 1.0) * 0.5;
}
