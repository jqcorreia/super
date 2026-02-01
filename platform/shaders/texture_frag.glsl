#version 330 core
in vec2 texCoord;

uniform sampler2D uTexture;
uniform bool flipped;

out vec4 FragColor;

void main() {
    float uvy = flipped ? 1.0 - texCoord.y : texCoord.y;
    vec2 tc = vec2(texCoord.x, uvy);
    FragColor = texture(uTexture, tc);
}
