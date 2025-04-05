#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    int w = 320;
    int h = 100; 
    int ratio = w / h;
    vec3 final_pos = vec3(aPos.x / 320 * 2.0 - 1.0, -(aPos.y / 100 * 2.0 - 1.0), 0.0);
    
    //gl_Position = vec4(aPos, 1.0);
    gl_Position = vec4(final_pos, 1.0);
    
}
