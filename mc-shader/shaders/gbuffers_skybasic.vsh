#version 120

varying vec4 vColor;

void main() {
    vColor = gl_Color; // vanilla sky color
    gl_Position = ftransform();
}

