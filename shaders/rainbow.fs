#version 330 core

out vec4 FragColor;
in vec2 TexCoord;

uniform float time; // Time uniform for animation

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    // Use position and time to create a rainbow effect
    float hue = fract(TexCoord.x + TexCoord.y + time * 0.1);
    vec3 rgb = hsv2rgb(vec3(hue, 0.8, 0.9));
    FragColor = vec4(rgb, 1.0);
}
