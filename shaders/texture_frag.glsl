#version 330 core
in vec2 texCoord;

uniform sampler2D uTexture;

out vec4 FragColor;

void main() {
    vec2 tc = vec2(texCoord.x, 1.0 - texCoord.y);
    FragColor = texture(uTexture, tc);
}
