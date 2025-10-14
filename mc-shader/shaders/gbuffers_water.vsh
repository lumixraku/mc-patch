#version 120

attribute vec4 at_tangent;
attribute vec4 at_position;
attribute vec2 at_texcoord0;

varying vec2 texcoord;

void main() {
    texcoord = at_texcoord0;
    gl_Position = ftransform();
}

