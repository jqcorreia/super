#version 330 core

in vec3 fragCoord;
out vec4 color;

uniform vec4 input;

void main()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord / iResolution.xy;
    float border = 5.0;
    float _borderX = iResolution.x - border;
    float _borderY = iResolution.y - border;
    if (fragCoord.x < border || fragCoord.x > _borderX || fragCoord.y < border || fragCoord.y > _borderY)
    {
        color = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        // Time varying pixel color
        vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
        color = vec4(col.xy, 1.0, 1.0);
    }
}
