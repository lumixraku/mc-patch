#version 150

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;

out vec2 texcoord;
out vec4 color;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
    texcoord = vaUV0;
    color = vaColor;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition, 1.0);
}

