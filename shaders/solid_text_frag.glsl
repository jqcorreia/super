#version 330 core

in vec2 texCoord;
uniform sampler2D fontTexture;
out vec4 fragColor;

void main() {
    float alpha = texture(fontTexture, texCoord).r;
    fragColor = vec4(1.0, 1.0, 1.0, alpha);
}
