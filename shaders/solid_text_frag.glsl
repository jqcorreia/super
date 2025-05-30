#version 330 core

in vec2 texCoord;
uniform sampler2D fontTexture;

uniform vec4 input;

out vec4 fragColor;

void main() {
    vec2 tc = vec2(texCoord.x, texCoord.y);
    float alpha = texture(fontTexture, tc).r;
    fragColor = vec4(input.xyz, alpha);
    // fragColor = vec4(texCoord.xy, 0.0, 1.0);
}
